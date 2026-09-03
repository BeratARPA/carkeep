import 'package:carkeep/data/db/daos/settings_dao.dart';
import 'package:carkeep/data/db/database.dart';
import 'package:carkeep/domain/models/rules.dart';
// `isNull`/`isNotNull` hem drift'te (SQL ifadesi) hem matcher'da var.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late int vehicleId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    vehicleId = await db.vehicleDao.insertVehicle(
      VehiclesCompanion.insert(
        brand: 'Fiat',
        model: const Value<String>('Egea 1.6 MultiJet'),
        year: const Value<String>('2019'),
        currentKm: 118420,
        createdAt: DateTime(2026, 8, 20),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> addItem({
    String templateKey = 'oil_level',
    String name = 'Motor yağı seviyesi',
    int sortOrder = 0,
    bool enabled = true,
    String scheduleKind = 'days',
    int? intervalDays = 14,
    int? intervalKm,
  }) {
    return db.itemDao.insertOne(
      CheckItemsCompanion.insert(
        vehicleId: vehicleId,
        templateKey: Value<String?>(templateKey),
        name: name,
        groupKey: 'frequent',
        scheduleKind: scheduleKind,
        intervalDays: Value<int?>(intervalDays),
        intervalKm: Value<int?>(intervalKm),
        measureType: 'level',
        enabled: Value<bool>(enabled),
        sortOrder: sortOrder,
      ),
    );
  }

  // -------------------------------------------------------------- VehicleDao

  group('VehicleDao', () {
    test('get ve watch tek aracı veriyor', () async {
      final VehicleRow? v = await db.vehicleDao.get();
      expect(v, isNotNull);
      expect(v!.brand, 'Fiat');
      expect(v.currentKm, 118420);
      expect(v.btAddress, isNull);
      expect(v.tireFrontBar, isNull);
    });

    test('setCurrentKm günceller', () async {
      await db.vehicleDao.setCurrentKm(vehicleId, 119950);
      expect((await db.vehicleDao.get())!.currentKm, 119950);
    });

    test('setDevice ve setTargetPressure', () async {
      await db.vehicleDao.setDevice(
        vehicleId,
        address: '00:11:22:33:44:55',
        name: 'Uconnect',
      );
      await db.vehicleDao.setTargetPressure(vehicleId, front: 2.3, rear: 2.3);
      final VehicleRow v = (await db.vehicleDao.get())!;
      expect(v.btAddress, '00:11:22:33:44:55');
      expect(v.btName, 'Uconnect');
      expect(v.tireFrontBar, 2.3);
      expect(v.tireRearBar, 2.3);
    });

    test('deleteAll maddeleri de siliyor (cascade)', () async {
      await addItem();
      expect((await db.itemDao.getAll(vehicleId)).length, 1);
      await db.vehicleDao.deleteAll();
      expect(await db.vehicleDao.get(), isNull);
      expect((await db.itemDao.getAll(vehicleId)).length, 0);
    });
  });

  // ----------------------------------------------------------------- ItemDao

  group('ItemDao', () {
    test('watchAll sort_order sırasında yayınlıyor', () async {
      await addItem(templateKey: 'c', name: 'C', sortOrder: 2);
      await addItem(templateKey: 'a', name: 'A', sortOrder: 0);
      await addItem(templateKey: 'b', name: 'B', sortOrder: 1);

      final List<CheckItemRow> rows =
          await db.itemDao.watchAll(vehicleId).first;
      expect(rows.map((CheckItemRow r) => r.name).toList(), <String>[
        'A',
        'B',
        'C',
      ]);
    });

    test('insertAll toplu ekliyor', () async {
      await db.itemDao.insertAll(<CheckItemsCompanion>[
        for (int i = 0; i < 5; i++)
          CheckItemsCompanion.insert(
            vehicleId: vehicleId,
            templateKey: Value<String?>('k$i'),
            name: 'Madde $i',
            groupKey: 'monthly',
            scheduleKind: 'days',
            intervalDays: const Value<int?>(30),
            measureType: 'none',
            sortOrder: i,
          ),
      ]);
      expect((await db.itemDao.getAll(vehicleId)).length, 5);
    });

    test('(vehicle_id, template_key) benzersiz', () async {
      await addItem(templateKey: 'oil_level');
      expect(
        () => addItem(templateKey: 'oil_level', sortOrder: 1),
        throwsA(isA<Exception>()),
      );
    });

    test('kullanıcı maddesinde template_key null, birden çok olabilir',
        () async {
      await db.itemDao.insertOne(
        CheckItemsCompanion.insert(
          vehicleId: vehicleId,
          name: 'Kendi maddem 1',
          groupKey: 'custom',
          scheduleKind: 'days',
          intervalDays: const Value<int?>(30),
          measureType: 'none',
          sortOrder: 100,
        ),
      );
      await db.itemDao.insertOne(
        CheckItemsCompanion.insert(
          vehicleId: vehicleId,
          name: 'Kendi maddem 2',
          groupKey: 'custom',
          scheduleKind: 'days',
          intervalDays: const Value<int?>(30),
          measureType: 'none',
          sortOrder: 101,
        ),
      );
      expect((await db.itemDao.getAll(vehicleId)).length, 2);
    });

    test('setEnabled, setSnooze, setSortOrder', () async {
      final int id = await addItem();
      await db.itemDao.setEnabled(id, false);
      expect((await db.itemDao.getById(id))!.enabled, isFalse);

      await db.itemDao.setSnooze(id, '2026-09-04');
      expect((await db.itemDao.getById(id))!.snoozeUntilDay, '2026-09-04');

      await db.itemDao.setSortOrder(id, 42);
      expect((await db.itemDao.getById(id))!.sortOrder, 42);
    });

    test('setSchedule takvim türünü ve değerleri değiştiriyor', () async {
      final int id = await addItem();
      await db.itemDao.setSchedule(
        id,
        kind: 'both',
        intervalDays: 365,
        intervalKm: 15000,
      );
      final CheckItemRow r = (await db.itemDao.getById(id))!;
      expect(r.scheduleKind, 'both');
      expect(r.intervalDays, 365);
      expect(r.intervalKm, 15000);
      expect(r.seasonalDates, isNull);
    });

    test('setLastDone log oluşturmuyor ve ertelemeyi temizliyor', () async {
      final int id = await addItem();
      await db.itemDao.setSnooze(id, '2026-09-04');

      await db.itemDao.setLastDone(id, day: '2026-03-12', km: 104900);

      final CheckItemRow r = (await db.itemDao.getById(id))!;
      expect(r.lastDoneDay, '2026-03-12');
      expect(r.lastDoneKm, 104900);
      expect(r.snoozeUntilDay, isNull);
      expect((await db.logDao.getAll()).length, 0);
    });

    test('deleteItem kayıtları da siliyor (cascade)', () async {
      final int id = await addItem();
      await db.logDao.addLog(
        itemId: id,
        doneAt: DateTime(2026, 9, 3, 10),
        doneDay: '2026-09-03',
        km: 118420,
      );
      expect((await db.logDao.getAll()).length, 1);
      await db.itemDao.deleteItem(id);
      expect((await db.logDao.getAll()).length, 0);
    });
  });

  // ------------------------------------------------------------------ LogDao

  group('LogDao', () {
    test('log ekle → item last_done_* ve last_value güncellendi', () async {
      final int id = await addItem();
      await db.logDao.addLog(
        itemId: id,
        doneAt: DateTime(2026, 9, 3, 10),
        doneDay: '2026-09-03',
        km: 118420,
        value: 'Orta',
        note: 'Yarım litre ekledim',
      );

      final CheckItemRow r = (await db.itemDao.getById(id))!;
      expect(r.lastDoneDay, '2026-09-03');
      expect(r.lastDoneKm, 118420);
      expect(r.lastValue, 'Orta');
    });

    test('snooze_until_day log eklemede temizleniyor', () async {
      final int id = await addItem();
      await db.itemDao.setSnooze(id, '2026-09-04');
      await db.logDao.addLog(
        itemId: id,
        doneAt: DateTime(2026, 9, 3, 10),
        doneDay: '2026-09-03',
        km: 118420,
        value: 'Orta',
      );
      expect((await db.itemDao.getById(id))!.snoozeUntilDay, isNull);
    });

    test('son logu sil → bir önceki loga döndü', () async {
      final int id = await addItem();
      await db.logDao.addLog(
        itemId: id,
        doneAt: DateTime(2026, 8, 12, 10),
        doneDay: '2026-08-12',
        km: 117900,
        value: 'Orta',
      );
      final int second = await db.logDao.addLog(
        itemId: id,
        doneAt: DateTime(2026, 9, 3, 10),
        doneDay: '2026-09-03',
        km: 118420,
        value: "Max'a yakın",
      );

      expect((await db.itemDao.getById(id))!.lastDoneDay, '2026-09-03');

      await db.logDao.deleteLog(second);

      final CheckItemRow r = (await db.itemDao.getById(id))!;
      expect(r.lastDoneDay, '2026-08-12');
      expect(r.lastDoneKm, 117900);
      expect(r.lastValue, 'Orta');
    });

    test('tek logu sil → null', () async {
      final int id = await addItem();
      final int only = await db.logDao.addLog(
        itemId: id,
        doneAt: DateTime(2026, 9, 3, 10),
        doneDay: '2026-09-03',
        km: 118420,
        value: 'Orta',
      );
      await db.logDao.deleteLog(only);

      final CheckItemRow r = (await db.itemDao.getById(id))!;
      expect(r.lastDoneDay, isNull);
      expect(r.lastDoneKm, isNull);
      expect(r.lastValue, isNull);
    });

    test('ortadaki logu silmek son yapılışı değiştirmiyor', () async {
      final int id = await addItem();
      final int mid = await db.logDao.addLog(
        itemId: id,
        doneAt: DateTime(2026, 8, 12, 10),
        doneDay: '2026-08-12',
        km: 117900,
      );
      await db.logDao.addLog(
        itemId: id,
        doneAt: DateTime(2026, 9, 3, 10),
        doneDay: '2026-09-03',
        km: 118420,
      );

      await db.logDao.deleteLog(mid);

      expect((await db.itemDao.getById(id))!.lastDoneDay, '2026-09-03');
    });

    test('log silme ertelemeyi temizlemiyor', () async {
      final int id = await addItem();
      final int only = await db.logDao.addLog(
        itemId: id,
        doneAt: DateTime(2026, 9, 3, 10),
        doneDay: '2026-09-03',
        km: 118420,
      );
      await db.itemDao.setSnooze(id, '2026-09-04');
      await db.logDao.deleteLog(only);
      expect((await db.itemDao.getById(id))!.snoozeUntilDay, '2026-09-04');
    });

    test('watchAll yeni üstte', () async {
      final int a = await addItem(templateKey: 'a', name: 'A');
      final int b = await addItem(templateKey: 'b', name: 'B', sortOrder: 1);
      await db.logDao.addLog(
        itemId: a,
        doneAt: DateTime(2026, 8, 12, 10),
        doneDay: '2026-08-12',
        km: 117900,
      );
      await db.logDao.addLog(
        itemId: b,
        doneAt: DateTime(2026, 9, 3, 10),
        doneDay: '2026-09-03',
        km: 118420,
      );

      final List<CheckLogRow> rows = await db.logDao.watchAll().first;
      expect(
        rows.map((CheckLogRow r) => r.doneDay).toList(),
        <String>['2026-09-03', '2026-08-12'],
      );
    });

    test('lastN yalnız o maddenin son n kaydını veriyor', () async {
      final int a = await addItem(templateKey: 'a', name: 'A');
      final int b = await addItem(templateKey: 'b', name: 'B', sortOrder: 1);
      for (int i = 1; i <= 5; i++) {
        await db.logDao.addLog(
          itemId: a,
          doneAt: DateTime(2026, 8, i, 10),
          doneDay: '2026-08-0$i',
          km: 117000 + i,
        );
      }
      await db.logDao.addLog(
        itemId: b,
        doneAt: DateTime(2026, 9, 3, 10),
        doneDay: '2026-09-03',
        km: 118420,
      );

      final List<CheckLogRow> rows = await db.logDao.lastN(a, 3);
      expect(rows.length, 3);
      expect(
        rows.map((CheckLogRow r) => r.doneDay).toList(),
        <String>['2026-08-05', '2026-08-04', '2026-08-03'],
      );
    });

    test('olmayan logu silmek hata vermiyor', () async {
      await db.logDao.deleteLog(9999);
    });
  });

  // ----------------------------------------------------------------- TripDao

  group('TripDao', () {
    test('insert ve last', () async {
      await db.tripDao.insertTrip(
        TripsCompanion.insert(
          connectedAt: Value<DateTime?>(DateTime(2026, 9, 3, 14, 5)),
          disconnectedAt: DateTime(2026, 9, 3, 14, 30),
          durationMin: 25,
          counted: true,
          notified: true,
          overdueCount: const Value<int>(2),
          note: const Value<String?>('ok'),
        ),
      );
      await db.tripDao.insertTrip(
        TripsCompanion.insert(
          connectedAt: Value<DateTime?>(DateTime(2026, 9, 4, 8)),
          disconnectedAt: DateTime(2026, 9, 4, 8, 2),
          durationMin: 2,
          counted: false,
          notified: false,
          note: const Value<String?>('short_trip'),
        ),
      );

      final TripRow last = (await db.tripDao.lastTrip())!;
      expect(last.durationMin, 2);
      expect(last.counted, isFalse);
      expect(last.note, 'short_trip');
      expect(last.overdueCount, 0);
      expect((await db.tripDao.getAll()).length, 2);
    });

    test('connected_at null olabilir (bilinmeyen bağlantı)', () async {
      await db.tripDao.insertTrip(
        TripsCompanion.insert(
          disconnectedAt: DateTime(2026, 9, 3, 14, 30),
          durationMin: 0,
          counted: false,
          notified: false,
          note: const Value<String?>('short_trip'),
        ),
      );
      expect((await db.tripDao.lastTrip())!.connectedAt, isNull);
    });

    test('kayıt yokken last null', () async {
      expect(await db.tripDao.lastTrip(), isNull);
    });
  });

  // ------------------------------------------------------------- SettingsDao

  group('SettingsDao', () {
    test('get/set/getAll', () async {
      expect(await db.settingsDao.get(SettingKeys.installDay), isNull);
      await db.settingsDao.set(SettingKeys.installDay, '2026-08-20');
      expect(await db.settingsDao.get(SettingKeys.installDay), '2026-08-20');

      await db.settingsDao.set(SettingKeys.installDay, '2026-08-21');
      expect(await db.settingsDao.get(SettingKeys.installDay), '2026-08-21');

      await db.settingsDao.setInt(SettingKeys.templateVersion, 1);
      expect(await db.settingsDao.getInt(SettingKeys.templateVersion), 1);

      expect((await db.settingsDao.getAll()).length, 2);
    });

    test('null yazmak anahtarı siliyor', () async {
      await db.settingsDao.set(SettingKeys.globalSnoozeUntilDay, '2026-09-04');
      await db.settingsDao.set(SettingKeys.globalSnoozeUntilDay, null);
      expect(await db.settingsDao.get(SettingKeys.globalSnoozeUntilDay), isNull);
    });

    test('setBool/getBool', () async {
      await db.settingsDao.setBool(SettingKeys.batteryBannerDismissed, true);
      expect(
        await db.settingsDao.getBool(SettingKeys.batteryBannerDismissed),
        isTrue,
      );
      await db.settingsDao.setBool(SettingKeys.batteryBannerDismissed, false);
      expect(
        await db.settingsDao.getBool(SettingKeys.batteryBannerDismissed),
        isFalse,
      );
    });

    test('boş tabloda getRules varsayılanları veriyor', () async {
      expect(await db.settingsDao.getRules(), Rules.defaults);
      expect(Rules.defaults.onlyOverdue, isTrue);
      expect(Rules.defaults.oncePerDay, isTrue);
      expect(Rules.defaults.minTripMinutes, 5);
      expect(Rules.defaults.graceMinutes, 2);
      expect(Rules.defaults.fallbackAfterDays, 7);
    });

    test('setRules → getRules gidiş dönüş', () async {
      const Rules r = Rules(
        onlyOverdue: false,
        oncePerDay: false,
        minTripMinutes: 12,
        graceMinutes: 0,
        fallbackAfterDays: 0,
      );
      await db.settingsDao.setRules(r);
      expect(await db.settingsDao.getRules(), r);
    });

    test('yarım yazılmış kurallar varsayılana düşüyor', () async {
      await db.settingsDao.set(SettingKeys.ruleMinTripMinutes, '9');
      await db.settingsDao.set(SettingKeys.ruleOnlyOverdue, '0');
      final Rules r = await db.settingsDao.getRules();
      expect(r.minTripMinutes, 9);
      expect(r.onlyOverdue, isFalse);
      expect(r.oncePerDay, Rules.defaults.oncePerDay);
      expect(r.graceMinutes, Rules.defaults.graceMinutes);
    });

    test('bozuk sayı varsayılana düşüyor', () async {
      await db.settingsDao.set(SettingKeys.ruleMinTripMinutes, 'abc');
      expect(
        (await db.settingsDao.getRules()).minTripMinutes,
        Rules.defaults.minTripMinutes,
      );
    });

    test('watchRules değişimi yayınlıyor', () async {
      final Future<Rules> next = db.settingsDao
          .watchRules()
          .firstWhere((Rules r) => r.minTripMinutes == 15);
      await db.settingsDao.setRules(const Rules(minTripMinutes: 15));
      expect((await next).minTripMinutes, 15);
    });
  });

  // ------------------------------------------------------------------- şema

  group('şema', () {
    test('schemaVersion 2 (K-23)', () {
      expect(db.schemaVersion, 2);
    });

    test('yabancı anahtarlar açık', () async {
      final List<QueryRow> rows =
          await db.customSelect('PRAGMA foreign_keys').get();
      expect(rows.single.data.values.first, 1);
    });

    test('olmayan araca madde eklenemiyor', () async {
      expect(
        () => db.itemDao.insertOne(
          CheckItemsCompanion.insert(
            vehicleId: 9999,
            name: 'Hayalet',
            groupKey: 'custom',
            scheduleKind: 'days',
            intervalDays: const Value<int?>(30),
            measureType: 'none',
            sortOrder: 0,
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
