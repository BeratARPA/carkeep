import 'dart:convert';
import 'dart:io';

import 'package:carkeep/app.dart';
import 'package:carkeep/core/constants.dart';
import 'package:carkeep/core/strings_tr.dart';
import 'package:carkeep/data/db/daos/settings_dao.dart';
import 'package:carkeep/data/db/database.dart';
import 'package:carkeep/data/platform/platform_bridge.dart';
import 'package:carkeep/data/repositories/item_repo.dart';
import 'package:carkeep/data/repositories/trip_repo.dart';
import 'package:carkeep/data/seed/seed_loader.dart';
import 'package:carkeep/domain/models/trip.dart';
import 'package:carkeep/lifecycle.dart';
import 'package:carkeep/providers.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'setup_test.dart' show FakeBridge;

/// T13: `drainPendingEvents` → `trips`/`settings`, açılış ve `resume`.
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

  Future<void> seedVehicle() async {
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
  }

  /// Kotlin'in yazdığı biçim (02-mimari §6).
  String tripJson({
    int durationMin = 25,
    bool counted = true,
    bool notified = true,
    String note = kTripNoteOk,
    int hour = 14,
  }) => jsonEncode(<String, Object?>{
    'type': 'trip',
    'connectedAt': DateTime(2026, 9, 3, hour, 5).millisecondsSinceEpoch,
    'disconnectedAt': DateTime(2026, 9, 3, hour, 30).millisecondsSinceEpoch,
    'durationMin': durationMin,
    'counted': counted,
    'notified': notified,
    'overdueCount': 1,
    'note': note,
  });

  ProviderContainer makeContainer() {
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        seedProvider.overrideWithValue(seed),
        platformBridgeProvider.overrideWithValue(bridge),
        todayProvider.overrideWith((Ref ref) => today),
        installDayProvider.overrideWith((Ref ref) => installDay),
        snapshotDebounceProvider.overrideWithValue(Duration.zero),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  // -------------------------------------------------------------- drain

  group('drainPendingEvents', () {
    test('sürüş olayları trips tablosuna işleniyor', () async {
      await seedVehicle();
      bridge.pendingEventsJson = '[${tripJson()}]';
      final ProviderContainer c = makeContainer();

      expect(await c.read(appLifecycleProvider).drainPendingEvents(), 1);

      final Trip row = (await TripRepo(db).getAll()).single;
      expect(row.durationMin, 25);
      expect(row.notified, isTrue);
      expect(row.note, kTripNoteOk);
      // Kotlin tarafındaki dizi boşaldı (oku + sil tek çağrı).
      expect(bridge.pendingEventsJson, '[]');
    });

    test('ikinci drain tekrar eklemiyor', () async {
      await seedVehicle();
      bridge.pendingEventsJson = '[${tripJson()}]';
      final ProviderContainer c = makeContainer();
      final AppLifecycle lifecycle = c.read(appLifecycleProvider);

      await lifecycle.drainPendingEvents();
      expect(await lifecycle.drainPendingEvents(), 0);

      expect((await TripRepo(db).getAll()).length, 1);
      expect(bridge.drainCalls, 2);
    });

    test('erteleme olayı ayarlara işleniyor', () async {
      await seedVehicle();
      bridge.pendingEventsJson = jsonEncode(<Map<String, Object?>>[
        <String, Object?>{'type': 'snooze', 'untilDay': '2026-09-04'},
      ]);
      final ProviderContainer c = makeContainer();

      await c.read(appLifecycleProvider).drainPendingEvents();

      expect(
        await db.settingsDao.get(SettingKeys.globalSnoozeUntilDay),
        '2026-09-04',
      );
    });

    test('bozuk JSON sessiz geçiyor', () async {
      await seedVehicle();
      bridge.pendingEventsJson = 'bu JSON değil';
      final ProviderContainer c = makeContainer();

      expect(await c.read(appLifecycleProvider).drainPendingEvents(), 0);
      expect(await TripRepo(db).getAll(), isEmpty);
    });

    test('kanal yoksa sessiz geçiyor', () async {
      await seedVehicle();
      // Gerçek kanalı olan köprü: `MissingPluginException`.
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          databaseProvider.overrideWithValue(db),
          seedProvider.overrideWithValue(seed),
          todayProvider.overrideWith((Ref ref) => today),
          installDayProvider.overrideWith((Ref ref) => installDay),
        ],
      );
      addTearDown(c.dispose);

      expect(await c.read(appLifecycleProvider).drainPendingEvents(), 0);
    });
  });

  group('readLaunchAction', () {
    test('bildirimden açıldıysa provider besleniyor', () async {
      await seedVehicle();
      bridge.launchAction = kLaunchActionOverdue;
      final ProviderContainer c = makeContainer();

      await c.read(appLifecycleProvider).readLaunchAction();

      expect(c.read(launchActionProvider), kLaunchActionOverdue);
      expect(c.read(launchActionSeqProvider), 1);
      // Kotlin okununca temizler; ikinci okuma tekrar tetiklemez.
      await c.read(appLifecycleProvider).readLaunchAction();
      expect(c.read(launchActionSeqProvider), 1);
    });

    test('normal açılışta dokunmuyor', () async {
      await seedVehicle();
      final ProviderContainer c = makeContainer();

      await c.read(appLifecycleProvider).readLaunchAction();

      expect(c.read(launchActionProvider), isNull);
      expect(c.read(launchActionSeqProvider), 0);
    });
  });

  // ------------------------------------------------------------- resume

  Future<void> pumpApp(WidgetTester tester) async {
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
  }

  Future<void> resume(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    // `onResume` async; işlerin bitmesi için bir tur daha.
    await tester.pumpAndSettle();
  }

  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  }

  testWidgets('resume drain ediyor, tanı satırı DB\'den güncelleniyor', (
    WidgetTester tester,
  ) async {
    await seedVehicle();
    await pumpApp(tester);

    await tester.tap(find.text(S.tabSettings));
    await tester.pumpAndSettle();
    expect(find.text(S.lastTripNone), findsOneWidget);

    // Kullanıcı arabadan indi: Kotlin olayı biriktirdi.
    bridge.pendingEventsJson =
        '[${tripJson(note: kTripNoteOncePerDay, notified: false, hour: 18)}]';
    await resume(tester);

    expect(
      find.text('Son kopma: 3 Eyl 18:30, 25 dk sürüş, bugün zaten hatırlatıldı'),
      findsOneWidget,
    );
    expect((await TripRepo(db).getAll()).length, 1);

    // İkinci resume aynı kaydı tekrar eklemiyor.
    await resume(tester);
    expect((await TripRepo(db).getAll()).length, 1);

    await disposeTree(tester);
  });

  testWidgets('resume Bluetooth durumunu tazeliyor, chip sürüşte diyor', (
    WidgetTester tester,
  ) async {
    await seedVehicle();
    await pumpApp(tester);
    expect(find.text('Uconnect ${S.chipDisconnectedSuffix}'), findsOneWidget);

    // "Bağlanmayı simüle et" sonrası motor bağlı diyor.
    bridge.btState = BluetoothState(
      connected: true,
      since: DateTime(2026, 9, 3, 14, 5),
      lastTrip: null,
    );
    await resume(tester);

    expect(find.text('Uconnect ${S.chipConnectedSuffix}'), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('resume izinleri tazeliyor, şerit kayboluyor', (
    WidgetTester tester,
  ) async {
    await seedVehicle();
    bridge
      ..bluetooth = false
      ..notification = false;
    await pumpApp(tester);
    expect(find.byKey(const Key('banner_noBluetooth')), findsOneWidget);

    bridge
      ..bluetooth = true
      ..notification = true;
    await resume(tester);

    expect(find.byKey(const Key('banner_noBluetooth')), findsNothing);
    expect(find.byKey(const Key('banner_noNotification')), findsNothing);
    await disposeTree(tester);
  });

  testWidgets('resume\'da bildirim eylemi gelirse gecikmiş vurgulanıyor', (
    WidgetTester tester,
  ) async {
    await seedVehicle();
    // Vurgulanacak bir Gecikmiş bölümü olsun.
    await db.itemDao.setLastDone(1, day: '2026-08-12', km: null);
    await pumpApp(tester);
    expect(find.byKey(const Key('section_overdue')), findsOneWidget);
    expect(find.byKey(const Key('overdue_highlight_0')), findsNothing);

    bridge.launchAction = kLaunchActionOverdue;
    await resume(tester);

    expect(find.byKey(const Key('overdue_highlight_1')), findsOneWidget);
    await disposeTree(tester);
  });
}
