import 'dart:convert';
import 'dart:io';

import 'package:carkeep/app.dart';
import 'package:carkeep/core/constants.dart';
import 'package:carkeep/core/strings_tr.dart';
import 'package:carkeep/data/db/database.dart';
import 'package:carkeep/data/db/daos/settings_dao.dart';
import 'package:carkeep/data/platform/platform_bridge.dart';
import 'package:carkeep/data/repositories/item_repo.dart';
import 'package:carkeep/data/repositories/trip_repo.dart';
import 'package:carkeep/data/seed/seed_loader.dart';
import 'package:carkeep/domain/models/measure.dart';
import 'package:carkeep/domain/models/rules.dart';
import 'package:carkeep/domain/models/schedule.dart';
import 'package:carkeep/domain/models/trip.dart';
import 'package:carkeep/domain/models/vehicle.dart';
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
        year: const Value<String>('2019'),
        currentKm: 118420,
        btName: const Value<String?>('Uconnect'),
        btAddress: const Value<String?>('12:34:56:78:9A:BC'),
        createdAt: DateTime(2026, 8, 20),
      ),
    );
    await ItemRepo(db).installSeed(id, seed);
    return id;
  }

  Future<int> insertTrip({
    required DateTime disconnectedAt,
    required int durationMin,
    required bool counted,
    required bool notified,
    String? note,
    int overdueCount = 1,
  }) => db.tripDao.insertTrip(
    TripsCompanion.insert(
      connectedAt: Value<DateTime?>(
        disconnectedAt.subtract(Duration(minutes: durationMin)),
      ),
      disconnectedAt: disconnectedAt,
      durationMin: durationMin,
      counted: counted,
      notified: notified,
      overdueCount: Value<int>(overdueCount),
      note: Value<String?>(note),
    ),
  );

  Future<CheckItemRow> item(int vehicleId, String templateKey) async =>
      (await db.itemDao.getAll(vehicleId))
          .firstWhere((CheckItemRow r) => r.templateKey == templateKey);

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          databaseProvider.overrideWithValue(db),
          seedProvider.overrideWithValue(seed),
          platformBridgeProvider.overrideWithValue(bridge),
          todayProvider.overrideWith((Ref ref) => today),
          installDayProvider.overrideWith((Ref ref) => installDay),
          // Snapshot yazımı testte anında olsun (bekleyen Timer bırakmaz).
          snapshotDebounceProvider.overrideWithValue(Duration.zero),
        ],
        child: const CarKeepApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.tabSettings));
    await tester.pumpAndSettle();
  }

  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  }

  Future<void> flushToast(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  /// Adımlayıcı düğmesi etkin mi (anahtar sarmalayıcıda olabilir).
  bool stepEnabled(WidgetTester tester, Key key) {
    final Finder button = find.descendant(
      of: find.byKey(key),
      matching: find.byType(IconButton),
    );
    final Finder target = button.evaluate().isEmpty
        ? find.byKey(key)
        : button;
    return tester.widget<IconButton>(target).onPressed != null;
  }

  /// Uzun listede hedefi görünür yap.
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  // ------------------------------------------------------------ saf metin

  group('metin yardımcıları', () {
    test('araç profili boş alanları atlıyor', () {
      Vehicle v(String model, String year) => Vehicle(
        id: 1,
        brand: 'Fiat',
        model: model,
        year: year,
        currentKm: 1,
        btAddress: null,
        btName: null,
        tireFrontBar: null,
        tireRearBar: null,
        createdAt: DateTime(2026),
      );
      expect(vehicleProfileText(v('Egea', '2019')), 'Fiat Egea 2019');
      expect(vehicleProfileText(v('', '')), 'Fiat');
    });

    test('hedef basınç metni', () {
      Vehicle v(double? f, double? r) => Vehicle(
        id: 1,
        brand: 'Fiat',
        model: '',
        year: '',
        currentKm: 1,
        btAddress: null,
        btName: null,
        tireFrontBar: f,
        tireRearBar: r,
        createdAt: DateTime(2026),
      );
      expect(tireTargetsText(v(null, null)), S.settingsTireTargetsNotSet);
      expect(tireTargetsText(v(2.3, 2.1)), '2,3 / 2,1 bar');
      expect(tireTargetsText(v(2.3, null)), '2,3 / — bar');
    });
  });

  // ---------------------------------------------------------------- araç

  testWidgets('araç bölümü mevcut değerleri gösteriyor', (
    WidgetTester tester,
  ) async {
    await seedVehicle();
    await pumpSettings(tester);

    expect(find.text('Fiat Egea 2019'), findsOneWidget);
    expect(find.text('118.420 km'), findsOneWidget);
    expect(find.text(S.settingsTireTargetsNotSet), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('marka/model/yıl düzenleniyor', (WidgetTester tester) async {
    await seedVehicle();
    await pumpSettings(tester);

    await tester.tap(find.byKey(const Key('row_vehicle_edit')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('vehicle_model')), 'Egea 1.6');
    await tester.tap(find.byKey(const Key('vehicle_edit_save')));
    await tester.pumpAndSettle();

    expect((await db.vehicleDao.get())!.model, 'Egea 1.6');
    expect(find.text('Fiat Egea 1.6 2019'), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('km büyütülürken onay sorulmuyor', (WidgetTester tester) async {
    await seedVehicle();
    await pumpSettings(tester);

    await tester.tap(find.byKey(const Key('row_km_fix')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('km_fix_field')), '119950');
    await tester.tap(find.byKey(const Key('km_fix_save')));
    await tester.pumpAndSettle();

    expect(find.text(S.settingsKmBackConfirm), findsNothing);
    expect((await db.vehicleDao.get())!.currentKm, 119950);
    await flushToast(tester);
    await disposeTree(tester);
  });

  testWidgets('km geriye alınırken onay isteniyor, iptalde yazmıyor', (
    WidgetTester tester,
  ) async {
    await seedVehicle();
    await pumpSettings(tester);

    await tester.tap(find.byKey(const Key('row_km_fix')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('km_fix_field')), '110000');
    await tester.tap(find.byKey(const Key('km_fix_save')));
    await tester.pumpAndSettle();

    expect(find.text(S.settingsKmBackConfirm), findsOneWidget);
    await tester.tap(find.byKey(const Key('km_back_cancel')));
    await tester.pumpAndSettle();
    expect((await db.vehicleDao.get())!.currentKm, 118420);

    await tester.tap(find.byKey(const Key('km_fix_save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('km_back_confirm')));
    await tester.pumpAndSettle();
    expect((await db.vehicleDao.get())!.currentKm, 110000);

    await flushToast(tester);
    await disposeTree(tester);
  });

  testWidgets('hedef basınçlar kaydediliyor, geçersiz değer reddediliyor', (
    WidgetTester tester,
  ) async {
    await seedVehicle();
    await pumpSettings(tester);

    await tester.tap(find.byKey(const Key('row_tire_targets')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('tire_front_field')), '9');
    await tester.tap(find.byKey(const Key('tire_target_save')));
    await tester.pumpAndSettle();
    expect(find.text(S.errBarInvalid), findsOneWidget);
    expect((await db.vehicleDao.get())!.tireFrontBar, isNull);

    await tester.enterText(find.byKey(const Key('tire_front_field')), '2,3');
    await tester.enterText(find.byKey(const Key('tire_rear_field')), '2,1');
    await tester.tap(find.byKey(const Key('tire_target_save')));
    await tester.pumpAndSettle();

    final VehicleRow v = (await db.vehicleDao.get())!;
    expect(v.tireFrontBar, 2.3);
    expect(v.tireRearBar, 2.1);
    expect(find.text('2,3 / 2,1 bar'), findsOneWidget);

    await flushToast(tester);
    await disposeTree(tester);
  });

  // ----------------------------------------------------------- bluetooth

  testWidgets('tanı satırı son kopmayı gösteriyor', (
    WidgetTester tester,
  ) async {
    await seedVehicle();
    // T13: kaynak `trips` tablosu.
    await insertTrip(
      disconnectedAt: DateTime(2026, 9, 3, 14, 30),
      durationMin: 25,
      counted: true,
      notified: true,
    );
    await pumpSettings(tester);

    expect(find.text('Uconnect'), findsOneWidget);
    expect(
      find.text('Son kopma: 3 Eyl 14:30, 25 dk sürüş, bildirim gönderildi'),
      findsOneWidget,
    );
    await disposeTree(tester);
  });

  testWidgets('kopma yokken tanı satırı boş durum metni', (
    WidgetTester tester,
  ) async {
    await seedVehicle();
    await pumpSettings(tester);
    expect(find.text(S.lastTripNone), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('cihaz seçicide seçim DB\'ye yazılıyor', (
    WidgetTester tester,
  ) async {
    await seedVehicle();
    bridge.devices = const <BondedDevice>[
      BondedDevice(name: 'Uconnect', address: '12:34:56:78:9A:BC'),
      BondedDevice(name: 'Kulaklık', address: 'AA:BB:CC:DD:EE:FF'),
    ];
    await pumpSettings(tester);

    await tester.tap(find.byKey(const Key('row_device')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('device_picker_title')), findsOneWidget);

    await tester.tap(find.byKey(const Key('device_AA:BB:CC:DD:EE:FF')));
    await tester.pumpAndSettle();

    final VehicleRow v = (await db.vehicleDao.get())!;
    expect(v.btAddress, 'AA:BB:CC:DD:EE:FF');
    expect(v.btName, 'Kulaklık');
    expect(find.text('Kulaklık'), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('Bluetooth izni yoksa izin akışı sunuluyor', (
    WidgetTester tester,
  ) async {
    await seedVehicle();
    bridge
      ..bluetooth = false
      ..bondedThrows = const BluetoothPermissionException();
    await pumpSettings(tester);

    await tester.tap(find.byKey(const Key('row_device')));
    await tester.pumpAndSettle();
    expect(find.text(S.deviceListNoPermission), findsOneWidget);

    bridge
      ..bondedThrows = null
      ..devices = const <BondedDevice>[
        BondedDevice(name: 'Uconnect', address: '12:34:56:78:9A:BC'),
      ];
    await tester.tap(find.byKey(const Key('device_picker_retry')));
    await tester.pumpAndSettle();

    expect(bridge.bluetooth, isTrue);
    expect(find.byKey(const Key('device_12:34:56:78:9A:BC')), findsOneWidget);
    await disposeTree(tester);
  });

  // ------------------------------------------------------------ kurallar

  testWidgets('switch değişikliği settings\'e ve snapshot\'a yansıyor', (
    WidgetTester tester,
  ) async {
    await seedVehicle();
    await pumpSettings(tester);

    await scrollTo(tester, find.byKey(const Key('rule_only_overdue')));
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('rule_only_overdue')),
        matching: find.byType(Switch),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      await db.settingsDao.get(SettingKeys.ruleOnlyOverdue),
      '0',
    );
    final Rules rules = await db.settingsDao.getRules();
    expect(rules.onlyOverdue, isFalse);

    // Snapshot'a yansıdı (T11 kabul kriteri).
    final String? snapshot = await bridge.readSnapshot();
    expect(snapshot, isNotNull);
    final Map<String, Object?> decoded =
        jsonDecode(snapshot!) as Map<String, Object?>;
    final Map<String, Object?> ruleJson =
        decoded['rules']! as Map<String, Object?>;
    expect(ruleJson['onlyOverdue'], false);

    await disposeTree(tester);
  });

  testWidgets('adımlayıcılar sınırlarda duruyor', (WidgetTester tester) async {
    await seedVehicle();
    await db.settingsDao.setRules(
      Rules.defaults.copyWith(minTripMinutes: 1, graceMinutes: 5),
    );
    await pumpSettings(tester);

    await scrollTo(tester, find.byKey(const Key('rule_min_trip')));
    // Alt uçta − pasif.
    expect(stepEnabled(tester, const Key('rule_min_trip_minus')), isFalse);
    await tester.tap(find.byKey(const Key('rule_min_trip_plus')));
    await tester.pumpAndSettle();
    expect((await db.settingsDao.getRules()).minTripMinutes, 2);

    // Üst uçta + pasif.
    expect(stepEnabled(tester, const Key('rule_grace_plus')), isFalse);
    await tester.tap(find.byKey(const Key('rule_grace_minus')));
    await tester.pumpAndSettle();
    expect((await db.settingsDao.getRules()).graceMinutes, 4);

    await disposeTree(tester);
  });

  testWidgets("adımlayıcı değişikliği de snapshot'a yansıyor", (
    WidgetTester tester,
  ) async {
    await seedVehicle();
    await pumpSettings(tester);

    await scrollTo(tester, find.byKey(const Key('rule_min_trip')));
    await tester.tap(find.byKey(const Key('rule_min_trip_plus')));
    await tester.pumpAndSettle();

    expect(
      await db.settingsDao.get(SettingKeys.ruleMinTripMinutes),
      '6',
    );
    final Map<String, Object?> snapshot =
        jsonDecode((await bridge.readSnapshot())!) as Map<String, Object?>;
    final Map<String, Object?> rules =
        snapshot['rules']! as Map<String, Object?>;
    expect(rules['minTripMinutes'], 6);

    await disposeTree(tester);
  });

  testWidgets('yedek bildirim seçenekleri arasında geziyor', (
    WidgetTester tester,
  ) async {
    await seedVehicle();
    await pumpSettings(tester);

    await scrollTo(tester, find.byKey(const Key('rule_fallback')));
    expect(find.text('7 gün sonra'), findsOneWidget);

    await tester.tap(find.byKey(const Key('rule_fallback_plus')));
    await tester.pumpAndSettle();
    expect((await db.settingsDao.getRules()).fallbackAfterDays, 14);
    expect(stepEnabled(tester, const Key('rule_fallback_plus')), isFalse);

    await tester.tap(find.byKey(const Key('rule_fallback_minus')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rule_fallback_minus')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rule_fallback_minus')));
    await tester.pumpAndSettle();
    expect((await db.settingsDao.getRules()).fallbackAfterDays, 0);
    expect(find.text(S.ruleFallbackOff), findsOneWidget);

    await disposeTree(tester);
  });

  // ----------------------------------------------------- kontrol listesi

  testWidgets('gün maddesinde aralık adımlayıcı presetlerde geziyor', (
    WidgetTester tester,
  ) async {
    final int v = await seedVehicle();
    final CheckItemRow oil = await item(v, 'oil_level');
    expect(oil.intervalDays, 14);

    await pumpSettings(tester);
    await scrollTo(tester, find.byKey(Key('setting_item_${oil.id}')));

    await tester.tap(find.byKey(Key('interval_plus_${oil.id}')));
    await tester.pumpAndSettle();
    expect((await db.itemDao.getById(oil.id))!.intervalDays, 30);

    await tester.tap(find.byKey(Key('interval_minus_${oil.id}')));
    await tester.pumpAndSettle();
    expect((await db.itemDao.getById(oil.id))!.intervalDays, 14);

    await disposeTree(tester);
  });

  testWidgets('both maddede +/− yalnız km değiştiriyor', (
    WidgetTester tester,
  ) async {
    final int v = await seedVehicle();
    final CheckItemRow both = (await db.itemDao.getAll(
      v,
    )).firstWhere((CheckItemRow r) => r.scheduleKind == 'both');
    final int days = both.intervalDays!;
    final int km = both.intervalKm!;

    await pumpSettings(tester);
    await scrollTo(tester, find.byKey(Key('setting_item_${both.id}')));
    await tester.tap(find.byKey(Key('interval_plus_${both.id}')));
    await tester.pumpAndSettle();

    final CheckItemRow after = (await db.itemDao.getById(both.id))!;
    expect(after.intervalDays, days);
    expect(after.intervalKm, greaterThan(km));

    await disposeTree(tester);
  });

  testWidgets('km presetinin üst ucundaki maddede + pasif', (
    WidgetTester tester,
  ) async {
    final int v = await seedVehicle();
    final CheckItemRow belt = await item(v, 'timing_belt');
    expect(belt.intervalKm, 120000);

    await pumpSettings(tester);
    await scrollTo(tester, find.byKey(Key('setting_item_${belt.id}')));
    expect(stepEnabled(tester, Key('interval_plus_${belt.id}')), isFalse);
    expect(stepEnabled(tester, Key('interval_minus_${belt.id}')), isTrue);

    await disposeTree(tester);
  });

  testWidgets('mevsimsel maddede adımlayıcı pasif', (
    WidgetTester tester,
  ) async {
    final int v = await seedVehicle();
    final CheckItemRow seasonal = (await db.itemDao.getAll(
      v,
    )).firstWhere((CheckItemRow r) => r.scheduleKind == 'seasonal');

    await pumpSettings(tester);
    await scrollTo(tester, find.byKey(Key('setting_item_${seasonal.id}')));

    expect(stepEnabled(tester, Key('interval_plus_${seasonal.id}')), isFalse);
    expect(stepEnabled(tester, Key('interval_minus_${seasonal.id}')), isFalse);
    await disposeTree(tester);
  });

  testWidgets('madde kapatılabiliyor', (WidgetTester tester) async {
    final int v = await seedVehicle();
    final CheckItemRow oil = await item(v, 'oil_level');
    expect(oil.enabled, isTrue);

    await pumpSettings(tester);
    await scrollTo(tester, find.byKey(Key('setting_item_${oil.id}')));
    await tester.tap(find.byKey(Key('enabled_${oil.id}')));
    await tester.pumpAndSettle();

    expect((await db.itemDao.getById(oil.id))!.enabled, isFalse);
    await disposeTree(tester);
  });

  testWidgets('şablon maddesinde ölçüm tipi kilitli ve Sil yok', (
    WidgetTester tester,
  ) async {
    final int v = await seedVehicle();
    final CheckItemRow oil = await item(v, 'oil_level');

    await pumpSettings(tester);
    await scrollTo(tester, find.byKey(Key('setting_item_${oil.id}')));
    await tester.tap(find.byKey(Key('setting_item_${oil.id}')));
    await tester.pumpAndSettle();

    expect(find.text(S.itemEditTitle), findsOneWidget);
    expect(
      tester
          .widget<DropdownButtonFormField<MeasureType>>(
            find.byKey(const Key('item_measure')),
          )
          .onChanged,
      isNull,
    );
    expect(find.text(S.itemEditMeasureLocked), findsOneWidget);
    expect(find.byKey(const Key('item_edit_delete')), findsNothing);
    // "Tarih/km düzelt" şablon maddesinde de var.
    expect(find.byKey(const Key('item_edit_fix')), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('şablon maddesinin adı ve aralığı düzenlenebiliyor', (
    WidgetTester tester,
  ) async {
    final int v = await seedVehicle();
    final CheckItemRow oil = await item(v, 'oil_level');

    await pumpSettings(tester);
    await scrollTo(tester, find.byKey(Key('setting_item_${oil.id}')));
    await tester.tap(find.byKey(Key('setting_item_${oil.id}')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('item_name')), 'Yağ seviyesi');
    await tester.enterText(
      find.byKey(const Key('item_interval_days')),
      '21',
    );
    await tester.tap(find.byKey(const Key('item_edit_save')));
    await tester.pumpAndSettle();

    final CheckItemRow after = (await db.itemDao.getById(oil.id))!;
    expect(after.name, 'Yağ seviyesi');
    expect(after.intervalDays, 21);
    // Ölçüm tipi korundu.
    expect(after.measureType, 'level');

    await disposeTree(tester);
  });

  testWidgets('boş adla kayıt hata gösteriyor', (WidgetTester tester) async {
    final int v = await seedVehicle();
    final CheckItemRow oil = await item(v, 'oil_level');

    await pumpSettings(tester);
    await scrollTo(tester, find.byKey(Key('setting_item_${oil.id}')));
    await tester.tap(find.byKey(Key('setting_item_${oil.id}')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('item_name')), '');
    await tester.tap(find.byKey(const Key('item_edit_save')));
    await tester.pumpAndSettle();

    expect(find.text(S.errNameRequired), findsOneWidget);
    expect((await db.itemDao.getById(oil.id))!.name, 'Motor yağı seviyesi');

    await disposeTree(tester);
  });

  testWidgets('madde ekleniyor ve listede görünüyor', (
    WidgetTester tester,
  ) async {
    final int v = await seedVehicle();
    final int before = (await db.itemDao.getAll(v)).length;

    await pumpSettings(tester);
    await scrollTo(tester, find.byKey(const Key('add_item')));
    await tester.tap(find.byKey(const Key('add_item')));
    await tester.pumpAndSettle();

    expect(find.text(S.itemEditNewTitle), findsOneWidget);
    await tester.enterText(find.byKey(const Key('item_name')), 'Yakıt filtresi');
    await tester.enterText(find.byKey(const Key('item_interval_days')), '365');
    await tester.tap(find.byKey(const Key('item_edit_save')));
    await tester.pumpAndSettle();

    final List<CheckItemRow> after = await db.itemDao.getAll(v);
    expect(after.length, before + 1);
    final CheckItemRow added = after.last;
    expect(added.name, 'Yakıt filtresi');
    expect(added.templateKey, isNull);
    expect(added.intervalDays, 365);
    expect(added.enabled, isTrue);

    await disposeTree(tester);
  });

  testWidgets('kullanıcı maddesinde ölçüm tipi değiştirilebiliyor', (
    WidgetTester tester,
  ) async {
    final int v = await seedVehicle();
    final int id = await db.itemListRepoCreate(v);

    await pumpSettings(tester);
    await scrollTo(tester, find.byKey(Key('setting_item_$id')));
    await tester.tap(find.byKey(Key('setting_item_$id')));
    await tester.pumpAndSettle();

    expect(find.text(S.itemEditMeasureLocked), findsNothing);
    await tester.tap(find.byKey(const Key('item_measure')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.measureTypeTires).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('item_edit_save')));
    await tester.pumpAndSettle();

    final CheckItemRow after = (await db.itemDao.getById(id))!;
    expect(after.measureType, 'tires');

    await disposeTree(tester);
  });

  testWidgets('kullanıcı maddesi kayıtlarıyla birlikte siliniyor', (
    WidgetTester tester,
  ) async {
    final int v = await seedVehicle();
    final int id = await db.itemListRepoCreate(v);
    await db.logDao.addLog(
      itemId: id,
      doneAt: DateTime(2026, 9, 1, 10),
      doneDay: '2026-09-01',
      km: 118000,
    );
    expect((await db.logDao.getAll()).length, 1);

    await pumpSettings(tester);
    await scrollTo(tester, find.byKey(Key('setting_item_$id')));
    await tester.tap(find.byKey(Key('setting_item_$id')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('item_edit_delete')));
    await tester.pumpAndSettle();
    expect(find.text(S.itemEditDeleteConfirm), findsOneWidget);

    // İptal: hiçbir şey olmuyor.
    await tester.tap(find.byKey(const Key('item_delete_cancel')));
    await tester.pumpAndSettle();
    expect(await db.itemDao.getById(id), isNotNull);

    await tester.tap(find.byKey(const Key('item_edit_delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('item_delete_confirm')));
    await tester.pumpAndSettle();

    expect(await db.itemDao.getById(id), isNull);
    expect(await db.logDao.getAll(), isEmpty);
    expect(find.byKey(Key('setting_item_$id')), findsNothing);

    await flushToast(tester);
    await disposeTree(tester);
  });

  // ----------------------------------------------------------- uygulama

  testWidgets('şablon sürümü gösteriliyor', (WidgetTester tester) async {
    await seedVehicle();
    await pumpSettings(tester);
    await scrollTo(tester, find.byKey(const Key('row_template_version')));
    expect(find.text('${S.templateVersionPrefix} ${seed.version}'),
        findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('verileri sıfırla iptal edilince hiçbir şey olmuyor', (
    WidgetTester tester,
  ) async {
    await seedVehicle();
    await pumpSettings(tester);
    await scrollTo(tester, find.byKey(const Key('row_reset')));
    await tester.tap(find.byKey(const Key('row_reset')));
    await tester.pumpAndSettle();

    expect(find.text(S.settingsResetConfirm), findsOneWidget);
    await tester.tap(find.byKey(const Key('reset_cancel')));
    await tester.pumpAndSettle();

    expect(await db.vehicleDao.get(), isNotNull);
    await disposeTree(tester);
  });

  testWidgets('verileri sıfırla DB\'yi boşaltıp kuruluma dönüyor', (
    WidgetTester tester,
  ) async {
    final int v = await seedVehicle();
    await db.logDao.addLog(
      itemId: (await item(v, 'oil_level')).id,
      doneAt: DateTime(2026, 9, 1, 10),
      doneDay: '2026-09-01',
      km: 118000,
    );
    await pumpSettings(tester);

    await scrollTo(tester, find.byKey(const Key('row_reset')));
    await tester.tap(find.byKey(const Key('row_reset')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reset_confirm')));
    await tester.pumpAndSettle();

    expect(await db.vehicleDao.get(), isNull);
    expect(await db.itemDao.getAll(v), isEmpty);
    expect(await db.logDao.getAll(), isEmpty);
    expect(await db.settingsDao.getAll(), isEmpty);
    // Kotlin tarafındaki snapshot/prefs de temizlendi.
    expect(bridge.clearEngineCalls, 1);
    expect(await bridge.readSnapshot(), isNull);
    // Kuruluma döndü.
    expect(find.text(S.setupVehicleTitle), findsOneWidget);

    await flushToast(tester);
    await disposeTree(tester);
  });

  // ------------------------------------------------------- geliştirici (T12)

  testWidgets('simülasyon satırları kanala doğru argümanla gidiyor', (
    WidgetTester tester,
  ) async {
    await seedVehicle();
    await pumpSettings(tester);

    await scrollTo(tester, find.byKey(const Key('debug_long_trip')));
    await tester.tap(find.byKey(const Key('debug_long_trip')));
    await tester.pumpAndSettle();
    expect(bridge.simulations.last.event, 'disconnect');
    expect(bridge.simulations.last.minutes, kDebugLongTripMin);
    expect(find.text(S.debugDone), findsOneWidget);
    await flushToast(tester);

    await scrollTo(tester, find.byKey(const Key('debug_short_trip')));
    await tester.tap(find.byKey(const Key('debug_short_trip')));
    await tester.pumpAndSettle();
    expect(bridge.simulations.last.event, 'disconnect');
    expect(bridge.simulations.last.minutes, kDebugShortTripMin);
    await flushToast(tester);

    await scrollTo(tester, find.byKey(const Key('debug_connect')));
    await tester.tap(find.byKey(const Key('debug_connect')));
    await tester.pumpAndSettle();
    expect(bridge.simulations.last.event, 'connect');
    expect(bridge.simulations.last.minutes, 0);

    await flushToast(tester);
    await disposeTree(tester);
  });

  testWidgets('araç cihazı seçilmemişse simülasyon uyarı veriyor', (
    WidgetTester tester,
  ) async {
    await seedVehicle();
    bridge.simulateThrows = PlatformException(code: 'NO_CAR');
    await pumpSettings(tester);

    await scrollTo(tester, find.byKey(const Key('debug_long_trip')));
    await tester.tap(find.byKey(const Key('debug_long_trip')));
    await tester.pumpAndSettle();

    expect(find.text(S.debugNoCar), findsOneWidget);
    expect(bridge.simulations, isEmpty);
    await flushToast(tester);
    await disposeTree(tester);
  });

  testWidgets("snapshot'ı göster yazılmış snapshot'ı açıyor", (
    WidgetTester tester,
  ) async {
    await seedVehicle();
    await pumpSettings(tester);

    // Snapshot senkronu ilk karede yazdı.
    expect(await bridge.readSnapshot(), isNotNull);

    await scrollTo(tester, find.byKey(const Key('debug_snapshot')));
    await tester.tap(find.byKey(const Key('debug_snapshot')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('debug_snapshot_dialog')), findsOneWidget);
    expect(find.textContaining('"rules"'), findsOneWidget);
    await tester.tap(find.byKey(const Key('debug_snapshot_close')));
    await tester.pumpAndSettle();
    await disposeTree(tester);
  });

  testWidgets("yedek işi satırı kanala gidiyor ve olayı DB'ye işliyor", (
    WidgetTester tester,
  ) async {
    await seedVehicle();
    // Motor yedek bildirimi bassaydı ne yazardı: `fallback` olayı.
    bridge.fallbackEventOnRun = true;
    await pumpSettings(tester);

    await scrollTo(tester, find.byKey(const Key('debug_fallback')));
    await tester.tap(find.byKey(const Key('debug_fallback')));
    await tester.pumpAndSettle();

    expect(bridge.dailyWorkerRuns, 1);
    expect(find.text(S.debugFallbackRan), findsOneWidget);

    // K-26: `trips`'e yazıldı ama tanı satırına girmedi.
    final List<Trip> rows = await TripRepo(db).getAll();
    expect(rows.single.isFallback, isTrue);
    expect(await TripRepo(db).lastTrip(), isNull);

    await flushToast(tester);
    await disposeTree(tester);
  });

  testWidgets('tanı satırı motorun notunu kullanıyor', (
    WidgetTester tester,
  ) async {
    await seedVehicle();
    await insertTrip(
      disconnectedAt: DateTime(2026, 9, 3, 18, 5),
      durationMin: 8,
      counted: true,
      notified: false,
      note: kTripNoteOncePerDay,
    );
    await pumpSettings(tester);

    expect(
      find.text('Son kopma: 3 Eyl 18:05, 8 dk sürüş, bugün zaten hatırlatıldı'),
      findsOneWidget,
    );
    await disposeTree(tester);
  });
}

/// Test için hızlı kullanıcı maddesi (şablon maddesi değil).
extension on AppDatabase {
  Future<int> itemListRepoCreate(int vehicleId) async {
    return itemDao.insertOne(
      CheckItemsCompanion.insert(
        vehicleId: vehicleId,
        name: 'Kendi maddem',
        groupKey: 'monthly',
        scheduleKind: scheduleKindToString(ScheduleKind.days),
        intervalDays: const Value<int?>(30),
        measureType: measureTypeToString(MeasureType.none),
        sortOrder: 999,
      ),
    );
  }
}
