import 'dart:convert';
import 'dart:io';

import 'package:carkeep/core/date_utils.dart';
import 'package:carkeep/core/strings_tr.dart';
import 'package:carkeep/core/widgets/tr_date_field.dart';
import 'package:carkeep/data/db/daos/settings_dao.dart';
import 'package:carkeep/data/db/database.dart';
import 'package:carkeep/data/platform/device_list.dart';
import 'package:carkeep/data/platform/platform_bridge.dart';
import 'package:carkeep/data/seed/seed_loader.dart';
import 'package:carkeep/domain/item_grouping.dart';
import 'package:carkeep/domain/models/item_status.dart';
import 'package:carkeep/features/setup/setup_controller.dart';
import 'package:carkeep/providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kanal çağrılarını sahteleyen köprü.
class FakeBridge extends PlatformBridge {
  FakeBridge({
    this.bluetooth = false,
    this.notification = false,
    this.battery = false,
    this.btEnabled = true,
    this.devices = const <BondedDevice>[],
    this.bondedThrows,
  }) : super(channel: const MethodChannel('carkeep.test/fake'));

  bool bluetooth;
  bool notification;
  bool battery;
  bool btEnabled;
  List<BondedDevice> devices;
  Object? bondedThrows;

  int scheduleCalls = 0;
  int clearEngineCalls = 0;

  /// Ayarlar tanı satırı ve snapshot testleri için.
  BluetoothState btState = BluetoothState.unknown;
  String? snapshotJson;

  /// Geliştirici bölümü testleri için.
  final List<({String event, int minutes})> simulations =
      <({String event, int minutes})>[];
  Object? simulateThrows;

  /// T13: Kotlin'in biriktirdikleri. `drain` oku+sil, tıpkı prefs gibi.
  String pendingEventsJson = '[]';
  int drainCalls = 0;

  /// Bildirimden mi açıldı; okununca Kotlin temizler.
  String? launchAction;

  /// T14: `debugRunDailyWorker` kaç kez çağrıldı ve motor `fallback` olayı
  /// yazdı mı (koşullar sağlandıysa yazar).
  int dailyWorkerRuns = 0;
  bool fallbackEventOnRun = false;

  /// K-27: tepsideki bildirim kaç kez iptal edildi.
  int cancelCalls = 0;

  @override
  Future<bool> hasBluetoothPermission() async => bluetooth;

  @override
  Future<bool> requestBluetoothPermission() async {
    bluetooth = true;
    return true;
  }

  @override
  Future<bool> hasNotificationPermission() async => notification;

  @override
  Future<bool> requestNotificationPermission() async {
    notification = true;
    return true;
  }

  @override
  Future<bool> areNotificationsEnabled() async => true;

  @override
  Future<bool> isIgnoringBatteryOptimizations() async => battery;

  @override
  Future<bool> isBluetoothEnabled() async => btEnabled;

  @override
  Future<void> openBatteryOptimizationSettings() async {
    battery = true;
  }

  @override
  Future<List<BondedDevice>> getBondedDevices() async {
    final Object? err = bondedThrows;
    if (err != null) {
      throw err;
    }
    return devices;
  }

  @override
  Future<void> scheduleDailyWorker() async {
    scheduleCalls++;
  }

  @override
  Future<void> cancelNotification() async {
    cancelCalls++;
  }

  @override
  Future<BluetoothState> getBluetoothState() async => btState;

  @override
  Future<void> writeSnapshot(String json) async {
    snapshotJson = json;
  }

  @override
  Future<String?> readSnapshot() async => snapshotJson;

  @override
  Future<void> clearEngine() async {
    clearEngineCalls++;
    snapshotJson = null;
  }

  @override
  Future<List<PendingEvent>> drainPendingEvents() async {
    drainCalls++;
    final List<PendingEvent> events = PendingEvent.decodeAll(pendingEventsJson);
    pendingEventsJson = '[]';
    return events;
  }

  @override
  Future<String?> getLaunchAction() async {
    final String? action = launchAction;
    launchAction = null;
    return action;
  }

  @override
  Future<void> debugRunDailyWorker() async {
    dailyWorkerRuns++;
    if (!fallbackEventOnRun) {
      return;
    }
    pendingEventsJson = jsonEncode(<Map<String, Object?>>[
      <String, Object?>{
        'type': 'fallback',
        'at': DateTime(2026, 9, 3, 19).millisecondsSinceEpoch,
        'overdueCount': 1,
      },
    ]);
  }

  @override
  Future<void> debugSimulate({required String event, int minutes = 0}) async {
    final Object? err = simulateThrows;
    if (err != null) {
      throw err;
    }
    simulations.add((event: event, minutes: minutes));
  }
}

void main() {
  late Seed seed;

  setUpAll(() {
    seed = SeedLoader.parse(
      File('assets/seed/checklist_seed.json').readAsStringSync(),
    );
  });

  late AppDatabase db;
  late FakeBridge bridge;
  late ProviderContainer container;
  final DateTime today = DateTime(2026, 9, 3);

  void makeContainer({FakeBridge? withBridge}) {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bridge = withBridge ?? FakeBridge();
    container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        seedProvider.overrideWithValue(seed),
        platformBridgeProvider.overrideWithValue(bridge),
        todayProvider.overrideWith((Ref ref) => today),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);
  }

  SetupController controller() =>
      container.read(setupControllerProvider.notifier);

  SetupState state() => container.read(setupControllerProvider);

  // ------------------------------------------------------------- doğrulama

  group('adım doğrulaması', () {
    setUp(makeContainer);

    test('1. adım: marka boşken ilerlemiyor', () {
      expect(controller().next(), isFalse);
      expect(state().step, 1);
      expect(state().error, S.errBrandRequired);
    });

    test('1. adım: yalnız boşluk da geçmiyor', () {
      controller().setBrand('   ');
      expect(controller().next(), isFalse);
      expect(state().step, 1);
    });

    test('1. adım: marka doluysa geçiyor, model ve yıl isteğe bağlı', () {
      controller().setBrand('Fiat');
      expect(controller().next(), isTrue);
      expect(state().step, 2);
      expect(state().error, isNull);
    });

    test('2. adım: km boşken ilerlemiyor', () {
      controller()
        ..setBrand('Fiat')
        ..next();
      expect(controller().next(), isFalse);
      expect(state().step, 2);
      expect(state().error, S.errKmRequired);
    });

    test('2. adım: km geçersizken ilerlemiyor', () {
      controller()
        ..setBrand('Fiat')
        ..next()
        ..setKm('abc');
      expect(controller().next(), isFalse);
      expect(state().step, 2);
    });

    test('2. adım: km 0 kabul', () {
      controller()
        ..setBrand('Fiat')
        ..next()
        ..setKm('0');
      expect(controller().next(), isTrue);
      expect(state().step, 3);
    });

    test('3 ve 4. adım zorunlu alan istemiyor', () {
      final SetupController c = controller()
        ..setBrand('Fiat')
        ..next()
        ..setKm('118420')
        ..next();
      expect(state().step, 3);
      expect(c.next(), isTrue);
      expect(state().step, 4);
      expect(c.next(), isTrue);
      expect(state().step, 5);
    });

    test('5. adım: ikisi de boşsa geçiyor', () {
      final SetupController c = controller()
        ..setBrand('Fiat')
        ..next()
        ..setKm('118420')
        ..next()
        ..next()
        ..next();
      expect(state().step, 5);
      expect(c.next(), isTrue);
      expect(state().step, 6);
    });

    test('5. adım: yalnız tarih varsa uyarı', () {
      final SetupController c = controller()
        ..setBrand('Fiat')
        ..next()
        ..setKm('118420')
        ..next()
        ..next()
        ..next()
        ..setLastServiceDate(DateTime(2026, 3, 12), touched: true);
      expect(c.next(), isFalse);
      expect(state().error, S.errServiceIncomplete);
    });

    test('5. adım: yalnız km varsa uyarı', () {
      final SetupController c = controller()
        ..setBrand('Fiat')
        ..next()
        ..setKm('118420')
        ..next()
        ..next()
        ..next()
        ..setLastServiceKm('104900');
      expect(c.next(), isFalse);
      expect(state().error, S.errServiceIncomplete);
    });

    test('5. adım: ikisi birlikte geçiyor', () {
      final SetupController c = controller()
        ..setBrand('Fiat')
        ..next()
        ..setKm('118420')
        ..next()
        ..next()
        ..next()
        ..setLastServiceDate(DateTime(2026, 3, 12), touched: true)
        ..setLastServiceKm('104900');
      expect(c.next(), isTrue);
      expect(state().step, 6);
    });

    test('geri gitmek hata mesajını temizliyor', () {
      final SetupController c = controller()
        ..setBrand('Fiat')
        ..next();
      expect(c.next(), isFalse);
      expect(state().error, isNotNull);
      c.back();
      expect(state().step, 1);
      expect(state().error, isNull);
    });

    test('1. adımda geri gitmek bir şey yapmıyor', () {
      controller().back();
      expect(state().step, 1);
    });
  });

  // -------------------------------------------------------------- cihazlar

  group('cihaz listesi', () {
    test('cihaz varsa ok', () async {
      makeContainer(
        withBridge: FakeBridge(
          devices: const <BondedDevice>[
            BondedDevice(name: 'Uconnect', address: '12:34:56:78:9A:BC'),
          ],
        ),
      );
      await controller().loadDevices();
      expect(state().deviceListState, DeviceListState.ok);
      expect(state().devices.length, 1);
    });

    test('Bluetooth açık ve liste boşsa "cihaz yok"', () async {
      makeContainer(withBridge: FakeBridge(btEnabled: true));
      await controller().loadDevices();
      expect(state().deviceListState, DeviceListState.empty);
    });

    /// T05 cihaz testinde bulundu.
    test('Bluetooth kapalıysa "cihaz yok" demiyor', () async {
      makeContainer(withBridge: FakeBridge(btEnabled: false));
      await controller().loadDevices();
      expect(state().deviceListState, DeviceListState.bluetoothOff);
    });

    test('izin yoksa noPermission', () async {
      makeContainer(
        withBridge: FakeBridge(
          bondedThrows: const BluetoothPermissionException(),
        ),
      );
      await controller().loadDevices();
      expect(state().deviceListState, DeviceListState.noPermission);
    });

    test('adaptör yoksa bluetoothOff', () async {
      makeContainer(
        withBridge: FakeBridge(
          bondedThrows: const BluetoothUnavailableException(),
        ),
      );
      await controller().loadDevices();
      expect(state().deviceListState, DeviceListState.bluetoothOff);
    });

    test('seçim ve seçimi kaldırma', () async {
      makeContainer(
        withBridge: FakeBridge(
          devices: const <BondedDevice>[
            BondedDevice(name: 'Uconnect', address: '12:34:56:78:9A:BC'),
          ],
        ),
      );
      await controller().loadDevices();
      controller().selectDevice(state().devices.single);
      expect(state().selectedAddress, '12:34:56:78:9A:BC');
      expect(state().selectedName, 'Uconnect');
      controller().clearDevice();
      expect(state().selectedAddress, isNull);
    });
  });

  // ---------------------------------------------------------------- izinler

  group('izinler', () {
    test('istek sonrası durum tazeleniyor', () async {
      makeContainer();
      await controller().refreshPermissions();
      expect(state().permissions.bluetooth, isFalse);
      await controller().requestBluetooth();
      expect(state().permissions.bluetooth, isTrue);
      await controller().requestNotification();
      expect(state().permissions.notification, isTrue);
      await controller().openBatterySettings();
      await controller().refreshPermissions();
      expect(state().permissions.batteryIgnored, isTrue);
    });
  });

  // ------------------------------------------------------------------ bitiş

  group('Başla', () {
    Future<void> fillAndFinish({
      DateTime? serviceDate,
      String serviceKm = '',
      String? deviceAddress,
    }) async {
      final SetupController c = controller()
        ..setBrand('Fiat')
        ..setModel('Egea 1.6 MultiJet')
        ..setYear('2019')
        ..setKm('118420');
      if (deviceAddress != null) {
        c.selectDevice(
          BondedDevice(name: 'Uconnect', address: deviceAddress),
        );
      }
      if (serviceDate != null) {
        c.setLastServiceDate(serviceDate, touched: true);
      }
      if (serviceKm.isNotEmpty) {
        c.setLastServiceKm(serviceKm);
      }
      // 6. adıma taşı.
      for (int i = 0; i < 5; i++) {
        c.next();
      }
      expect(state().step, 6);
      expect(await c.finish(), isTrue);
      // Drift akislari yayilsin: statusesProvider bunlara dayaniyor.
      await container.read(vehicleProvider.future);
      await container.read(itemsProvider.future);
    }

    test('1 araç ve 34 madde yazılıyor', () async {
      makeContainer();
      await fillAndFinish();

      final VehicleRow? v = await db.vehicleDao.get();
      expect(v, isNotNull);
      expect(v!.brand, 'Fiat');
      expect(v.model, 'Egea 1.6 MultiJet');
      expect(v.year, '2019');
      expect(v.currentKm, 118420);
      expect((await db.itemDao.getAll(v.id)).length, 34);
      expect(state().finished, isTrue);
    });

    test('install_day ve template_version yazılıyor', () async {
      makeContainer();
      await fillAndFinish();
      expect(
        await db.settingsDao.get(SettingKeys.installDay),
        dayKey(today),
      );
      expect(
        await db.settingsDao.getInt(SettingKeys.templateVersion),
        seed.version,
      );
      expect(container.read(installDayProvider), today);
    });

    test('günlük iş planlanıyor', () async {
      makeContainer();
      await fillAndFinish();
      expect(bridge.scheduleCalls, 1);
    });

    test('seçilen cihaz araca yazılıyor', () async {
      makeContainer();
      await fillAndFinish(deviceAddress: '12:34:56:78:9A:BC');
      final VehicleRow v = (await db.vehicleDao.get())!;
      expect(v.btAddress, '12:34:56:78:9A:BC');
      expect(v.btName, 'Uconnect');
    });

    test('cihaz seçilmezse araç adres taşımıyor', () async {
      makeContainer();
      await fillAndFinish();
      expect((await db.vehicleDao.get())!.btAddress, isNull);
    });

    test('6. adımdaki aç/kapat seçimleri uygulanıyor', () async {
      makeContainer();
      // Varsayılan açık bir maddeyi kapat, varsayılan kapalı birini aç.
      controller()
        ..toggleItem('oil_level', false)
        ..toggleItem('kasko', true);
      await fillAndFinish();

      final int vehicleId = (await db.vehicleDao.get())!.id;
      final List<CheckItemRow> rows = await db.itemDao.getAll(vehicleId);
      expect(
        rows.firstWhere((CheckItemRow r) => r.templateKey == 'oil_level').enabled,
        isFalse,
      );
      expect(
        rows.firstWhere((CheckItemRow r) => r.templateKey == 'kasko').enabled,
        isTrue,
      );
      // Dokunulmayanlar seed varsayılanında.
      expect(
        rows
            .firstWhere((CheckItemRow r) => r.templateKey == 'tire_pressure')
            .enabled,
        isTrue,
      );
      expect(
        rows
            .firstWhere((CheckItemRow r) => r.templateKey == 'gearbox_oil')
            .enabled,
        isFalse,
      );
    });

    test('son servis girilince oil_change ve pollen_filter hesaplanıyor',
        () async {
      makeContainer();
      await fillAndFinish(
        serviceDate: DateTime(2026, 3, 12),
        serviceKm: '104900',
      );

      final List<StatusedItem> statuses = container.read(statusesProvider);
      expect(statuses, isNotEmpty);

      StatusedItem byKey(String key) => statuses.firstWhere(
        (StatusedItem e) => e.item.templateKey == key,
      );

      final StatusedItem oil = byKey('oil_change');
      expect(oil.item.lastDoneDay, '2026-03-12');
      expect(oil.item.lastDoneKm, 104900);
      expect(oil.status.state, isNot(ItemState.unknown));
      expect(oil.status.state, ItemState.ok);
      expect(oil.status.kmLeft, 1480);

      final StatusedItem pollen = byKey('pollen_filter');
      expect(pollen.status.state, isNot(ItemState.unknown));

      // appliesLastService olmayanlar dokunulmadı.
      expect(byKey('timing_belt').item.lastDoneDay, isNull);
      expect(byKey('timing_belt').status.state, ItemState.unknown);
    });

    test('son servis girilmezse bu maddeler Bilinmiyor kalıyor', () async {
      makeContainer();
      await fillAndFinish();

      final List<StatusedItem> statuses = container.read(statusesProvider);
      StatusedItem byKey(String key) => statuses.firstWhere(
        (StatusedItem e) => e.item.templateKey == key,
      );
      expect(byKey('oil_change').item.lastDoneDay, isNull);
      expect(byKey('oil_change').status.state, ItemState.unknown);
      expect(byKey('pollen_filter').status.state, ItemState.unknown);
    });

    test('fiziksel maddeler kurulum gününden başlıyor', () async {
      makeContainer();
      await fillAndFinish();
      final List<StatusedItem> statuses = container.read(statusesProvider);
      final StatusedItem oilLevel = statuses.firstWhere(
        (StatusedItem e) => e.item.templateKey == 'oil_level',
      );
      // startsFromInstall=true, 14 gün → vade kurulum + 14.
      expect(oilLevel.status.dueDay, '2026-09-17');
      expect(oilLevel.status.state, ItemState.ok);
    });

    test('izin verilmese de kurulum tamamlanıyor', () async {
      makeContainer(withBridge: FakeBridge());
      expect(bridge.bluetooth, isFalse);
      expect(bridge.notification, isFalse);
      await fillAndFinish();
      expect((await db.vehicleDao.get()), isNotNull);
    });

    test('iki kez finish çağırmak ikinci aracı yazmıyor', () async {
      makeContainer();
      await fillAndFinish();
      final int before =
          (await db.itemDao.getAll((await db.vehicleDao.get())!.id)).length;
      // finished sonrasi tekrar cagri yok sayilir (tek arac, K-01).
      expect(await controller().finish(), isFalse);
      final List<VehicleRow> all = await db.select(db.vehicles).get();
      expect(all.length, 1);
      expect(before, 34);
    });
  });

  // ---------------------------------------------------------- tarih alanı

  group('parseTrDateParts (K-21)', () {
    final DateTime today = DateTime(2026, 9, 3);

    test('geçerli tarih', () {
      expect(
        parseTrDateParts(day: '12', month: 3, year: '2026', today: today),
        DateTime(2026, 3, 12),
      );
    });

    test('eksik parça null', () {
      expect(
        parseTrDateParts(day: '', month: 3, year: '2026', today: today),
        isNull,
      );
      expect(
        parseTrDateParts(day: '12', month: null, year: '2026', today: today),
        isNull,
      );
      expect(
        parseTrDateParts(day: '12', month: 3, year: '', today: today),
        isNull,
      );
    });

    test('taşan gün reddediliyor', () {
      expect(
        parseTrDateParts(day: '31', month: 2, year: '2026', today: today),
        isNull,
      );
      expect(
        parseTrDateParts(day: '29', month: 2, year: '2026', today: today),
        isNull,
      );
      // Gecmisteki artik yil kabul; 2028 bugunden ileri oldugu icin reddedilir.
      expect(
        parseTrDateParts(day: '29', month: 2, year: '2024', today: today),
        DateTime(2024, 2, 29),
      );
      expect(
        parseTrDateParts(day: '29', month: 2, year: '2028', today: today),
        isNull,
      );
    });

    test('ileri tarih reddediliyor, bugün kabul', () {
      expect(
        parseTrDateParts(day: '4', month: 9, year: '2026', today: today),
        isNull,
      );
      expect(
        parseTrDateParts(day: '3', month: 9, year: '2026', today: today),
        DateTime(2026, 9, 3),
      );
    });

    test('saçma yıl reddediliyor', () {
      expect(
        parseTrDateParts(day: '12', month: 3, year: '20', today: today),
        isNull,
      );
    });

    test('isTrDateEmpty', () {
      expect(isTrDateEmpty(day: '', month: null, year: ''), isTrue);
      expect(isTrDateEmpty(day: '12', month: null, year: ''), isFalse);
      expect(isTrDateEmpty(day: '', month: 3, year: ''), isFalse);
    });
  });
}
