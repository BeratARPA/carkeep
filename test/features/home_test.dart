import 'dart:io';

import 'package:carkeep/app.dart';
import 'package:carkeep/core/strings_tr.dart';
import 'package:carkeep/core/theme.dart';
import 'package:carkeep/data/db/database.dart';
import 'package:carkeep/data/repositories/item_repo.dart';
import 'package:carkeep/data/seed/seed_loader.dart';
import 'package:carkeep/domain/models/item_status.dart';
import 'package:carkeep/features/history/history_screen.dart';
import 'package:carkeep/features/home/home_controller.dart';
import 'package:carkeep/features/home/home_screen.dart';
import 'package:carkeep/features/home/widgets/item_row.dart';
import 'package:carkeep/features/settings/settings_screen.dart';
import 'package:carkeep/providers.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final DateTime installDay = DateTime(2026, 8, 20);

  /// Kurulmuş bir araç + şablon; sonra istenen maddelerin son yapılışı verilir.
  Future<int> seedVehicle({String? btName = 'Uconnect'}) async {
    final int vehicleId = await db.vehicleDao.insertVehicle(
      VehiclesCompanion.insert(
        brand: 'Fiat',
        model: const Value<String>('Egea 1.6 MultiJet'),
        year: const Value<String>('2019'),
        currentKm: 118420,
        btAddress: Value<String?>(btName == null ? null : '12:34:56:78:9A:BC'),
        btName: Value<String?>(btName),
        createdAt: DateTime(2026, 8, 20),
      ),
    );
    await ItemRepo(db).installSeed(vehicleId, seed);
    return vehicleId;
  }

  /// Listeyi kısaltır: verilenler dışındaki her maddeyi kapatır.
  /// `ListView` tembel olduğu için uzun listede alttaki bölümler ağaca girmiyor.
  Future<void> keepOnly(int vehicleId, Set<String> keys) async {
    for (final CheckItemRow r in await db.itemDao.getAll(vehicleId)) {
      await db.itemDao.setEnabled(r.id, keys.contains(r.templateKey));
    }
  }

  Future<void> setLastDone(
    int vehicleId,
    String templateKey, {
    String? day,
    int? km,
    String? value,
  }) async {
    final CheckItemRow row = (await db.itemDao.getAll(vehicleId)).firstWhere(
      (CheckItemRow r) => r.templateKey == templateKey,
    );
    await db.itemDao.setLastDone(row.id, day: day, km: km, value: value);
  }

  Future<void> pumpHome(
    WidgetTester tester, {
    FakeBridge? withBridge,
    String? launchAction,
  }) async {
    bridge = withBridge ?? FakeBridge(bluetooth: true, notification: true, battery: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          databaseProvider.overrideWithValue(db),
          seedProvider.overrideWithValue(seed),
          platformBridgeProvider.overrideWithValue(bridge),
          todayProvider.overrideWith((Ref ref) => today),
          installDayProvider.overrideWith((Ref ref) => installDay),
          if (launchAction != null)
            launchActionProvider.overrideWith((Ref ref) => launchAction),
        ],
        child: const CarKeepApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Kotlin'in `onLaunchAction` çağrısını taklit eder.
  Future<void> sendLaunchAction(WidgetTester tester, String action) async {
    const StandardMethodCodec codec = StandardMethodCodec();
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      bridge.channel.name,
      codec.encodeMethodCall(MethodCall('onLaunchAction', action)),
      (ByteData? _) {},
    );
    await tester.pumpAndSettle();
  }

  /// Drift, akış iptalinde sıfır süreli bir Timer kurar; ağacı sökerken
  /// süre vererek bir frame çevirmek gerekiyor (bkz. ILERLEME T06 notu).
  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
  });

  // ------------------------------------------------------------- bölümler

  testWidgets('bölüm sayıları ve boş bölümün gizlenmesi', (
    WidgetTester tester,
  ) async {
    final int v = await seedVehicle();
    await keepOnly(v, <String>{
      'oil_level',
      'coolant_level',
      'washer_fluid',
      'air_filter',
    });
    // oil_level → gecikmiş, coolant_level → yaklaşan (vade 2026-09-04),
    // washer_fluid → zamanında (kurulumdan 30 gün), air_filter → bilinmiyor.
    await setLastDone(v, 'oil_level', day: '2026-08-12', value: 'Orta');
    await setLastDone(v, 'coolant_level', day: '2026-08-05', value: 'Orta');

    await pumpHome(tester);

    expect(find.byKey(const Key('section_overdue')), findsOneWidget);
    expect(find.byKey(const Key('section_soon')), findsOneWidget);
    expect(find.byKey(const Key('section_ok')), findsOneWidget);
    expect(find.byKey(const Key('section_unknown')), findsOneWidget);

    expect(find.text('${S.sectionOverdue} (1)'), findsOneWidget);
    expect(find.text('${S.sectionSoon} (1)'), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('hepsi zamanındaysa gecikmiş ve yaklaşan bölümü yok', (
    WidgetTester tester,
  ) async {
    final int v = await seedVehicle();
    // Kurulumdan 14 gün geçtiği için 14 günlük maddeler bugün vadeli
    // ("Bugün", yaklaşan); onları kapatıp yalnız 30 günlükleri bırakıyoruz.
    await keepOnly(v, <String>{'washer_fluid', 'lights_horn'});
    await pumpHome(tester);

    expect(find.byKey(const Key('section_overdue')), findsNothing);
    expect(find.byKey(const Key('section_soon')), findsNothing);
    expect(find.byKey(const Key('home_all_good')), findsOneWidget);
    expect(find.text(S.homeAllGood), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('kapalı madde listede görünmüyor', (WidgetTester tester) async {
    final int v = await seedVehicle();
    // `kasko` varsayılan kapalı; `insurance` açık. İkisi de unknown.
    await keepOnly(v, <String>{'insurance'});
    await pumpHome(tester);

    expect(find.text('Trafik sigortası yenileme'), findsOneWidget);
    expect(find.text('Kasko yenileme'), findsNothing);

    // Açınca görünür.
    final CheckItemRow kasko = (await db.itemDao.getAll(v)).firstWhere(
      (CheckItemRow r) => r.templateKey == 'kasko',
    );
    await db.itemDao.setEnabled(kasko.id, true);
    await tester.pumpAndSettle();
    expect(find.text('Kasko yenileme'), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('gecikmiş sıralaması: en çok gecikmiş önce', (
    WidgetTester tester,
  ) async {
    final int v = await seedVehicle();
    await keepOnly(v, <String>{'oil_level', 'coolant_level'});
    // oil_level 14 gün: 2026-08-12 → vade 2026-08-26, −8 gün, oran −0,571
    await setLastDone(v, 'oil_level', day: '2026-08-12');
    // coolant_level 30 gün: 2026-07-20 → vade 2026-08-19, −15 gün, oran −0,5
    await setLastDone(v, 'coolant_level', day: '2026-07-20');

    await pumpHome(tester);

    final List<Element> rows = find
        .byType(ItemRow)
        .evaluate()
        .toList(growable: false);
    final ItemRow first = rows.first.widget as ItemRow;
    final ItemRow second = rows[1].widget as ItemRow;
    expect(first.entry.item.templateKey, 'oil_level');
    expect(second.entry.item.templateKey, 'coolant_level');
    expect(first.entry.status.state, ItemState.overdue);
    await disposeTree(tester);
  });

  // ----------------------------------------------------------------- satır

  testWidgets('satır alt metni ve durum metni', (WidgetTester tester) async {
    final int v = await seedVehicle();
    await keepOnly(v, <String>{'oil_level', 'air_filter', 'insurance'});
    await setLastDone(v, 'oil_level', day: '2026-08-12', value: 'Orta');
    await setLastDone(v, 'air_filter', km: 100000, day: '2026-03-12');

    await pumpHome(tester);

    // days maddesi: `Son: 12 Ağu, Orta`
    expect(find.text('Son: 12 Ağu, Orta'), findsOneWidget);
    expect(find.text('8 gün gecikti'), findsOneWidget);

    // km maddesi: `Son: 100.000 km, 12 Mar`
    expect(find.text('Son: 100.000 km, 12 Mar'), findsOneWidget);
    expect(find.text('11.580 km kaldı'), findsOneWidget);

    // Son yapılışı olmayan madde (K-18)
    expect(find.text(S.lastDoneMissing), findsWidgets);
    expect(find.text(S.enterDate), findsWidgets);
    await disposeTree(tester);
  });

  testWidgets('gecikmiş satırda sol kırmızı çizgi, diğerlerinde yok', (
    WidgetTester tester,
  ) async {
    final int v = await seedVehicle();
    await keepOnly(v, <String>{'oil_level', 'tire_pressure'});
    await setLastDone(v, 'oil_level', day: '2026-08-12');
    await pumpHome(tester);

    BorderSide leftOf(String templateKey) {
      final ItemRow row =
          tester
                  .widgetList<ItemRow>(find.byType(ItemRow))
                  .firstWhere(
                    (ItemRow r) => r.entry.item.templateKey == templateKey,
                  );
      final Container container = tester.widget<Container>(
        find.descendant(
          of: find.byKey(Key('item_${row.entry.item.id}')),
          matching: find.byType(Container),
        ),
      );
      return ((container.decoration! as BoxDecoration).border! as Border).left;
    }

    expect(leftOf('oil_level').color, AppColors.red);
    expect(leftOf('tire_pressure').color, Colors.transparent);
    await disposeTree(tester);
  });

  testWidgets('durum metni renkleri', (WidgetTester tester) async {
    expect(statusColor(ItemState.overdue), AppColors.red);
    expect(statusColor(ItemState.soon), AppColors.amber);
    expect(statusColor(ItemState.ok), AppColors.ink3);
    expect(statusColor(ItemState.unknown), AppColors.ink3);
  });

  // --------------------------------------------------------------- başlık

  testWidgets('km başlığı ve Bluetooth chip metni', (
    WidgetTester tester,
  ) async {
    await seedVehicle();
    await pumpHome(tester);

    expect(find.text('118.420 km'), findsOneWidget);
    expect(find.text('Fiat Egea 1.6 MultiJet, 2019'), findsOneWidget);
    expect(find.text(S.kmEntryLink), findsOneWidget);
    expect(find.text('Uconnect bağlı değil'), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('chip metinleri', (WidgetTester tester) async {
    expect(
      bluetoothChipText(deviceName: 'Uconnect', connected: false),
      'Uconnect bağlı değil',
    );
    expect(
      bluetoothChipText(deviceName: 'Uconnect', connected: true),
      'Uconnect bağlı, sürüşte',
    );
    expect(
      bluetoothChipText(deviceName: null, connected: false),
      S.chipNoDevice,
    );
  });

  // ------------------------------------------------------- uyarı şeritleri

  testWidgets('izinler tamsa şerit yok', (WidgetTester tester) async {
    final int v = await seedVehicle();
    await keepOnly(v, <String>{'oil_level'});
    await pumpHome(tester);
    expect(find.byKey(const Key('banner_noBluetooth')), findsNothing);
    expect(find.byKey(const Key('banner_noNotification')), findsNothing);
    expect(find.byKey(const Key('banner_noDevice')), findsNothing);
    expect(find.byKey(const Key('banner_battery')), findsNothing);
    await disposeTree(tester);
  });

  testWidgets('eksik izinler ve cihaz için şerit çıkıyor', (
    WidgetTester tester,
  ) async {
    await seedVehicle(btName: null);
    await pumpHome(
      tester,
      withBridge: FakeBridge(),
    );

    expect(find.byKey(const Key('banner_noBluetooth')), findsOneWidget);
    expect(find.byKey(const Key('banner_noNotification')), findsOneWidget);
    expect(find.byKey(const Key('banner_noDevice')), findsOneWidget);
    expect(find.byKey(const Key('banner_battery')), findsOneWidget);
    expect(find.text(S.bannerNoBluetooth), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('Bluetooth şeridine dokunmak izin istiyor', (
    WidgetTester tester,
  ) async {
    await seedVehicle();
    await pumpHome(tester, withBridge: FakeBridge(notification: true, battery: true));

    expect(find.byKey(const Key('banner_noBluetooth')), findsOneWidget);
    await tester.tap(find.byKey(const Key('banner_noBluetooth')));
    await tester.pumpAndSettle();

    expect(bridge.bluetooth, isTrue);
    expect(find.byKey(const Key('banner_noBluetooth')), findsNothing);
    await disposeTree(tester);
  });

  testWidgets('pil şeridi dokununca sistem ekranını açıyor', (
    WidgetTester tester,
  ) async {
    await seedVehicle();
    await pumpHome(
      tester,
      withBridge: FakeBridge(bluetooth: true, notification: true),
    );
    await tester.tap(find.byKey(const Key('banner_battery')));
    await tester.pumpAndSettle();
    expect(bridge.battery, isTrue);
    await disposeTree(tester);
  });

  testWidgets('yalnız pil şeridi kapatılabiliyor ve kalıcı', (
    WidgetTester tester,
  ) async {
    await seedVehicle();
    await pumpHome(
      tester,
      withBridge: FakeBridge(bluetooth: true, notification: true),
    );

    expect(find.byKey(const Key('banner_battery')), findsOneWidget);
    await tester.tap(find.byKey(const Key('banner_dismiss')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('banner_battery')), findsNothing);

    expect(
      await db.settingsDao.get('battery_banner_dismissed'),
      '1',
    );
    await disposeTree(tester);
  });

  testWidgets('araba seçilmedi şeridi Ayarlar sekmesine götürüyor', (
    WidgetTester tester,
  ) async {
    await seedVehicle(btName: null);
    await pumpHome(tester);

    await tester.tap(find.byKey(const Key('banner_noDevice')));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    await disposeTree(tester);
  });

  // --------------------------------------------------------------- gezinme

  testWidgets('alt gezinme üç sekme ve IndexedStack', (
    WidgetTester tester,
  ) async {
    await seedVehicle();
    await pumpHome(tester);

    expect(find.byKey(const Key('bottom_nav')), findsOneWidget);
    expect(find.byType(IndexedStack), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.text(S.tabHistory));
    await tester.pumpAndSettle();
    expect(find.byType(HistoryScreen), findsOneWidget);

    await tester.tap(find.text(S.tabSettings));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tester.tap(find.text(S.tabHome));
    await tester.pumpAndSettle();
    expect(find.text('118.420 km'), findsOneWidget);
    await disposeTree(tester);
  });

  // --------------------------------------------------------------- vurgu

  testWidgets('bildirimden gelindiğinde gecikmiş bölümü vurgulanıyor', (
    WidgetTester tester,
  ) async {
    final int v = await seedVehicle();
    await keepOnly(v, <String>{'oil_level'});
    await setLastDone(v, 'oil_level', day: '2026-08-12');
    await pumpHome(tester, launchAction: 'overdue');

    // Anahtar sayaçlı: aynı eylem ikinci kez gelince vurgu tekrar oynasın.
    expect(find.byKey(const Key('overdue_highlight_0')), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('uygulama açıkken bildirime dokununca sekme değişip vurgulanıyor', (
    WidgetTester tester,
  ) async {
    // Cihaz testi bulgusu: Kotlin `onLaunchAction` gönderiyordu ama Dart
    // tarafında dinleyen yoktu; uygulama açıkken sekme değişmiyordu.
    final int v = await seedVehicle();
    await keepOnly(v, <String>{'oil_level'});
    await setLastDone(v, 'oil_level', day: '2026-08-12');
    await pumpHome(tester);

    // Başka sekmedeyken bildirime dokunuluyor.
    await tester.tap(find.text(S.tabSettings));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('overdue_highlight_0')), findsNothing);

    await sendLaunchAction(tester, 'overdue');

    expect(find.byKey(const Key('overdue_highlight_1')), findsOneWidget);

    // İkinci dokunuş yeni anahtarla yeni animasyon başlatıyor.
    await sendLaunchAction(tester, 'overdue');
    expect(find.byKey(const Key('overdue_highlight_2')), findsOneWidget);
    expect(find.byKey(const Key('overdue_highlight_1')), findsNothing);

    await disposeTree(tester);
  });

  testWidgets('normal açılışta vurgu yok', (WidgetTester tester) async {
    final int v = await seedVehicle();
    await keepOnly(v, <String>{'oil_level'});
    await setLastDone(v, 'oil_level', day: '2026-08-12');
    await pumpHome(tester);

    expect(find.byKey(const Key('overdue_highlight_0')), findsNothing);
    await disposeTree(tester);
  });

  // ------------------------------------------------------------ yardımcılar

  test('sectionTitle', () {
    expect(sectionTitle(ItemState.overdue, 2), 'Gecikmiş (2)');
    expect(sectionTitle(ItemState.soon, 0), 'Yaklaşan (0)');
    expect(sectionTitle(ItemState.ok, 16), 'Zamanında (16)');
    expect(sectionTitle(ItemState.unknown, 13), 'Bilinmiyor (13)');
  });

  test('bannerText ve bannerDismissible', () {
    expect(bannerText(HomeBanner.noBluetooth), S.bannerNoBluetooth);
    expect(bannerText(HomeBanner.noNotification), S.bannerNoNotification);
    expect(bannerText(HomeBanner.noDevice), S.bannerNoDevice);
    expect(bannerText(HomeBanner.battery), S.bannerBattery);

    expect(bannerDismissible(HomeBanner.battery), isTrue);
    expect(bannerDismissible(HomeBanner.noBluetooth), isFalse);
    expect(bannerDismissible(HomeBanner.noNotification), isFalse);
    expect(bannerDismissible(HomeBanner.noDevice), isFalse);
  });
}
