import 'dart:io';

import 'package:carkeep/data/seed/seed_loader.dart';
import 'package:carkeep/domain/models/measure.dart';
import 'package:carkeep/domain/models/schedule.dart';
import 'package:carkeep/domain/template_merge.dart';
import 'package:flutter_test/flutter_test.dart';

SeedItem _item(String id, {String group = 'monthly'}) => SeedItem(
  id: id,
  group: group,
  name: 'Madde $id',
  schedule: Schedule.days(30),
  measure: const Measure.none(),
  why: 'neden',
  how: const <String>['nasıl'],
  warn: null,
  startsFromInstall: true,
  appliesLastService: false,
  enabledByDefault: true,
  verified: 'true',
  sourceNote: null,
);

void main() {
  late Seed realSeed;

  setUpAll(() {
    realSeed = SeedLoader.parse(
      File('assets/seed/checklist_seed.json').readAsStringSync(),
    );
  });

  test('boş DB → 34 insert (ilk kurulum)', () {
    final MergePlan p = TemplateMerge.plan(
      realSeed.items,
      const <ExistingItem>[],
    );
    expect(p.toInsert.length, 34);
    expect(p.unchangedCount, 0);
    expect(p.removedFromSeed, isEmpty);
    expect(p.nextSortOrder, 0);
    expect(p.isEmpty, isFalse);
  });

  test('aynı sürüm, tam DB → 0 insert', () {
    final MergePlan p = TemplateMerge.plan(realSeed.items, <ExistingItem>[
      for (int i = 0; i < realSeed.items.length; i++)
        ExistingItem(templateKey: realSeed.items[i].id, sortOrder: i),
    ]);
    expect(p.toInsert, isEmpty);
    expect(p.unchangedCount, 34);
    expect(p.isEmpty, isTrue);
    expect(p.nextSortOrder, 34);
  });

  test('yeni seed maddesi ekleniyor, mevcutlar dokunulmuyor', () {
    final List<SeedItem> seed = <SeedItem>[
      _item('a'),
      _item('b'),
      _item('c'),
    ];
    final MergePlan p = TemplateMerge.plan(seed, <ExistingItem>[
      const ExistingItem(templateKey: 'a', sortOrder: 0),
      const ExistingItem(templateKey: 'b', sortOrder: 1),
    ]);
    expect(p.toInsert.map((SeedItem s) => s.id).toList(), <String>['c']);
    expect(p.unchangedCount, 2);
    expect(p.nextSortOrder, 2);
  });

  test('DB\'de kullanıcı aralığı değişmiş madde → dokunulmuyor', () {
    // Birleştirme yalnız template_key'e bakar; DB'deki aralık/ad/enabled
    // hiç okunmaz, dolayısıyla ezilmesi de mümkün değil.
    final MergePlan p = TemplateMerge.plan(<SeedItem>[
      _item('oil_change'),
    ], <ExistingItem>[
      const ExistingItem(templateKey: 'oil_change', sortOrder: 15),
    ]);
    expect(p.toInsert, isEmpty);
    expect(p.unchangedCount, 1);
  });

  test('seed\'de olmayan DB maddesi kalıyor, raporlanıyor', () {
    final MergePlan p = TemplateMerge.plan(<SeedItem>[
      _item('a'),
    ], <ExistingItem>[
      const ExistingItem(templateKey: 'a', sortOrder: 0),
      const ExistingItem(templateKey: 'eski_madde', sortOrder: 1),
    ]);
    expect(p.toInsert, isEmpty);
    expect(p.removedFromSeed, <String>['eski_madde']);
  });

  test('kullanıcı maddeleri (template_key null) birleştirmeyi etkilemiyor', () {
    final MergePlan p = TemplateMerge.plan(<SeedItem>[
      _item('a'),
      _item('b'),
    ], <ExistingItem>[
      const ExistingItem(templateKey: 'a', sortOrder: 0),
      const ExistingItem(templateKey: null, sortOrder: 50),
      const ExistingItem(templateKey: null, sortOrder: 51),
    ]);
    expect(p.toInsert.map((SeedItem s) => s.id).toList(), <String>['b']);
    expect(p.removedFromSeed, isEmpty);
    // Yeni madde en sona eklenir, kullanıcı maddelerinin arkasına.
    expect(p.nextSortOrder, 52);
  });

  test('sort_order boşluklu olsa da sıradaki değer en büyüğün bir fazlası', () {
    final MergePlan p = TemplateMerge.plan(<SeedItem>[
      _item('a'),
      _item('b'),
    ], <ExistingItem>[
      const ExistingItem(templateKey: 'a', sortOrder: 7),
    ]);
    expect(p.nextSortOrder, 8);
  });

  test('birden çok yeni madde seed sırasını koruyor', () {
    final MergePlan p = TemplateMerge.plan(<SeedItem>[
      _item('a'),
      _item('yeni1'),
      _item('b'),
      _item('yeni2'),
    ], <ExistingItem>[
      const ExistingItem(templateKey: 'a', sortOrder: 0),
      const ExistingItem(templateKey: 'b', sortOrder: 1),
    ]);
    expect(
      p.toInsert.map((SeedItem s) => s.id).toList(),
      <String>['yeni1', 'yeni2'],
    );
  });

  test('boş seed → hiçbir şey', () {
    final MergePlan p = TemplateMerge.plan(
      const <SeedItem>[],
      const <ExistingItem>[
        ExistingItem(templateKey: 'a', sortOrder: 0),
      ],
    );
    expect(p.toInsert, isEmpty);
    expect(p.unchangedCount, 0);
    expect(p.removedFromSeed, <String>['a']);
  });
}
