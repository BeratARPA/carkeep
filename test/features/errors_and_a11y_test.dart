import 'dart:io';

import 'package:carkeep/app.dart';
import 'package:carkeep/core/strings_tr.dart';
import 'package:carkeep/core/theme.dart';
import 'package:carkeep/data/db/daos/settings_dao.dart';
import 'package:carkeep/data/db/database.dart';
import 'package:carkeep/data/repositories/item_repo.dart';
import 'package:carkeep/data/seed/seed_loader.dart';
import 'package:carkeep/main.dart';
import 'package:carkeep/providers.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_fonts.dart';
import 'setup_test.dart' show FakeBridge;

/// T16: 01-spec §9 hata/boş durumlar ve erişilebilirlik.
void main() {
  late Seed seed;

  setUpAll(() async {
    // Taşma ölçümü doğru olsun diye gerçek font yüklenir.
    await loadAppFonts();
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
        // Gerçek cihaz adı 25 karakter; kısa adla taşma testleri yalan söylüyordu.
        btName: const Value<String?>('Uconnect NM000000000N00000'),
        btAddress: const Value<String?>('12:34:56:78:9A:BC'),
        createdAt: DateTime(2026, 8, 20),
      ),
    );
    await ItemRepo(db).installSeed(id, seed);
    return id;
  }

  /// Varsayılan test yüzeyi 800x600 dp; gerçek telefon 411 dp geniş.
  /// Taşma testleri geniş yüzeyde yalan söylüyordu (cihazda taşan chip
  /// testte geçiyordu).
  void usePhoneSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pumpApp(WidgetTester tester, {double? textScale}) async {
    if (textScale != null) {
      // `MaterialApp` kendi `MediaQuery`sini pencereden kurar; ağacı
      // `MediaQuery` ile sarmak ölçeği geçirmiyor, platform değeri geçiyor.
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }
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

  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  }

  // ------------------------------------------------ 01-spec §9 hata durumları

  group('bildirim kanalı kapalı (07 §8)', () {
    testWidgets('izin verili ama kanal kapalıysa şerit çıkıyor', (
      WidgetTester tester,
    ) async {
      await seedVehicle();
      bridge.notificationsEnabled = false;
      await pumpApp(tester);

      expect(find.byKey(const Key('banner_notificationsOff')), findsOneWidget);
      expect(find.text(S.bannerNotificationsOff), findsOneWidget);
      // İzin verili olduğu için "izin yok" şeridi çıkmamalı.
      expect(find.byKey(const Key('banner_noNotification')), findsNothing);

      await disposeTree(tester);
    });

    testWidgets('şeride dokununca bildirim ayarları açılıyor', (
      WidgetTester tester,
    ) async {
      await seedVehicle();
      bridge.notificationsEnabled = false;
      await pumpApp(tester);

      await tester.tap(find.byKey(const Key('banner_notificationsOff')));
      await tester.pumpAndSettle();

      expect(bridge.openNotificationSettingsCalls, 1);
      await disposeTree(tester);
    });

    testWidgets('kanal açıkken şerit yok', (WidgetTester tester) async {
      await seedVehicle();
      await pumpApp(tester);
      expect(find.byKey(const Key('banner_notificationsOff')), findsNothing);
      await disposeTree(tester);
    });
  });

  group('kalıcı izin reddi (01-spec §9)', () {
    testWidgets('sorulmadan önce kalıcı ret gösterilmiyor', (
      WidgetTester tester,
    ) async {
      await seedVehicle();
      bridge
        ..bluetooth = false
        ..rationale = false;
      await pumpApp(tester);
      await tester.tap(find.text(S.tabSettings));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_perm_bluetooth')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // `asked` işareti yok: ilk açılışta sistem de false döner.
      expect(find.byKey(const Key('perm_blocked')), findsNothing);
      await disposeTree(tester);
    });

    testWidgets('soruldu + reddedildi + gerekçe yok → ayarlara yönlendirir', (
      WidgetTester tester,
    ) async {
      await seedVehicle();
      await db.settingsDao.setBool(SettingKeys.askedBluetooth, true);
      bridge
        ..bluetooth = false
        ..rationale = false;
      await pumpApp(tester);
      await tester.tap(find.text(S.tabSettings));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_perm_bluetooth')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text(S.permDeniedPermanently), findsOneWidget);
      expect(find.text(S.openSettings), findsWidgets);

      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('settings_perm_bluetooth')),
          matching: find.byType(OutlinedButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(bridge.openAppSettingsCalls, 1);
      await disposeTree(tester);
    });

    testWidgets('gerekçe gösterilecekse normal izin akışı', (
      WidgetTester tester,
    ) async {
      await seedVehicle();
      await db.settingsDao.setBool(SettingKeys.askedBluetooth, true);
      bridge
        ..bluetooth = false
        ..rationale = true;
      await pumpApp(tester);
      await tester.tap(find.text(S.tabSettings));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_perm_bluetooth')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('perm_blocked')), findsNothing);
      await disposeTree(tester);
    });

    testWidgets('izin isteyince "soruldu" işareti yazılıyor', (
      WidgetTester tester,
    ) async {
      await seedVehicle();
      bridge.bluetooth = false;
      await pumpApp(tester);

      await tester.tap(find.byKey(const Key('banner_noBluetooth')));
      await tester.pumpAndSettle();

      expect(
        await db.settingsDao.getBool(SettingKeys.askedBluetooth),
        isTrue,
      );
      await disposeTree(tester);
    });
  });

  group('açılış hatası (01-spec §9)', () {
    testWidgets('DB açılamadıysa sıfırlama sunuluyor', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        StartupErrorApp(
          message: S.errDbOpen,
          canReset: true,
          bridge: bridge,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(S.errDbOpen), findsOneWidget);
      await tester.tap(find.byKey(const Key('startup_reset')));
      await tester.pumpAndSettle();

      // Onay isteniyor; iptal edilirse silinmiyor.
      expect(find.text(S.settingsResetConfirm), findsOneWidget);
      await tester.tap(find.byKey(const Key('startup_reset_cancel')));
      await tester.pumpAndSettle();
      expect(bridge.deleteDatabaseCalls, 0);

      await tester.tap(find.byKey(const Key('startup_reset')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('startup_reset_confirm')));
      await tester.pumpAndSettle();

      expect(bridge.deleteDatabaseCalls, 1);
      expect(find.text(S.errDbResetDone), findsOneWidget);
      expect(find.byKey(const Key('startup_reset')), findsNothing);
    });

    testWidgets('şablon bozuksa sıfırlama sunulmuyor', (
      WidgetTester tester,
    ) async {
      // Geliştirici hatası; veriyi silmek çözmez.
      await tester.pumpWidget(
        StartupErrorApp(message: S.errSeedLoad, bridge: bridge),
      );
      await tester.pumpAndSettle();

      expect(find.text(S.errSeedLoad), findsOneWidget);
      expect(find.byKey(const Key('startup_reset')), findsNothing);
    });
  });

  // ------------------------------------------------------- erişilebilirlik

  group('erişilebilirlik', () {
    Future<void> visitTabs(WidgetTester tester) async {
      for (final String tab in <String>[
        S.tabHistory,
        S.tabSettings,
        S.tabHome,
      ]) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '$tab sekmesinde taşma var',
        );
      }
    }

    testWidgets('yazı ölçeği 1.3\'te taşma yok', (WidgetTester tester) async {
      usePhoneSurface(tester);
      await seedVehicle();
      await pumpApp(tester, textScale: 1.3);
      expect(tester.takeException(), isNull);
      await visitTabs(tester);
      await disposeTree(tester);
    });

    testWidgets('yazı ölçeği 1.0\'da taşma yok', (WidgetTester tester) async {
      usePhoneSurface(tester);
      await seedVehicle();
      await pumpApp(tester);
      expect(tester.takeException(), isNull);
      await visitTabs(tester);
      await disposeTree(tester);
    });

    testWidgets('dokunma alanları en az 48 dp', (WidgetTester tester) async {
      usePhoneSurface(tester);
      await seedVehicle();
      await pumpApp(tester);

      final List<String> small = <String>[];
      for (final Element e in find.byType(InkWell).evaluate()) {
        final Size size = tester.getSize(find.byElementPredicate(
          (Element candidate) => identical(candidate, e),
        ));
        if (size.height > 0 && size.height < AppSizes.minTapTarget) {
          small.add('${size.height.toStringAsFixed(1)} dp');
        }
      }

      // Döngü boş kalmasın: ekranda gerçekten dokunulabilir şeyler var.
      expect(find.byType(InkWell), findsWidgets);
      expect(small, isEmpty, reason: '48 dp altı dokunma alanı: $small');
      await disposeTree(tester);
    });

    testWidgets('simge düğmelerinin etiketi var', (WidgetTester tester) async {
      await seedVehicle();
      await pumpApp(tester);
      await tester.tap(find.text(S.tabSettings));
      await tester.pumpAndSettle();

      // Aralık adımlayıcıları yalnız simge; ekran okuyucu için tooltip şart.
      final Iterable<IconButton> buttons =
          tester.widgetList<IconButton>(find.byType(IconButton));
      expect(buttons, isNotEmpty);
      for (final IconButton b in buttons) {
        expect(b.tooltip, isNotNull, reason: 'etiketsiz simge düğmesi');
        expect(b.tooltip, isNotEmpty);
      }
      await disposeTree(tester);
    });
  });

  // ------------------------------------------------ K-28: doğrulama notu

  group('K-28: şablon aralığı doğrulanmamış maddeler', () {
    testWidgets('kaynak notu detayda görünüyor', (WidgetTester tester) async {
      final int v = await seedVehicle();
      // `air_filter` şablonda `verified: partial` ve kaynak notu var.
      final CheckItemRow air = (await db.itemDao.getAll(v)).firstWhere(
        (CheckItemRow r) => r.templateKey == 'air_filter',
      );
      expect(air.verified, 'partial');
      expect(air.sourceNote, isNotNull);
      for (final CheckItemRow r in await db.itemDao.getAll(v)) {
        await db.itemDao.setEnabled(r.id, r.id == air.id);
      }
      await pumpApp(tester);

      await tester.tap(find.byKey(Key('item_${air.id}')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('detail_verify')), findsOneWidget);
      expect(find.textContaining(S.detailVerifyPrefix), findsOneWidget);
      expect(find.textContaining(air.sourceNote!), findsOneWidget);
      await disposeTree(tester);
    });

    testWidgets('doğrulanmış maddede not satırı yok', (
      WidgetTester tester,
    ) async {
      final int v = await seedVehicle();
      final CheckItemRow oil = (await db.itemDao.getAll(v)).firstWhere(
        (CheckItemRow r) => r.templateKey == 'oil_level',
      );
      expect(oil.verified, 'true');
      for (final CheckItemRow r in await db.itemDao.getAll(v)) {
        await db.itemDao.setEnabled(r.id, r.id == oil.id);
      }
      await pumpApp(tester);

      await tester.tap(find.byKey(Key('item_${oil.id}')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('detail_verify')), findsNothing);
      await disposeTree(tester);
    });
  });
}
