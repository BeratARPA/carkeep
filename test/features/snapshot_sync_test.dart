import 'dart:convert';
import 'dart:io';

import 'package:carkeep/app.dart';
import 'package:carkeep/core/date_utils.dart';
import 'package:carkeep/core/strings_tr.dart';
import 'package:carkeep/data/db/database.dart';
import 'package:carkeep/data/repositories/item_list_repo.dart';
import 'package:carkeep/data/repositories/item_repo.dart';
import 'package:carkeep/data/repositories/log_repo.dart';
import 'package:carkeep/data/seed/seed_loader.dart';
import 'package:carkeep/domain/models/measure.dart';
import 'package:carkeep/domain/models/rules.dart';
import 'package:carkeep/domain/models/schedule.dart';
import 'package:carkeep/lifecycle.dart';
import 'package:carkeep/providers.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'setup_test.dart' show FakeBridge;

/// T15: 01-spec §6'daki her tetikleyici snapshot'ı yeniden yazıyor mu.
void main() {
  late Seed seed;

  setUpAll(() {
    seed = SeedLoader.parse(
      File('assets/seed/checklist_seed.json').readAsStringSync(),
    );
  });

  late AppDatabase db;
  late FakeBridge bridge;
  final DateTime today = DateTime(2026, 9, 3);
  final DateTime installDay = DateTime(2026, 8, 20);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bridge = FakeBridge(bluetooth: true, notification: true, battery: true);
    addTearDown(db.close);
  });

  Future<int> seedVehicle() async {
    final int id = await db.vehicleDao.insertVehicle(
      VehiclesCompanion.insert(
        brand: 'Fiat',
        model: const Value<String>('Egea'),
        currentKm: 118420,
        btName: const Value<String?>('Uconnect'),
        btAddress: const Value<String?>('12:34:56:78:9A:BC'),
        createdAt: DateTime(2026, 8, 20),
      ),
    );
    await ItemRepo(db).installSeed(id, seed);
    return id;
  }

  Future<int> itemId(int vehicleId, String templateKey) async =>
      (await db.itemDao.getAll(vehicleId))
          .firstWhere((CheckItemRow r) => r.templateKey == templateKey)
          .id;

  ProviderContainer makeContainer({DateTime? day}) {
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        seedProvider.overrideWithValue(seed),
        platformBridgeProvider.overrideWithValue(bridge),
        todayProvider.overrideWith((Ref ref) => day ?? today),
        installDayProvider.overrideWith((Ref ref) => installDay),
        snapshotDebounceProvider.overrideWithValue(Duration.zero),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  /// Debounce sıfır; bir tur bekle.
  Future<void> settle() async {
    for (int i = 0; i < 4; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  }

  /// Senkronu ayağa kaldırır ve ilk yazımı bekler.
  Future<ProviderContainer> startSync({DateTime? day}) async {
    final ProviderContainer c = makeContainer(day: day);
    await c.read(vehicleProvider.future);
    await c.read(itemsProvider.future);
    c.read(snapshotSyncProvider);
    await settle();
    return c;
  }

  Future<Map<String, Object?>> snapshot() async {
    final String? raw = await bridge.readSnapshot();
    expect(raw, isNotNull, reason: 'snapshot yazılmadı');
    return jsonDecode(raw!) as Map<String, Object?>;
  }

  Future<Map<String, Object?>> car() async =>
      (await snapshot())['car']! as Map<String, Object?>;

  Future<List<Map<String, Object?>>> items() async => <Map<String, Object?>>[
    for (final Object? e in (await snapshot())['items']! as List<Object?>)
      e! as Map<String, Object?>,
  ];

  Future<Map<String, Object?>?> itemById(int id) async {
    for (final Map<String, Object?> e in await items()) {
      if (e['id'] == id) {
        return e;
      }
    }
    return null;
  }

  // ----------------------------------------------- 01-spec §6 tetikleyicileri

  group('tetikleyiciler', () {
    test('kayıt: dueDay ilerliyor', () async {
      final int v = await seedVehicle();
      final int oil = await itemId(v, 'oil_level');
      await db.itemDao.setLastDone(oil, day: '2026-08-20', km: null);
      final ProviderContainer c = await startSync();

      expect((await itemById(oil))!['dueDay'], '2026-09-03');

      await c.read(logRepoProvider).add(
        itemId: oil,
        doneAt: DateTime(2026, 9, 3, 10),
        doneDay: '2026-09-03',
        km: 118420,
        value: 'Orta',
      );
      await settle();

      // 14 günlük madde, bugün yapıldı → 17 Eyl.
      expect((await itemById(oil))!['dueDay'], '2026-09-17');
    });

    test('kayıt silme: dueDay geri gidiyor', () async {
      final int v = await seedVehicle();
      final int oil = await itemId(v, 'oil_level');
      final ProviderContainer c = await startSync();
      final LogRepo logs = c.read(logRepoProvider);

      final int id = await logs.add(
        itemId: oil,
        doneAt: DateTime(2026, 9, 3, 10),
        doneDay: '2026-09-03',
        km: 118420,
        value: 'Orta',
      );
      await settle();
      expect((await itemById(oil))!['dueDay'], '2026-09-17');

      await logs.delete(id);
      await settle();
      // Kayıt kalmadı; `startsFromInstall` madde olduğu için vade kurulum
      // gününe döner (20 Ağu + 14 = 3 Eyl), `unknown` olmaz.
      expect((await itemById(oil))!['dueDay'], '2026-09-03');
    });

    test('tarih düzeltme', () async {
      final int v = await seedVehicle();
      final int oil = await itemId(v, 'oil_level');
      final ProviderContainer c = await startSync();

      await c.read(itemListRepoProvider).setLastDone(
        oil,
        day: '2026-09-01',
        km: null,
      );
      await settle();

      expect((await itemById(oil))!['dueDay'], '2026-09-15');
    });

    test('km girişi: car.km ve km maddesinin durumu', () async {
      final int v = await seedVehicle();
      final ProviderContainer c = await startSync();
      expect((await car())['km'], 118420);

      await c.read(vehicleRepoProvider).setCurrentKm(v, 119950);
      await settle();

      expect((await car())['km'], 119950);
    });

    test('madde kapatma ve açma', () async {
      final int v = await seedVehicle();
      final int oil = await itemId(v, 'oil_level');
      await db.itemDao.setLastDone(oil, day: '2026-08-20', km: null);
      final ProviderContainer c = await startSync();
      expect(await itemById(oil), isNotNull);

      final ItemListRepo repo = c.read(itemListRepoProvider);
      await repo.setEnabled(oil, false);
      await settle();
      expect(await itemById(oil), isNull);

      await repo.setEnabled(oil, true);
      await settle();
      expect(await itemById(oil), isNotNull);
    });

    test('aralık değişikliği', () async {
      final int v = await seedVehicle();
      final int oil = await itemId(v, 'oil_level');
      await db.itemDao.setLastDone(oil, day: '2026-08-20', km: null);
      final ProviderContainer c = await startSync();
      expect((await itemById(oil))!['dueDay'], '2026-09-03');

      await c.read(itemListRepoProvider).setSchedule(oil, Schedule.days(30));
      await settle();

      expect((await itemById(oil))!['dueDay'], '2026-09-19');
    });

    test('madde ekleme ve silme', () async {
      final int v = await seedVehicle();
      final ProviderContainer c = await startSync();
      final int before = (await items()).length;

      final int id = await c.read(itemListRepoProvider).createUserItem(
        vehicleId: v,
        name: 'Yakıt filtresi',
        groupKey: 'service',
        schedule: Schedule.days(30),
        measure: const Measure.none(),
      );
      await c.read(itemListRepoProvider).setLastDone(
        id,
        day: '2026-08-20',
        km: null,
      );
      await settle();
      expect((await items()).length, before + 1);
      expect((await itemById(id))!['name'], 'Yakıt filtresi');

      await c.read(itemListRepoProvider).deleteItem(id);
      await settle();
      expect(await itemById(id), isNull);
    });

    test('kural değişikliği', () async {
      await seedVehicle();
      final ProviderContainer c = await startSync();
      expect(
        ((await snapshot())['rules']! as Map<String, Object?>)['minTripMinutes'],
        5,
      );

      await c.read(settingsRepoProvider).setRules(
        Rules.defaults.copyWith(minTripMinutes: 9),
      );
      await settle();

      expect(
        ((await snapshot())['rules']! as Map<String, Object?>)['minTripMinutes'],
        9,
      );
    });

    test('cihaz değişikliği: car bloğu', () async {
      final int v = await seedVehicle();
      final ProviderContainer c = await startSync();
      expect((await car())['address'], '12:34:56:78:9A:BC');

      await c.read(vehicleRepoProvider).setDevice(
        v,
        address: 'AA:BB:CC:DD:EE:FF',
        name: 'Başka araba',
      );
      await settle();

      // Durum listesi hiç değişmedi; yine de yazılmalı, yoksa motor eski
      // cihazı dinlemeye devam ederdi.
      expect((await car())['address'], 'AA:BB:CC:DD:EE:FF');
      expect((await car())['name'], 'Başka araba');
    });

    test('erteleme: snoozeUntilDay snapshot\'a giriyor', () async {
      final int v = await seedVehicle();
      final int oil = await itemId(v, 'oil_level');
      await db.itemDao.setLastDone(oil, day: '2026-08-01', km: null);
      final ProviderContainer c = await startSync();
      expect((await itemById(oil))!['snoozeUntilDay'], isNull);

      await c.read(itemListRepoProvider).setSnooze(oil, '2026-09-04');
      await settle();

      expect((await itemById(oil))!['snoozeUntilDay'], '2026-09-04');
    });

    test('gün değişimi: vadeler yeni güne göre yeniden yazılıyor', () async {
      final int v = await seedVehicle();
      final int oil = await itemId(v, 'oil_level');
      // 3 Eyl'de yaklaşan, 20 Eyl'de gecikmiş.
      await db.itemDao.setLastDone(oil, day: '2026-08-20', km: null);
      final ProviderContainer c = await startSync();
      expect((await itemById(oil))!['dueDay'], '2026-09-03');

      c.read(todayProvider.notifier).state = DateTime(2026, 9, 20);
      await settle();

      // Vade değişmedi ama snapshot yeniden yazıldı: `generatedAt` ilerledi
      // ve madde artık gecikmiş sayılıyor (Kotlin `dueDay < today` diyecek).
      expect((await itemById(oil))!['dueDay'], '2026-09-03');
      expect(c.read(snapshotSyncProvider).writeCount, greaterThan(1));
    });

    test('resume snapshot yazıyor', () async {
      await seedVehicle();
      final ProviderContainer c = await startSync();
      final int before = c.read(snapshotSyncProvider).writeCount;

      await c.read(appLifecycleProvider).onResume();

      expect(c.read(snapshotSyncProvider).writeCount, greaterThan(before));
    });
  });

  // ------------------------------------------------------- gece yarısı (T15)

  group('gece yarısı geçişi', () {
    test('resume bugünü tazeliyor', () async {
      await seedVehicle();
      final ProviderContainer c = await startSync(day: DateTime(2020, 1, 1));
      expect(c.read(todayProvider), DateTime(2020, 1, 1));

      c.read(appLifecycleProvider).refreshToday();

      expect(c.read(todayProvider), dateOnly(DateTime.now()));
    });

    test('gün aynıysa dokunmuyor', () async {
      await seedVehicle();
      final ProviderContainer c = await startSync(day: dateOnly(DateTime.now()));
      final DateTime before = c.read(todayProvider);

      c.read(appLifecycleProvider).refreshToday();

      expect(identical(c.read(todayProvider), before), isTrue);
    });
  });

  // ----------------------------------------------------------- K-27 iptal

  group('K-27: gecikmiş bitince bildirim iptal', () {
    test('gecikmiş kaydedilince iptal ediliyor', () async {
      final int v = await seedVehicle();
      final int oil = await itemId(v, 'oil_level');
      await db.itemDao.setLastDone(oil, day: '2026-08-01', km: null);
      final ProviderContainer c = await startSync();
      expect(bridge.cancelCalls, 0, reason: 'açılışta iptal edilmemeli');

      await c.read(logRepoProvider).add(
        itemId: oil,
        doneAt: DateTime(2026, 9, 3, 10),
        doneDay: '2026-09-03',
        km: 118420,
        value: 'Orta',
      );
      await settle();

      expect(bridge.cancelCalls, 1);
    });

    test('hiç gecikmiş yokken açılışta iptal etmiyor', () async {
      await seedVehicle();
      final ProviderContainer c = await startSync();
      await c.read(appLifecycleProvider).onResume();
      await settle();

      expect(bridge.cancelCalls, 0);
    });

    test('gecikmiş sürerken iptal etmiyor', () async {
      final int v = await seedVehicle();
      final int a = await itemId(v, 'oil_level');
      final int b = await itemId(v, 'tire_pressure');
      await db.itemDao.setLastDone(a, day: '2026-08-01', km: null);
      await db.itemDao.setLastDone(b, day: '2026-08-01', km: null);
      final ProviderContainer c = await startSync();

      await c.read(logRepoProvider).add(
        itemId: a,
        doneAt: DateTime(2026, 9, 3, 10),
        doneDay: '2026-09-03',
        km: 118420,
        value: 'Orta',
      );
      await settle();

      // B hâlâ gecikmiş.
      expect(bridge.cancelCalls, 0);
    });

    test('erteleme de motoru susturduğu için iptal ediyor', () async {
      final int v = await seedVehicle();
      final int oil = await itemId(v, 'oil_level');
      await db.itemDao.setLastDone(oil, day: '2026-08-01', km: null);
      final ProviderContainer c = await startSync();

      // K-13: ekranda gecikmiş görünmeye devam eder ama bildirime girmez.
      await c.read(itemListRepoProvider).setSnooze(oil, '2026-09-04');
      await settle();

      expect(bridge.cancelCalls, 1);
    });
  });

  // ------------------------------------------------------- widget üzerinden

  testWidgets('"Yaptım" kaydından sonra snapshot\'ta dueDay ilerledi', (
    WidgetTester tester,
  ) async {
    final int v = await seedVehicle();
    final int air = await itemId(v, 'air_filter');
    // Yalnız bu madde açık kalsın ki listede ilk sırada olsun.
    for (final CheckItemRow r in await db.itemDao.getAll(v)) {
      await db.itemDao.setEnabled(r.id, r.id == air);
    }
    await db.itemDao.setLastDone(air, day: '2026-08-01', km: 100000);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          databaseProvider.overrideWithValue(db),
          seedProvider.overrideWithValue(seed),
          platformBridgeProvider.overrideWithValue(bridge),
          todayProvider.overrideWith((Ref ref) => today),
          installDayProvider.overrideWith((Ref ref) => installDay),
          snapshotDebounceProvider.overrideWithValue(Duration.zero),
        ],
        child: const CarKeepApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 30.000 km'de bir; 100.000'de yapıldı → 130.000.
    expect((await itemById(air))!['dueKm'], 130000);

    await tester.tap(find.byKey(Key('item_$air')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('detail_save')));
    await tester.pumpAndSettle();

    // Bugün 118.420 km'de yapıldı → 148.420.
    expect((await itemById(air))!['dueKm'], 148420);
    expect(find.textContaining(S.savedPrefix), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });
}
