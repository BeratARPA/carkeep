import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../domain/models/measure.dart';
import '../../domain/models/schedule.dart';

/// `assets/seed/checklist_seed.json` yolu (K-07).
const String kSeedAssetPath = 'assets/seed/checklist_seed.json';

/// Şablon dosyası okunamaz veya geçersizse (01-spec §9: geliştirici hatası).
class SeedFormatException implements Exception {
  const SeedFormatException(this.message, [this.itemId]);

  final String message;
  final String? itemId;

  @override
  String toString() => itemId == null
      ? 'SeedFormatException: $message'
      : 'SeedFormatException($itemId): $message';
}

/// Şablondaki tek madde. Salt okunur; DB'ye kurulumda kopyalanır.
class SeedItem {
  const SeedItem({
    required this.id,
    required this.group,
    required this.name,
    required this.schedule,
    required this.measure,
    required this.why,
    required this.how,
    required this.warn,
    required this.startsFromInstall,
    required this.appliesLastService,
    required this.enabledByDefault,
    required this.verified,
    required this.sourceNote,
  });

  final String id;
  final String group;
  final String name;
  final Schedule schedule;
  final Measure measure;
  final String why;
  final List<String> how;
  final String? warn;
  final bool startsFromInstall;
  final bool appliesLastService;
  final bool enabledByDefault;

  /// `true|partial|false`
  final String verified;
  final String? sourceNote;

  bool get isFullyVerified => verified == 'true';

  @override
  String toString() => 'SeedItem($id)';
}

/// Yüklenmiş şablon.
class Seed {
  const Seed({
    required this.version,
    required this.targetVehicle,
    required this.groups,
    required this.items,
  });

  final int version;
  final String targetVehicle;

  /// `frequent → "Sık (2 haftada bir)"` gibi grup başlıkları.
  final Map<String, String> groups;
  final List<SeedItem> items;

  SeedItem? byId(String id) {
    for (final SeedItem i in items) {
      if (i.id == id) {
        return i;
      }
    }
    return null;
  }
}

/// Geçerli grup anahtarları. `custom` yalnız kullanıcı maddelerinde kullanılır,
/// seed'de bulunmaz.
const Set<String> kSeedGroups = <String>{
  'frequent',
  'monthly',
  'quarterly',
  'service',
  'yearly',
  'seasonal',
};

const Set<String> kVerifiedValues = <String>{'true', 'partial', 'false'};

/// Şablonu asset'ten okur ve doğrular.
class SeedLoader {
  const SeedLoader({this.bundle});

  /// Testte sahte bir bundle verilebilsin diye.
  final AssetBundle? bundle;

  Future<Seed> load() async {
    final String raw = await (bundle ?? rootBundle).loadString(kSeedAssetPath);
    return parse(raw);
  }

  /// Test edilebilir saf ayrıştırıcı.
  static Seed parse(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (e) {
      throw SeedFormatException('JSON ayrıştırılamadı: ${e.message}');
    }
    if (decoded is! Map<String, Object?>) {
      throw const SeedFormatException('Kök nesne olmalı');
    }

    final Object? version = decoded['version'];
    if (version is! int || version < 1) {
      throw const SeedFormatException('`version` pozitif tam sayı olmalı');
    }

    final Object? rawItems = decoded['items'];
    if (rawItems is! List<Object?> || rawItems.isEmpty) {
      throw const SeedFormatException('`items` boş olmayan dizi olmalı');
    }

    final Map<String, String> groups = <String, String>{};
    final Object? rawGroups = decoded['groups'];
    if (rawGroups is Map<String, Object?>) {
      rawGroups.forEach((String k, Object? v) {
        if (v is String) {
          groups[k] = v;
        }
      });
    }

    final Set<String> seenIds = <String>{};
    final List<SeedItem> items = <SeedItem>[];
    for (final Object? e in rawItems) {
      if (e is! Map<String, Object?>) {
        throw const SeedFormatException('Madde nesne olmalı');
      }
      final SeedItem item = _parseItem(e, groups);
      if (!seenIds.add(item.id)) {
        throw SeedFormatException('Yinelenen madde id', item.id);
      }
      items.add(item);
    }

    return Seed(
      version: version,
      targetVehicle: (decoded['targetVehicle'] as String?) ?? '',
      groups: Map<String, String>.unmodifiable(groups),
      items: List<SeedItem>.unmodifiable(items),
    );
  }

  static SeedItem _parseItem(
    Map<String, Object?> m,
    Map<String, String> groups,
  ) {
    final Object? rawId = m['id'];
    if (rawId is! String || rawId.isEmpty) {
      throw const SeedFormatException('`id` zorunlu');
    }
    final String id = rawId;

    final String group = _str(m['group'], 'group', id);
    if (!kSeedGroups.contains(group)) {
      throw SeedFormatException('Bilinmeyen grup: $group', id);
    }
    if (groups.isNotEmpty && !groups.containsKey(group)) {
      throw SeedFormatException('`groups` sözlüğünde yok: $group', id);
    }

    final String name = _str(m['name'], 'name', id);

    final Schedule schedule;
    try {
      schedule = _parseSchedule(m['schedule']);
    } on FormatException catch (e) {
      throw SeedFormatException('Geçersiz schedule: ${e.message}', id);
    }

    final Measure measure;
    try {
      measure = _parseMeasure(m['measure']);
    } on FormatException catch (e) {
      throw SeedFormatException('Geçersiz measure: ${e.message}', id);
    }

    final String verified = _str(m['verified'], 'verified', id);
    if (!kVerifiedValues.contains(verified)) {
      throw SeedFormatException('Geçersiz verified: $verified', id);
    }
    final Object? rawSourceNote = m['sourceNote'];
    final String? sourceNote =
        rawSourceNote is String && rawSourceNote.isNotEmpty
        ? rawSourceNote
        : null;
    // 05-is-listesi T03: verified != true ise sourceNote zorunlu.
    if (verified != 'true' && sourceNote == null) {
      throw SeedFormatException(
        'verified=$verified ise sourceNote zorunlu',
        id,
      );
    }

    final Object? rawHow = m['how'];
    if (rawHow is! List<Object?>) {
      throw SeedFormatException('`how` dizi olmalı', id);
    }

    final Object? rawWarn = m['warn'];

    return SeedItem(
      id: id,
      group: group,
      name: name,
      schedule: schedule,
      measure: measure,
      why: _str(m['why'], 'why', id),
      how: List<String>.unmodifiable(<String>[
        for (final Object? h in rawHow)
          if (h is String) h else throw SeedFormatException('`how` metin', id),
      ]),
      warn: rawWarn is String && rawWarn.isNotEmpty ? rawWarn : null,
      startsFromInstall: _bool(m['startsFromInstall'], 'startsFromInstall', id),
      appliesLastService: _bool(
        m['appliesLastService'],
        'appliesLastService',
        id,
      ),
      enabledByDefault: _bool(m['enabledByDefault'], 'enabledByDefault', id),
      verified: verified,
      sourceNote: sourceNote,
    );
  }

  static Schedule _parseSchedule(Object? raw) {
    if (raw is! Map<String, Object?>) {
      throw const FormatException('nesne olmalı');
    }
    final Object? kind = raw['kind'];
    if (kind is! String) {
      throw const FormatException('`kind` zorunlu');
    }
    return switch (scheduleKindFromString(kind)) {
      ScheduleKind.days => Schedule.days(_int(raw['days'], 'days')),
      ScheduleKind.km => Schedule.km(_int(raw['km'], 'km')),
      ScheduleKind.both => Schedule.both(
        days: _int(raw['days'], 'days'),
        km: _int(raw['km'], 'km'),
      ),
      ScheduleKind.seasonal => Schedule.seasonal(_parseDates(raw['dates'])),
    };
  }

  static List<SeasonalDate> _parseDates(Object? raw) {
    if (raw is! List<Object?>) {
      throw const FormatException('`dates` dizi olmalı');
    }
    return <SeasonalDate>[
      for (final Object? e in raw)
        if (e is Map<String, Object?>)
          SeasonalDate(_int(e['month'], 'month'), _int(e['day'], 'day'))
        else
          throw const FormatException('tarih nesne olmalı'),
    ];
  }

  static Measure _parseMeasure(Object? raw) {
    if (raw is! Map<String, Object?>) {
      throw const FormatException('nesne olmalı');
    }
    final Object? type = raw['type'];
    if (type is! String) {
      throw const FormatException('`type` zorunlu');
    }
    return switch (measureTypeFromString(type)) {
      MeasureType.none => const Measure.none(),
      MeasureType.level => Measure.level(<String>[
        for (final Object? e
            in (raw['levels'] as List<Object?>? ?? const <Object?>[]))
          if (e is String) e else throw const FormatException('seçenek metin'),
      ]),
      MeasureType.tires => Measure.tires(
        unit: (raw['unit'] as String?) ?? 'bar',
      ),
      MeasureType.number => Measure.number(
        unit: _strPlain(raw['unit'], 'unit'),
        label: _strPlain(raw['label'], 'label'),
      ),
    };
  }

  static String _str(Object? v, String field, String id) {
    if (v is! String || v.isEmpty) {
      throw SeedFormatException('`$field` boş olmayan metin olmalı', id);
    }
    return v;
  }

  static String _strPlain(Object? v, String field) {
    if (v is! String || v.isEmpty) {
      throw FormatException('`$field` boş olmayan metin olmalı', '$v');
    }
    return v;
  }

  static bool _bool(Object? v, String field, String id) {
    if (v is! bool) {
      throw SeedFormatException('`$field` bool olmalı', id);
    }
    return v;
  }

  static int _int(Object? v, String field) {
    if (v is! int) {
      throw FormatException('`$field` tam sayı olmalı', '$v');
    }
    return v;
  }
}
