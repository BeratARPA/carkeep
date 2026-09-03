import 'dart:io';

import 'package:carkeep/app.dart';
import 'package:carkeep/core/strings_tr.dart';
import 'package:carkeep/data/db/database.dart';
import 'package:carkeep/data/platform/platform_bridge.dart';
import 'package:carkeep/data/seed/seed_loader.dart';
import 'package:carkeep/features/home/home_screen.dart';
import 'package:carkeep/features/setup/setup_screen.dart';
import 'package:carkeep/providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'setup_test.dart' show FakeBridge;

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

  Future<void> pumpApp(WidgetTester tester) async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bridge = FakeBridge(
      devices: const <BondedDevice>[
        BondedDevice(name: 'Uconnect', address: '12:34:56:78:9A:BC'),
        BondedDevice(name: 'JBL TUNE510BT', address: 'E4:61:F4:0E:12:BA'),
      ],
    );
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          databaseProvider.overrideWithValue(db),
          seedProvider.overrideWithValue(seed),
          platformBridgeProvider.overrideWithValue(bridge),
          todayProvider.overrideWith((Ref ref) => today),
        ],
        child: const CarKeepApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapNext(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('setup_next')));
    await tester.pumpAndSettle();
  }

  /// Drift, sorgu akışı iptal edilince `StreamQueryStore.markAsClosed`
  /// içinde sıfır süreli bir `Timer` kurar. `ProviderScope` test sonunda
  /// dispose olursa bu zamanlayıcı asılı kalır, `flutter_test` "A Timer is
  /// still pending" der ve koşucu kilitlenir. Ağacı test içinde söküp
  /// **süre vererek** bir frame çevirmek gerekiyor (`pump()` süresiz
  /// çağrıldığında sahte saati ilerletmez).
  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  }

  /// Uyarı SnackBar'ı 4 sn'lik bir zamanlayıcı tutar; test bitmeden
  /// süresinin dolmasi gerekiyor.
  Future<void> expectToast(WidgetTester tester, String text) async {
    expect(find.text(text), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  testWidgets('araç yokken kurulum sihirbazı açılıyor', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    expect(find.byType(SetupScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text(S.setupVehicleTitle), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('zorunlu alan boşken uyarı çıkıyor ve adım ilerlemiyor', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await tapNext(tester);
    expect(find.text(S.setupVehicleTitle), findsOneWidget);
    await expectToast(tester, S.errBrandRequired);

    await disposeTree(tester);
  });

  testWidgets('km boşken uyarı çıkıyor', (WidgetTester tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byKey(const Key('setup_brand')), 'Fiat');
    await tapNext(tester);
    expect(find.text(S.setupKmTitle), findsOneWidget);
    await tapNext(tester);
    expect(find.text(S.setupKmTitle), findsOneWidget);
    await expectToast(tester, S.errKmRequired);

    await disposeTree(tester);
  });

  testWidgets('6 adım akışı ve Başla sonrası ana ekran', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    // 1
    expect(find.text(S.setupVehicleTitle), findsOneWidget);
    await tester.enterText(find.byKey(const Key('setup_brand')), 'Fiat');
    await tester.enterText(
      find.byKey(const Key('setup_model')),
      'Egea 1.6 MultiJet',
    );
    await tester.enterText(find.byKey(const Key('setup_year')), '2019');
    await tapNext(tester);

    // 2
    expect(find.text(S.setupKmTitle), findsOneWidget);
    await tester.enterText(find.byKey(const Key('setup_km')), '118420');
    await tapNext(tester);

    // 3 — izinler; reddedilse de ilerlenebiliyor
    expect(find.text(S.setupPermissionsTitle), findsOneWidget);
    expect(find.byKey(const Key('perm_bluetooth')), findsOneWidget);
    expect(find.byKey(const Key('perm_notification')), findsOneWidget);
    expect(find.byKey(const Key('perm_battery')), findsOneWidget);
    await tapNext(tester);

    // 4 — cihaz listesi
    expect(find.text(S.setupDeviceTitle), findsOneWidget);
    expect(find.text('Uconnect'), findsOneWidget);
    expect(find.text('12:34:56:78:9A:BC'), findsOneWidget);
    await tester.tap(find.text('Uconnect'));
    await tester.pumpAndSettle();
    await tapNext(tester);

    // 5 — son servis, boş bırakılıyor
    expect(find.text(S.setupLastServiceTitle), findsOneWidget);
    await tapNext(tester);

    // 6 — kontrol listesi
    expect(find.text(S.setupChecklistTitle), findsOneWidget);
    expect(find.text(S.start), findsOneWidget);
    expect(find.byKey(const Key('checklist_oil_level')), findsOneWidget);

    await tester.tap(find.byKey(const Key('setup_next')));
    await tester.pumpAndSettle();

    // Ana ekran
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(SetupScreen), findsNothing);

    final VehicleRow? vehicle = await db.vehicleDao.get();
    expect(vehicle, isNotNull);
    expect(vehicle!.brand, 'Fiat');
    expect(vehicle.btAddress, '12:34:56:78:9A:BC');
    expect((await db.itemDao.getAll(vehicle.id)).length, 34);

    await disposeTree(tester);
  });

  testWidgets('geri düğmesi 1. adımda yok, sonrasında var', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    expect(find.byKey(const Key('setup_back')), findsNothing);

    await tester.enterText(find.byKey(const Key('setup_brand')), 'Fiat');
    await tapNext(tester);
    expect(find.byKey(const Key('setup_back')), findsOneWidget);

    await tester.tap(find.byKey(const Key('setup_back')));
    await tester.pumpAndSettle();
    expect(find.text(S.setupVehicleTitle), findsOneWidget);
    expect(find.byKey(const Key('setup_back')), findsNothing);

    await disposeTree(tester);
  });

  testWidgets('Bluetooth kapalıyken "cihaz yok" yerine ayrı metin', (
    WidgetTester tester,
  ) async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bridge = FakeBridge(btEnabled: false);
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          databaseProvider.overrideWithValue(db),
          seedProvider.overrideWithValue(seed),
          platformBridgeProvider.overrideWithValue(bridge),
          todayProvider.overrideWith((Ref ref) => today),
        ],
        child: const CarKeepApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('setup_brand')), 'Fiat');
    await tapNext(tester);
    await tester.enterText(find.byKey(const Key('setup_km')), '118420');
    await tapNext(tester);
    await tapNext(tester);

    expect(find.text(S.deviceListBluetoothOff), findsOneWidget);
    expect(find.text(S.deviceListEmpty), findsNothing);

    await disposeTree(tester);
  });

  testWidgets('kurulmuş araç varsa doğrudan ana ekran', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    // Kurulumu tamamla.
    await tester.enterText(find.byKey(const Key('setup_brand')), 'Fiat');
    await tapNext(tester);
    await tester.enterText(find.byKey(const Key('setup_km')), '118420');
    for (int i = 0; i < 5; i++) {
      await tapNext(tester);
    }
    expect(find.byType(HomeScreen), findsOneWidget);

    // Aynı DB ile uygulamayı yeniden kur: doğrudan ana ekran.
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          databaseProvider.overrideWithValue(db),
          seedProvider.overrideWithValue(seed),
          platformBridgeProvider.overrideWithValue(bridge),
          todayProvider.overrideWith((Ref ref) => today),
        ],
        child: const CarKeepApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(SetupScreen), findsNothing);

    await disposeTree(tester);
  });
}
