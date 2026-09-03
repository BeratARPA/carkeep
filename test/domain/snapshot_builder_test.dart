import 'dart:convert';

import 'package:carkeep/domain/models/check_item.dart';
import 'package:carkeep/domain/models/rules.dart';
import 'package:carkeep/domain/models/schedule.dart';
import 'package:carkeep/domain/models/vehicle.dart';
import 'package:carkeep/domain/snapshot_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import 'status_calculator_test.dart' show item, kInstallDay, kToday;

Vehicle vehicle({
  String? address = '00:11:22:33:44:55',
  String? name = 'Uconnect',
  int km = 118420,
}) {
  return Vehicle(
    id: 1,
    brand: 'Fiat',
    model: 'Egea 1.6 MultiJet',
    year: '2019',
    currentKm: km,
    btAddress: address,
    btName: name,
    tireFrontBar: 2.3,
    tireRearBar: 2.3,
    createdAt: DateTime(2026, 8, 20),
  );
}

Map<String, Object?> build(
  List<CheckItem> items, {
  Vehicle? v,
  Rules rules = Rules.defaults,
}) {
  return SnapshotBuilder.build(
    vehicle: v ?? vehicle(),
    items: items,
    rules: rules,
    installDay: kInstallDay,
    today: kToday,
    generatedAt: DateTime(2026, 9, 3, 14, 5, 12),
  );
}

void main() {
  group('şema', () {
    test('kök alanlar 02-mimari §5 ile aynı', () {
      final Map<String, Object?> s = build(<CheckItem>[]);
      expect(s.keys.toSet(), <String>{
        'version',
        'generatedAt',
        'car',
        'rules',
        'items',
      });
      expect(s['version'], 1);
    });

    test('car alanı', () {
      final Map<String, Object?> car =
          build(<CheckItem>[])['car']! as Map<String, Object?>;
      expect(car.keys.toSet(), <String>{'address', 'name', 'km'});
      expect(car['address'], '00:11:22:33:44:55');
      expect(car['name'], 'Uconnect');
      expect(car['km'], 118420);
    });

    test('rules alanı', () {
      final Map<String, Object?> rules =
          build(<CheckItem>[])['rules']! as Map<String, Object?>;
      expect(rules, <String, Object?>{
        'onlyOverdue': true,
        'oncePerDay': true,
        'minTripMinutes': 5,
        'graceMinutes': 2,
        'fallbackAfterDays': 7,
      });
    });

    test('kural değişikliği snapshot\'a yansıyor', () {
      final Map<String, Object?> rules =
          build(
                <CheckItem>[],
                rules: const Rules(
                  onlyOverdue: false,
                  oncePerDay: false,
                  minTripMinutes: 12,
                  graceMinutes: 0,
                  fallbackAfterDays: 0,
                ),
              )['rules']!
              as Map<String, Object?>;
      expect(rules['onlyOverdue'], false);
      expect(rules['minTripMinutes'], 12);
      expect(rules['fallbackAfterDays'], 0);
    });

    test('madde alanları', () {
      final Map<String, Object?> s = build(<CheckItem>[
        item(
          id: 12,
          name: 'Motor yağı seviyesi',
          schedule: Schedule.days(14),
          lastDoneDay: '2026-08-12',
        ),
      ]);
      final List<Object?> items = s['items']! as List<Object?>;
      expect(items.length, 1);
      final Map<String, Object?> i = items.single! as Map<String, Object?>;
      expect(i.keys.toSet(), <String>{
        'id',
        'name',
        'dueDay',
        'dueKm',
        'snoozeUntilDay',
      });
      expect(i['id'], 12);
      expect(i['name'], 'Motor yağı seviyesi');
      expect(i['dueDay'], '2026-08-26');
      expect(i['dueKm'], isNull);
      expect(i['snoozeUntilDay'], isNull);
    });

    test('both maddede hem dueDay hem dueKm var', () {
      final Map<String, Object?> s = build(<CheckItem>[
        item(
          id: 21,
          name: 'Motor yağı ve yağ filtresi',
          schedule: Schedule.both(days: 365, km: 15000),
          lastDoneDay: '2026-03-12',
          lastDoneKm: 104900,
        ),
      ]);
      final Map<String, Object?> i =
          (s['items']! as List<Object?>).single! as Map<String, Object?>;
      expect(i['dueDay'], '2027-03-12');
      expect(i['dueKm'], 119900);
    });

    test('km maddede dueDay null', () {
      final Map<String, Object?> s = build(<CheckItem>[
        item(schedule: Schedule.km(30000), lastDoneKm: 100000),
      ]);
      final Map<String, Object?> i =
          (s['items']! as List<Object?>).single! as Map<String, Object?>;
      expect(i['dueDay'], isNull);
      expect(i['dueKm'], 130000);
    });

    test('snoozeUntilDay geçiyor', () {
      final Map<String, Object?> s = build(<CheckItem>[
        item(
          schedule: Schedule.days(14),
          lastDoneDay: '2026-08-12',
          snoozeUntilDay: '2026-09-04',
        ),
      ]);
      final Map<String, Object?> i =
          (s['items']! as List<Object?>).single! as Map<String, Object?>;
      expect(i['snoozeUntilDay'], '2026-09-04');
    });
  });

  group('filtreleme (01-spec §6)', () {
    test('unknown madde snapshot\'a girmiyor', () {
      final Map<String, Object?> s = build(<CheckItem>[
        item(id: 1, schedule: Schedule.km(30000)),
        item(id: 2, schedule: Schedule.km(30000), lastDoneKm: 100000),
        item(id: 3, schedule: Schedule.both(days: 365, km: 15000)),
      ]);
      final List<Object?> items = s['items']! as List<Object?>;
      expect(items.length, 1);
      expect((items.single! as Map<String, Object?>)['id'], 2);
    });

    test('kapalı madde snapshot\'a girmiyor', () {
      final Map<String, Object?> s = build(<CheckItem>[
        item(
          id: 1,
          schedule: Schedule.days(14),
          lastDoneDay: '2026-08-12',
          enabled: false,
        ),
        item(id: 2, schedule: Schedule.days(14), lastDoneDay: '2026-08-12'),
      ]);
      final List<Object?> items = s['items']! as List<Object?>;
      expect(items.length, 1);
      expect((items.single! as Map<String, Object?>)['id'], 2);
    });

    test('madde sırası girdi sırasını koruyor', () {
      final Map<String, Object?> s = build(<CheckItem>[
        item(id: 3, schedule: Schedule.days(14), lastDoneDay: '2026-08-12'),
        item(id: 1, schedule: Schedule.days(14), lastDoneDay: '2026-08-12'),
        item(id: 2, schedule: Schedule.days(14), lastDoneDay: '2026-08-12'),
      ]);
      expect(
        (s['items']! as List<Object?>)
            .map((Object? e) => (e! as Map<String, Object?>)['id'])
            .toList(),
        <int>[3, 1, 2],
      );
    });
  });

  group('araç yokken', () {
    test('araç null → snapshot yine yazılır, maddeler boş', () {
      final Map<String, Object?> s = SnapshotBuilder.build(
        vehicle: null,
        items: <CheckItem>[
          item(schedule: Schedule.days(14), lastDoneDay: '2026-08-12'),
        ],
        rules: Rules.defaults,
        installDay: kInstallDay,
        today: kToday,
        generatedAt: DateTime(2026, 9, 3, 14, 5, 12),
      );
      expect(s['items'], isEmpty);
      final Map<String, Object?> car = s['car']! as Map<String, Object?>;
      expect(car['address'], isNull);
      expect(car['km'], 0);
    });

    test('cihaz seçilmemişse address null, snapshot yine yazılır', () {
      final Map<String, Object?> s = build(
        <CheckItem>[
          item(schedule: Schedule.days(14), lastDoneDay: '2026-08-12'),
        ],
        v: vehicle(address: null, name: null),
      );
      final Map<String, Object?> car = s['car']! as Map<String, Object?>;
      expect(car['address'], isNull);
      expect(car['name'], isNull);
      expect((s['items']! as List<Object?>).length, 1);
    });
  });

  group('generatedAt', () {
    test('ISO 8601 + yerel offset biçimi', () {
      final String iso = isoWithLocalOffset(DateTime(2026, 9, 3, 14, 5, 12));
      expect(
        RegExp(r'^2026-09-03T14:05:12[+-]\d{2}:\d{2}$').hasMatch(iso),
        isTrue,
        reason: iso,
      );
    });

    test('tek haneli değerler sıfır dolgulu', () {
      final String iso = isoWithLocalOffset(DateTime(2026, 1, 5, 9, 5, 3));
      expect(iso.startsWith('2026-01-05T09:05:03'), isTrue, reason: iso);
    });
  });

  group('JSON', () {
    test('buildJson çözülebiliyor ve build ile aynı', () {
      final List<CheckItem> items = <CheckItem>[
        item(id: 12, schedule: Schedule.days(14), lastDoneDay: '2026-08-12'),
        item(
          id: 21,
          schedule: Schedule.both(days: 365, km: 15000),
          lastDoneDay: '2026-03-12',
          lastDoneKm: 104900,
        ),
      ];
      final String json = SnapshotBuilder.buildJson(
        vehicle: vehicle(),
        items: items,
        rules: Rules.defaults,
        installDay: kInstallDay,
        today: kToday,
        generatedAt: DateTime(2026, 9, 3, 14, 5, 12),
      );
      final Object? decoded = jsonDecode(json);
      expect(decoded, isA<Map<String, Object?>>());
      expect(decoded, build(items));
    });

    test('null alanlar JSON\'da açıkça null olarak yazılıyor', () {
      final String json = SnapshotBuilder.buildJson(
        vehicle: vehicle(),
        items: <CheckItem>[
          item(id: 12, schedule: Schedule.days(14), lastDoneDay: '2026-08-12'),
        ],
        rules: Rules.defaults,
        installDay: kInstallDay,
        today: kToday,
        generatedAt: DateTime(2026, 9, 3, 14, 5, 12),
      );
      // Kotlin tarafı bu null'ları `isNull(key)` ile okumak zorunda;
      // `optString(...).ifEmpty{null}` "null" metnini döndürür (denetim md. 1).
      expect(json.contains('"dueKm":null'), isTrue);
      expect(json.contains('"snoozeUntilDay":null'), isTrue);
    });
  });
}
