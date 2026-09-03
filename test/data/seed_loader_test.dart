import 'dart:convert';
import 'dart:io';

import 'package:carkeep/data/seed/seed_loader.dart';
import 'package:carkeep/domain/models/measure.dart';
import 'package:carkeep/domain/models/schedule.dart';
import 'package:flutter_test/flutter_test.dart';

/// Asset olarak paketlenen dosyanın kendisi okunur; `rootBundle` testte
/// kurulamadığı için diskten alınır (aynı dosya).
String _readSeed() => File('assets/seed/checklist_seed.json').readAsStringSync();

void main() {
  late Seed seed;

  setUpAll(() {
    seed = SeedLoader.parse(_readSeed());
  });

  group('gerçek şablon', () {
    test('34 madde yükleniyor', () {
      expect(seed.items.length, 34);
      expect(seed.version, 1);
    });

    test('madde id\'leri benzersiz', () {
      final Set<String> ids = <String>{
        for (final SeedItem i in seed.items) i.id,
      };
      expect(ids.length, 34);
    });

    test('grup başlıkları var ve her madde bilinen bir gruba ait', () {
      expect(seed.groups.length, 6);
      for (final SeedItem i in seed.items) {
        expect(kSeedGroups.contains(i.group), isTrue, reason: i.id);
        expect(seed.groups.containsKey(i.group), isTrue, reason: i.id);
      }
    });

    test('takvim türü dağılımı 03-kontrol-listesi ile aynı', () {
      final Map<ScheduleKind, int> counts = <ScheduleKind, int>{};
      for (final SeedItem i in seed.items) {
        counts[i.schedule.kind] = (counts[i.schedule.kind] ?? 0) + 1;
      }
      expect(counts[ScheduleKind.days], 24);
      expect(counts[ScheduleKind.km], 5);
      expect(counts[ScheduleKind.both], 4);
      expect(counts[ScheduleKind.seasonal], 1);
    });

    test('ölçüm tipi dağılımı', () {
      final Map<MeasureType, int> counts = <MeasureType, int>{};
      for (final SeedItem i in seed.items) {
        counts[i.measure.type] = (counts[i.measure.type] ?? 0) + 1;
      }
      expect(counts[MeasureType.none], 28);
      expect(counts[MeasureType.level], 4);
      expect(counts[MeasureType.tires], 1);
      expect(counts[MeasureType.number], 1);
    });

    test('29 madde varsayılan açık, 5 kapalı', () {
      final int on = seed.items
          .where((SeedItem i) => i.enabledByDefault)
          .length;
      expect(on, 29);
      expect(
        seed.items
            .where((SeedItem i) => !i.enabledByDefault)
            .map((SeedItem i) => i.id)
            .toList(),
        <String>[
          'adblue_level',
          'gearbox_oil',
          'kasko',
          'emission',
          'ac_check',
        ],
      );
    });

    test('verified != true olan her maddede sourceNote var', () {
      for (final SeedItem i in seed.items) {
        if (i.verified != 'true') {
          expect(i.sourceNote, isNotNull, reason: i.id);
        }
      }
    });

    test('startsFromInstall listesi 03-kontrol-listesi ile aynı', () {
      expect(
        seed.items
            .where((SeedItem i) => i.startsFromInstall)
            .map((SeedItem i) => i.id)
            .toList(),
        <String>[
          'oil_level',
          'tire_pressure',
          'coolant_level',
          'brake_fluid_level',
          'washer_fluid',
          'lights_horn',
          'tire_visual',
          'leak_check',
          'dpf_drive',
          'adblue_level',
          'tread_depth',
          'battery_terminals',
          'wiper_blades',
          'spare_tire',
          'belt_visual',
          'safety_kit',
          'ac_check',
          'winter_tires',
        ],
      );
    });

    test('appliesLastService yalnız oil_change ve pollen_filter', () {
      expect(
        seed.items
            .where((SeedItem i) => i.appliesLastService)
            .map((SeedItem i) => i.id)
            .toList(),
        <String>['oil_change', 'pollen_filter'],
      );
    });

    test('örnek maddeler doğru ayrıştırıldı', () {
      final SeedItem oil = seed.byId('oil_level')!;
      expect(oil.schedule.kind, ScheduleKind.days);
      expect(oil.schedule.intervalDays, 14);
      expect(oil.measure.type, MeasureType.level);
      expect(oil.measure.levels, <String>["Min'e yakın", 'Orta', "Max'a yakın"]);
      expect(oil.measure.isRequired, isTrue);
      expect(oil.how.length, 4);
      expect(oil.warn, isNotNull);

      final SeedItem tires = seed.byId('tire_pressure')!;
      expect(tires.measure.type, MeasureType.tires);
      expect(tires.measure.unit, 'bar');

      final SeedItem tread = seed.byId('tread_depth')!;
      expect(tread.measure.type, MeasureType.number);
      expect(tread.measure.unit, 'mm');
      expect(tread.measure.label, 'En düşük diş');
      expect(tread.measure.isRequired, isFalse);

      final SeedItem timing = seed.byId('timing_belt')!;
      expect(timing.schedule.kind, ScheduleKind.both);
      expect(timing.schedule.intervalDays, 1825);
      expect(timing.schedule.intervalKm, 120000);

      final SeedItem airFilter = seed.byId('air_filter')!;
      expect(airFilter.schedule.kind, ScheduleKind.km);
      expect(airFilter.schedule.intervalKm, 30000);
      expect(airFilter.schedule.intervalDays, isNull);

      final SeedItem winter = seed.byId('winter_tires')!;
      expect(winter.schedule.kind, ScheduleKind.seasonal);
      expect(winter.schedule.dates, <SeasonalDate>[
        const SeasonalDate(11, 1),
        const SeasonalDate(4, 1),
      ]);
      expect(winter.warn, isNull);
    });
  });

  group('doğrulama', () {
    Map<String, Object?> validRoot() =>
        jsonDecode(_readSeed()) as Map<String, Object?>;

    String encode(Map<String, Object?> root) => jsonEncode(root);

    test('bozuk JSON anlamlı hata fırlatıyor', () {
      expect(
        () => SeedLoader.parse('{ bu json degil'),
        throwsA(
          isA<SeedFormatException>().having(
            (SeedFormatException e) => e.message,
            'message',
            contains('JSON ayrıştırılamadı'),
          ),
        ),
      );
    });

    test('kök dizi olamaz', () {
      expect(
        () => SeedLoader.parse('[]'),
        throwsA(isA<SeedFormatException>()),
      );
    });

    test('version eksik veya geçersiz', () {
      final Map<String, Object?> root = validRoot()..remove('version');
      expect(
        () => SeedLoader.parse(encode(root)),
        throwsA(
          isA<SeedFormatException>().having(
            (SeedFormatException e) => e.message,
            'message',
            contains('version'),
          ),
        ),
      );
    });

    test('items boş olamaz', () {
      final Map<String, Object?> root = validRoot();
      root['items'] = <Object?>[];
      expect(
        () => SeedLoader.parse(encode(root)),
        throwsA(isA<SeedFormatException>()),
      );
    });

    test('yinelenen id yakalanıyor', () {
      final Map<String, Object?> root = validRoot();
      final List<Object?> items = root['items']! as List<Object?>;
      items.add(Map<String, Object?>.from(items.first as Map<String, Object?>));
      expect(
        () => SeedLoader.parse(encode(root)),
        throwsA(
          isA<SeedFormatException>()
              .having(
                (SeedFormatException e) => e.message,
                'message',
                contains('Yinelenen'),
              )
              .having(
                (SeedFormatException e) => e.itemId,
                'itemId',
                'oil_level',
              ),
        ),
      );
    });

    test('bilinmeyen grup yakalanıyor', () {
      final Map<String, Object?> root = validRoot();
      ((root['items']! as List<Object?>).first as Map<String, Object?>)['group'] =
          'uydurma';
      expect(
        () => SeedLoader.parse(encode(root)),
        throwsA(
          isA<SeedFormatException>().having(
            (SeedFormatException e) => e.message,
            'message',
            contains('Bilinmeyen grup'),
          ),
        ),
      );
    });

    test('geçersiz takvim türü yakalanıyor', () {
      final Map<String, Object?> root = validRoot();
      ((root['items']! as List<Object?>).first
              as Map<String, Object?>)['schedule'] =
          <String, Object?>{'kind': 'aylik', 'days': 30};
      expect(
        () => SeedLoader.parse(encode(root)),
        throwsA(
          isA<SeedFormatException>().having(
            (SeedFormatException e) => e.message,
            'message',
            contains('schedule'),
          ),
        ),
      );
    });

    test('negatif aralık yakalanıyor', () {
      final Map<String, Object?> root = validRoot();
      ((root['items']! as List<Object?>).first
              as Map<String, Object?>)['schedule'] =
          <String, Object?>{'kind': 'days', 'days': 0};
      expect(
        () => SeedLoader.parse(encode(root)),
        throwsA(isA<SeedFormatException>()),
      );
    });

    test('geçersiz ölçüm tipi yakalanıyor', () {
      final Map<String, Object?> root = validRoot();
      ((root['items']! as List<Object?>).first
              as Map<String, Object?>)['measure'] =
          <String, Object?>{'type': 'renk'};
      expect(
        () => SeedLoader.parse(encode(root)),
        throwsA(
          isA<SeedFormatException>().having(
            (SeedFormatException e) => e.message,
            'message',
            contains('measure'),
          ),
        ),
      );
    });

    test('number ölçümünde unit/label zorunlu', () {
      final Map<String, Object?> root = validRoot();
      ((root['items']! as List<Object?>).first
              as Map<String, Object?>)['measure'] =
          <String, Object?>{'type': 'number', 'unit': 'mm'};
      expect(
        () => SeedLoader.parse(encode(root)),
        throwsA(isA<SeedFormatException>()),
      );
    });

    test('verified != true iken sourceNote yoksa hata', () {
      final Map<String, Object?> root = validRoot();
      final Map<String, Object?> first =
          (root['items']! as List<Object?>).first as Map<String, Object?>;
      first['verified'] = 'partial';
      first.remove('sourceNote');
      expect(
        () => SeedLoader.parse(encode(root)),
        throwsA(
          isA<SeedFormatException>().having(
            (SeedFormatException e) => e.message,
            'message',
            contains('sourceNote zorunlu'),
          ),
        ),
      );
    });

    test('geçersiz verified değeri', () {
      final Map<String, Object?> root = validRoot();
      ((root['items']! as List<Object?>).first
          as Map<String, Object?>)['verified'] = 'belki';
      expect(
        () => SeedLoader.parse(encode(root)),
        throwsA(isA<SeedFormatException>()),
      );
    });

    test('eksik zorunlu alan (why) yakalanıyor', () {
      final Map<String, Object?> root = validRoot();
      ((root['items']! as List<Object?>).first as Map<String, Object?>)
          .remove('why');
      expect(
        () => SeedLoader.parse(encode(root)),
        throwsA(
          isA<SeedFormatException>().having(
            (SeedFormatException e) => e.itemId,
            'itemId',
            'oil_level',
          ),
        ),
      );
    });

    test('bool alan metin olarak verilirse hata', () {
      final Map<String, Object?> root = validRoot();
      ((root['items']! as List<Object?>).first
          as Map<String, Object?>)['enabledByDefault'] = 'true';
      expect(
        () => SeedLoader.parse(encode(root)),
        throwsA(isA<SeedFormatException>()),
      );
    });

    test('mevsimselde dates boş olamaz', () {
      final Map<String, Object?> root = validRoot();
      for (final Object? e in root['items']! as List<Object?>) {
        final Map<String, Object?> m = e! as Map<String, Object?>;
        if (m['id'] == 'winter_tires') {
          m['schedule'] = <String, Object?>{
            'kind': 'seasonal',
            'dates': <Object?>[],
          };
        }
      }
      expect(
        () => SeedLoader.parse(encode(root)),
        throwsA(isA<SeedFormatException>()),
      );
    });
  });

  group('Schedule / Measure gidiş dönüş', () {
    test('mevsimsel tarihler JSON gidiş dönüş', () {
      final Schedule s = Schedule.seasonal(<SeasonalDate>[
        const SeasonalDate(11, 1),
        const SeasonalDate(4, 1),
      ]);
      final Schedule back = Schedule.fromDb(
        kind: 'seasonal',
        seasonalDatesJson: s.seasonalDatesJson,
      );
      expect(back, s);
    });

    test('days/km/both DB gidiş dönüş', () {
      expect(Schedule.fromDb(kind: 'days', intervalDays: 14), Schedule.days(14));
      expect(Schedule.fromDb(kind: 'km', intervalKm: 30000), Schedule.km(30000));
      expect(
        Schedule.fromDb(kind: 'both', intervalDays: 365, intervalKm: 15000),
        Schedule.both(days: 365, km: 15000),
      );
    });

    test('eksik değerle DB dönüşümü hata veriyor', () {
      expect(
        () => Schedule.fromDb(kind: 'both', intervalDays: 365),
        throwsFormatException,
      );
      expect(() => Schedule.fromDb(kind: 'days'), throwsFormatException);
      expect(() => Schedule.fromDb(kind: 'seasonal'), throwsFormatException);
    });

    test('Measure DB gidiş dönüş', () {
      final Measure level = Measure.level(<String>['A', 'B']);
      expect(
        Measure.fromDb(type: 'level', json: level.json),
        level,
      );
      const Measure number = Measure.number(unit: 'mm', label: 'Diş');
      expect(Measure.fromDb(type: 'number', json: number.json), number);
      expect(Measure.fromDb(type: 'none'), const Measure.none());
      expect(
        Measure.fromDb(type: 'tires', json: const Measure.tires().json),
        const Measure.tires(),
      );
    });

    test('copyWith yalnız ilgili boyutu değiştiriyor', () {
      final Schedule both = Schedule.both(days: 365, km: 15000);
      expect(both.copyWith(intervalKm: 20000).intervalDays, 365);
      expect(both.copyWith(intervalKm: 20000).intervalKm, 20000);
      final Schedule seasonal = Schedule.seasonal(<SeasonalDate>[
        const SeasonalDate(11, 1),
      ]);
      expect(seasonal.copyWith(intervalKm: 1), seasonal);
    });
  });
}
