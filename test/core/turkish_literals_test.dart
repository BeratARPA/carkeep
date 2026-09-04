import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CLAUDE.md: kullanıcıya görünen her metin `lib/core/strings_tr.dart`'ta.
/// T16 kabul kriteri bunu `grep` ile istiyor; test hâline getirildi ki
/// geri gelmesin.
///
/// Kotlin tarafındaki bildirim metinleri bilinçli istisna
/// (`NotificationText.kt`): receiver Flutter motorunu uyandırmaz (K-03).
void main() {
  const List<String> roots = <String>[
    'lib/features',
    'lib/app.dart',
    'lib/lifecycle.dart',
    'lib/main.dart',
    'lib/providers.dart',
  ];

  test('ekran katmanında Türkçe metin literali yok', () {
    final List<String> offenders = <String>[];

    for (final String path in _dartFiles(roots)) {
      final List<String> lines = File(path).readAsLinesSync();
      bool inBlockComment = false;
      for (int i = 0; i < lines.length; i++) {
        final String code = _stripComments(lines[i], inBlockComment);
        inBlockComment = _blockCommentAfter(lines[i], inBlockComment);
        if (_turkish.hasMatch(code)) {
          offenders.add('$path:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Bu satırlarda Türkçe metin var; strings_tr.dart\'a taşı:\n'
          '${offenders.join('\n')}',
    );
  });

  test('strings_tr.dart bu kontrolün kendisini yakalıyor', () {
    // Kontrolün işe yaradığını kanıtla: strings dosyası Türkçe dolu.
    expect(
      _turkish.hasMatch(File('lib/core/strings_tr.dart').readAsStringSync()),
      isTrue,
    );
    // Ve yorum ayıklayıcı gerçekten ayıklıyor.
    expect(_stripComments('foo(); // açıklama', false).trim(), 'foo();');
    expect(_stripComments('/// Türkçe belge', false).trim(), isEmpty);
    expect(_stripComments("const a = 'https://x';", false), contains('https'));
    expect(_stripComments("const a = 'ç';", false), contains('ç'));
  });
}

final RegExp _turkish = RegExp('[çğışöüÇĞİŞÖÜ]');

List<String> _dartFiles(List<String> roots) {
  final List<String> out = <String>[];
  for (final String root in roots) {
    final FileSystemEntity entity = FileSystemEntity.isDirectorySync(root)
        ? Directory(root)
        : File(root);
    if (entity is File) {
      out.add(entity.path);
      continue;
    }
    for (final FileSystemEntity e
        in (entity as Directory).listSync(recursive: true)) {
      if (e is File && e.path.endsWith('.dart')) {
        out.add(e.path);
      }
    }
  }
  return out;
}

/// Satırdaki yorumları siler. Dizge içindeki `//` (URL) korunur.
String _stripComments(String line, bool inBlockComment) {
  final StringBuffer out = StringBuffer();
  String? quote;
  bool block = inBlockComment;

  for (int i = 0; i < line.length; i++) {
    final String c = line[i];
    final String next = i + 1 < line.length ? line[i + 1] : '';

    if (block) {
      if (c == '*' && next == '/') {
        block = false;
        i++;
      }
      continue;
    }
    if (quote != null) {
      out.write(c);
      if (c == r'\\') {
        if (next.isNotEmpty) {
          out.write(next);
          i++;
        }
        continue;
      }
      if (c == quote) {
        quote = null;
      }
      continue;
    }
    if (c == "'" || c == '"') {
      quote = c;
      out.write(c);
      continue;
    }
    if (c == '/' && next == '/') {
      break;
    }
    if (c == '/' && next == '*') {
      block = true;
      i++;
      continue;
    }
    out.write(c);
  }
  return out.toString();
}

bool _blockCommentAfter(String line, bool before) {
  bool block = before;
  String? quote;
  for (int i = 0; i < line.length; i++) {
    final String c = line[i];
    final String next = i + 1 < line.length ? line[i + 1] : '';
    if (block) {
      if (c == '*' && next == '/') {
        block = false;
        i++;
      }
      continue;
    }
    if (quote != null) {
      if (c == quote) {
        quote = null;
      }
      continue;
    }
    if (c == "'" || c == '"') {
      quote = c;
      continue;
    }
    if (c == '/' && next == '/') {
      return block;
    }
    if (c == '/' && next == '*') {
      block = true;
      i++;
    }
  }
  return block;
}
