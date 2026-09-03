import 'dart:convert';
import 'dart:io';

import 'package:carkeep/data/db/daos/settings_dao.dart';
import 'package:carkeep/data/db/database.dart';
import 'package:carkeep/data/repositories/item_repo.dart';
import 'package:carkeep/data/seed/seed_loader.dart';
import 'package:carkeep/domain/models/measure.dart';
import 'package:carkeep/domain/models/schedule.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ItemRepo repo;
  late Seed seed;
  late int vehicleId;

  setUpAll(() {
    seed = SeedLoader.parse(
      File('assets/seed/checklist_seed.json').readAsStringSync(),
    );
  });

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ItemRepo(db);
    vehicleId = await db.vehicleDao.insertVehicle(
      VehiclesCompanion.insert(
        brand: 'Fiat',
        currentKm: 118420,
        createdAt: DateTime(2026, 8, 20),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('installSeed', () {
    test('34 madde seed sırasında ekleniyor', () async {
      await repo.installSeed(vehicleId, seed);
      final List<CheckItemRow> rows = await db.itemDao.getAll(vehicleId);
      expect(rows.length, 34);
      expect(
        rows.map((CheckItemRow r) => r.templateKey).toList(),
        seed.items.map((SeedItem i) => i.id).toList(),
      );
      expect(rows.map((CheckItemRow r) => r.sortOrder).toList(), <int>[
        for (int i = 0; i < 34; i++) i,
      ]);
    });

    test('enabled = enabledByDefault', () async {
      await repo.installSeed(vehicleId, seed);
      final List<CheckItemRow> rows = await db.itemDao.getAll(vehicleId);
      expect(rows.where((CheckItemRow r) => r.enabled).length, 29);
      expect(
        rows
            .where((CheckItemRow r) => !r.enabled)
            .map((CheckItemRow r) => r.templateKey)
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

    test('template_version yazılıyor', () async {
      await repo.installSeed(vehicleId, seed);
      expect(
        await db.settingsDao.getInt(SettingKeys.templateVersion),
        seed.version,
      );
    });

    test('alanlar eksiksiz kopyalanıyor', () async {
      await repo.installSeed(vehicleId, seed);
      final List<CheckItemRow> rows = await db.itemDao.getAll(vehicleId);

      final CheckItemRow oil = rows.firstWhere(
        (CheckItemRow r) => r.templateKey == 'oil_level',
      );
      expect(oil.name, 'Motor yağı seviyesi');
      expect(oil.groupKey, 'frequent');
      expect(oil.scheduleKind, 'days');
      expect(oil.intervalDays, 14);
      expect(oil.intervalKm, isNull);
      expect(oil.measureType, 'level');
      expect(
        Measure.fromDb(type: oil.measureType, json: oil.measureJson).levels,
        <String>["Min'e yakın", 'Orta', "Max'a yakın"],
      );
      expect(oil.why.isNotEmpty, isTrue);
      expect((jsonDecode(oil.howJson) as List<Object?>).length, 4);
      expect(oil.warn, isNotNull);
      expect(oil.startsFromInstall, isTrue);
      expect(oil.appliesLastService, isFalse);
      expect(oil.verified, 'true');
      expect(oil.sourceNote, isNull);
      expect(oil.lastDoneDay, isNull);
      expect(oil.snoozeUntilDay, isNull);

      final CheckItemRow timing = rows.firstWhere(
        (CheckItemRow r) => r.templateKey == 'timing_belt',
      );
      expect(timing.scheduleKind, 'both');
      expect(timing.intervalDays, 1825);
      expect(timing.intervalKm, 120000);
      expect(timing.startsFromInstall, isFalse);
      expect(timing.sourceNote, isNotNull);

      final CheckItemRow winter = rows.firstWhere(
        (CheckItemRow r) => r.templateKey == 'winter_tires',
      );
      expect(winter.scheduleKind, 'seasonal');
      expect(
        decodeSeasonalDates(winter.seasonalDates!),
        <SeasonalDate>[const SeasonalDate(11, 1), const SeasonalDate(4, 1)],
      );
      expect(winter.verified, 'partial');
      expect(winter.sourceNote, isNotNull);

      final CheckItemRow oilChange = rows.firstWhere(
        (CheckItemRow r) => r.templateKey == 'oil_change',
      );
      expect(oilChange.appliesLastService, isTrue);
    });

    test('DB\'den okunan her madde tipli modele dönüşebiliyor', () async {
      await repo.installSeed(vehicleId, seed);
      for (final CheckItemRow r in await db.itemDao.getAll(vehicleId)) {
        final Schedule s = Schedule.fromDb(
          kind: r.scheduleKind,
          intervalDays: r.intervalDays,
          intervalKm: r.intervalKm,
          seasonalDatesJson: r.seasonalDates,
        );
        final Measure m = Measure.fromDb(
          type: r.measureType,
          json: r.measureJson,
        );
        expect(s.kind, isNotNull, reason: r.templateKey);
        expect(m.type, isNotNull, reason: r.templateKey);
      }
    });
  });

  group('upgradeTemplateIfNeeded', () {
    test('aynı sürümde hiçbir şey yapmıyor', () async {
      await repo.installSeed(vehicleId, seed);
      final TemplateUpgradeResult r = await repo.upgradeTemplateIfNeeded(
        vehicleId,
        seed,
      );
      expect(r.addedCount, 0);
      expect(r.hasNewItems, isFalse);
      expect((await db.itemDao.getAll(vehicleId)).length, 34);
    });

    test('yeni sürümdeki yeni madde kapalı olarak ekleniyor', () async {
      await repo.installSeed(vehicleId, seed);

      final Seed v2 = Seed(
        version: 2,
        targetVehicle: seed.targetVehicle,
        groups: seed.groups,
        items: <SeedItem>[
          ...seed.items,
          SeedItem(
            id: 'yeni_madde',
            group: 'monthly',
            name: 'Yeni madde',
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
          ),
        ],
      );

      final TemplateUpgradeResult r = await repo.upgradeTemplateIfNeeded(
        vehicleId,
        v2,
      );
      expect(r.addedCount, 1);
      expect(r.hasNewItems, isTrue);
      expect(r.fromVersion, 1);
      expect(r.toVersion, 2);

      final List<CheckItemRow> rows = await db.itemDao.getAll(vehicleId);
      expect(rows.length, 35);
      final CheckItemRow added = rows.last;
      expect(added.templateKey, 'yeni_madde');
      // enabledByDefault true olmasına rağmen yükseltmede kapalı gelir.
      expect(added.enabled, isFalse);
      expect(added.sortOrder, 34);
      expect(
        await db.settingsDao.getInt(SettingKeys.templateVersion),
        2,
      );
    });

    test('kullanıcı değişiklikleri ezilmiyor', () async {
      await repo.installSeed(vehicleId, seed);
      final CheckItemRow oil = (await db.itemDao.getAll(vehicleId)).firstWhere(
        (CheckItemRow r) => r.templateKey == 'oil_level',
      );
      await db.itemDao.setSchedule(oil.id, kind: 'days', intervalDays: 7);
      await db.itemDao.setEnabled(oil.id, false);
      await db.itemDao.setLastDone(oil.id, day: '2026-08-12', km: 117900);

      final Seed v2 = Seed(
        version: 2,
        targetVehicle: seed.targetVehicle,
        groups: seed.groups,
        items: seed.items,
      );
      await repo.upgradeTemplateIfNeeded(vehicleId, v2);

      final CheckItemRow after = (await db.itemDao.getById(oil.id))!;
      expect(after.intervalDays, 7);
      expect(after.enabled, isFalse);
      expect(after.lastDoneDay, '2026-08-12');
      expect(after.lastDoneKm, 117900);
    });

    test('seed\'den kaldırılan madde DB\'de kalıyor', () async {
      await repo.installSeed(vehicleId, seed);
      final Seed v2 = Seed(
        version: 2,
        targetVehicle: seed.targetVehicle,
        groups: seed.groups,
        items: seed.items
            .where((SeedItem i) => i.id != 'kasko')
            .toList(growable: false),
      );
      await repo.upgradeTemplateIfNeeded(vehicleId, v2);

      final List<CheckItemRow> rows = await db.itemDao.getAll(vehicleId);
      expect(rows.length, 34);
      expect(
        rows.any((CheckItemRow r) => r.templateKey == 'kasko'),
        isTrue,
      );
    });

    test('template_version hiç yazılmamışsa yükseltme çalışıyor', () async {
      final TemplateUpgradeResult r = await repo.upgradeTemplateIfNeeded(
        vehicleId,
        seed,
      );
      expect(r.fromVersion, isNull);
      expect(r.addedCount, 34);
      expect((await db.itemDao.getAll(vehicleId)).length, 34);
    });

    test('kullanıcı maddesi varken yeni madde en sona ekleniyor', () async {
      await repo.installSeed(vehicleId, seed);
      await db.itemDao.insertOne(
        CheckItemsCompanion.insert(
          vehicleId: vehicleId,
          name: 'Kendi maddem',
          groupKey: 'custom',
          scheduleKind: 'days',
          intervalDays: const Value<int?>(30),
          measureType: 'none',
          sortOrder: 100,
        ),
      );

      final Seed v2 = Seed(
        version: 2,
        targetVehicle: seed.targetVehicle,
        groups: seed.groups,
        items: <SeedItem>[
          ...seed.items,
          SeedItem(
            id: 'yeni_madde',
            group: 'monthly',
            name: 'Yeni madde',
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
          ),
        ],
      );
      await repo.upgradeTemplateIfNeeded(vehicleId, v2);

      final List<CheckItemRow> rows = await db.itemDao.getAll(vehicleId);
      expect(rows.last.templateKey, 'yeni_madde');
      expect(rows.last.sortOrder, 101);
    });
  });
}
