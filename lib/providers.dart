/// Riverpod sağlayıcıları (02-mimari §9). Codegen yok (K-08).
///
/// `main.dart` açılışta [databaseProvider], [seedProvider] ve
/// [installDayProvider] için `overrideWithValue` kullanır; böylece ekranlar
/// senkron değerlere bakar ve testler kolayca sahte veri verebilir.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'core/date_utils.dart';
import 'data/db/daos/settings_dao.dart';
import 'data/db/database.dart';
import 'data/platform/platform_bridge.dart';
import 'data/repositories/item_list_repo.dart';
import 'data/repositories/item_repo.dart';
import 'data/repositories/log_repo.dart';
import 'data/repositories/settings_repo.dart';
import 'data/repositories/trip_repo.dart';
import 'data/repositories/vehicle_repo.dart';
import 'data/seed/seed_loader.dart';
import 'domain/item_grouping.dart';
import 'domain/models/check_item.dart';
import 'domain/models/check_log.dart';
import 'domain/models/rules.dart';
import 'domain/models/trip.dart';
import 'domain/models/vehicle.dart';
import 'domain/snapshot_builder.dart';
import 'domain/status_calculator.dart';

// ---------------------------------------------------------------- altyapı

/// `main.dart` gerçek örnekle override eder.
final Provider<AppDatabase> databaseProvider = Provider<AppDatabase>(
  (Ref ref) => throw UnimplementedError('databaseProvider override edilmeli'),
);

/// `main.dart` yüklenmiş şablonla override eder.
final Provider<Seed> seedProvider = Provider<Seed>(
  (Ref ref) => throw UnimplementedError('seedProvider override edilmeli'),
);

final Provider<PlatformBridge> platformBridgeProvider =
    Provider<PlatformBridge>((Ref ref) => PlatformBridge());

// -------------------------------------------------------------- depolar

final Provider<VehicleRepo> vehicleRepoProvider = Provider<VehicleRepo>(
  (Ref ref) => VehicleRepo(ref.watch(databaseProvider)),
);

final Provider<ItemRepo> itemRepoProvider = Provider<ItemRepo>(
  (Ref ref) => ItemRepo(ref.watch(databaseProvider)),
);

final Provider<ItemListRepo> itemListRepoProvider = Provider<ItemListRepo>(
  (Ref ref) => ItemListRepo(ref.watch(databaseProvider)),
);

final Provider<SettingsRepo> settingsRepoProvider = Provider<SettingsRepo>(
  (Ref ref) => SettingsRepo(ref.watch(databaseProvider)),
);

final Provider<LogRepo> logRepoProvider = Provider<LogRepo>(
  (Ref ref) => LogRepo(ref.watch(databaseProvider)),
);

final Provider<TripRepo> tripRepoProvider = Provider<TripRepo>(
  (Ref ref) => TripRepo(ref.watch(databaseProvider)),
);

// ---------------------------------------------------------------- veri

final StreamProvider<Vehicle?> vehicleProvider = StreamProvider<Vehicle?>(
  (Ref ref) => ref.watch(vehicleRepoProvider).watch(),
);

final StreamProvider<List<CheckItem>> itemsProvider =
    StreamProvider<List<CheckItem>>((Ref ref) {
      final Vehicle? vehicle = ref.watch(vehicleProvider).valueOrNull;
      if (vehicle == null) {
        return Stream<List<CheckItem>>.value(const <CheckItem>[]);
      }
      return ref.watch(itemListRepoProvider).watchAll(vehicle.id);
    });

/// Geçmiş ekranı ve madde detayı buna bakar (denetim md. "gecmis-ekrani-veri-yolu-yok").
final StreamProvider<List<CheckLog>> logsProvider =
    StreamProvider<List<CheckLog>>(
      (Ref ref) => ref.watch(logRepoProvider).watchAll(),
    );

final StreamProvider<Rules> rulesProvider = StreamProvider<Rules>(
  (Ref ref) => ref.watch(settingsRepoProvider).watchRules(),
);

/// `settings.install_day`. Kurulum bitene kadar null.
/// `main.dart` açılışta okuduğu değerle override eder; kurulum bitince
/// [SetupController] `invalidate` ile tazeler.
final StateProvider<DateTime?> installDayProvider = StateProvider<DateTime?>(
  (Ref ref) => null,
);

/// Yerel takvim günü. Test için override edilebilir; `resume`'da tazelenir
/// (02-mimari §9, gece yarısı geçişi).
final StateProvider<DateTime> todayProvider = StateProvider<DateTime>(
  (Ref ref) => dateOnly(DateTime.now()),
);

// -------------------------------------------------------------- türetilmiş

/// Her madde ve hesaplanmış durumu (K-04: hesap yalnız `StatusCalculator`'da).
final Provider<List<StatusedItem>> statusesProvider =
    Provider<List<StatusedItem>>((Ref ref) {
      final Vehicle? vehicle = ref.watch(vehicleProvider).valueOrNull;
      final List<CheckItem> items =
          ref.watch(itemsProvider).valueOrNull ?? const <CheckItem>[];
      final DateTime today = ref.watch(todayProvider);
      final DateTime? installDay = ref.watch(installDayProvider);
      if (vehicle == null || installDay == null) {
        return const <StatusedItem>[];
      }
      return <StatusedItem>[
        for (final CheckItem item in items)
          (
            item: item,
            status: StatusCalculator.compute(
              item: item,
              currentKm: vehicle.currentKm,
              installDay: installDay,
              today: today,
            ),
          ),
      ];
    });

/// Ana ekranın bölümleri (K-17 sıralaması).
final Provider<GroupedItems> groupedItemsProvider = Provider<GroupedItems>(
  (Ref ref) => groupForHome(ref.watch(statusesProvider)),
);

// ------------------------------------------------------------- yaşam döngüsü

/// İzin durumları; `resume`'da tazelenir.
class PermissionState {
  const PermissionState({
    required this.bluetooth,
    required this.notification,
    required this.notificationsEnabled,
    required this.batteryIgnored,
    required this.bluetoothEnabled,
    this.bluetoothBlocked = false,
    this.notificationBlocked = false,
    this.motionAvailable = false,
    this.motionPermission = false,
    this.motionActive = false,
    this.motionLastAt,
  });

  static const PermissionState unknown = PermissionState(
    bluetooth: false,
    notification: false,
    notificationsEnabled: true,
    batteryIgnored: false,
    bluetoothEnabled: false,
  );

  final bool bluetooth;
  final bool notification;

  /// 01-spec §9: bir kez soruldu, verilmedi ve sistem artık gerekçe
  /// göstermeyecek → "bir daha sorma". Tek çıkış sistem ayarları.
  final bool bluetoothBlocked;
  final bool notificationBlocked;

  /// Kanal kullanıcı tarafından kapatılmış mı (07 §8).
  final bool notificationsEnabled;
  final bool batteryIgnored;

  /// Adaptör açık mı (T05 cihaz testi bulgusu).
  final bool bluetoothEnabled;

  /// K-30: Play Services var mı; hareket izni verildi mi; abonelik kurulu mu.
  final bool motionAvailable;
  final bool motionPermission;
  final bool motionActive;

  /// K-35: motorun gördüğü son araç hareketi; hiç görülmediyse null.
  final DateTime? motionLastAt;

  PermissionState copyWith({
    bool? bluetooth,
    bool? notification,
    bool? notificationsEnabled,
    bool? batteryIgnored,
    bool? bluetoothEnabled,
    bool? bluetoothBlocked,
    bool? notificationBlocked,
    bool? motionAvailable,
    bool? motionPermission,
    bool? motionActive,
    DateTime? motionLastAt,
  }) {
    return PermissionState(
      bluetooth: bluetooth ?? this.bluetooth,
      notification: notification ?? this.notification,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      batteryIgnored: batteryIgnored ?? this.batteryIgnored,
      bluetoothEnabled: bluetoothEnabled ?? this.bluetoothEnabled,
      bluetoothBlocked: bluetoothBlocked ?? this.bluetoothBlocked,
      notificationBlocked: notificationBlocked ?? this.notificationBlocked,
      motionAvailable: motionAvailable ?? this.motionAvailable,
      motionPermission: motionPermission ?? this.motionPermission,
      motionActive: motionActive ?? this.motionActive,
      motionLastAt: motionLastAt ?? this.motionLastAt,
    );
  }
}

class _MotionPermissions {
  const _MotionPermissions({
    required this.available,
    required this.permission,
    required this.active,
    required this.lastAt,
  });

  final bool available;
  final bool permission;
  final bool active;
  final DateTime? lastAt;
}

class PermissionsNotifier extends Notifier<PermissionState> {
  bool _disposed = false;

  @override
  PermissionState build() {
    ref.onDispose(() => _disposed = true);
    return PermissionState.unknown;
  }

  Future<void> refresh() async {
    if (_disposed) {
      return;
    }
    final PlatformBridge bridge = ref.read(platformBridgeProvider);
    try {
      final bool bt = await bridge.hasBluetoothPermission();
      final bool notif = await bridge.hasNotificationPermission();
      final PermissionState next = PermissionState(
        bluetooth: bt,
        notification: notif,
        notificationsEnabled: await bridge.areNotificationsEnabled(),
        batteryIgnored: await bridge.isIgnoringBatteryOptimizations(),
        bluetoothEnabled: await bridge.isBluetoothEnabled(),
        bluetoothBlocked: await _blocked(
          granted: bt,
          which: 'bluetooth',
          askedKey: SettingKeys.askedBluetooth,
        ),
        notificationBlocked: await _blocked(
          granted: notif,
          which: 'notification',
          askedKey: SettingKeys.askedNotification,
        ),
        motionAvailable: state.motionAvailable,
        motionPermission: state.motionPermission,
        motionActive: state.motionActive,
        motionLastAt: state.motionLastAt,
      );
      if (!_disposed) {
        state = next;
      }
    } on Object {
      // Kanal yoksa (test/masaüstü) varsayılanda kal.
    }
    // K-30 en sonda ve ayrı korumada: hareket katmanı (Play Services) yavaş
    // olabilir veya hiç olmayabilir; şeritleri bekletmemeli, düşürmemeli.
    final _MotionPermissions motion = await _readMotion(bridge);
    if (!_disposed) {
      state = state.copyWith(
        motionAvailable: motion.available,
        motionPermission: motion.permission,
        motionActive: motion.active,
        motionLastAt: motion.lastAt,
      );
    }
  }

  /// K-30/K-35 dörtlüsü; kanal metodu yoksa hepsi boş.
  Future<_MotionPermissions> _readMotion(PlatformBridge bridge) async {
    try {
      final ({bool active, DateTime? lastAt}) motion =
          await bridge.getMotionState();
      return _MotionPermissions(
        available: await bridge.isMotionAvailable(),
        permission: await bridge.hasMotionPermission(),
        active: motion.active,
        lastAt: motion.lastAt,
      );
    } on Object {
      return const _MotionPermissions(
        available: false,
        permission: false,
        active: false,
        lastAt: null,
      );
    }
  }

  /// Soruldu + verilmedi + sistem gerekçe göstermeyecek → kalıcı ret.
  /// "Soruldu mu" olmadan ilk açılışta da kalıcı ret görünürdü.
  Future<bool> _blocked({
    required bool granted,
    required String which,
    required String askedKey,
  }) async {
    if (granted) {
      return false;
    }
    if (!await ref.read(settingsRepoProvider).permissionAsked(askedKey)) {
      return false;
    }
    return !await ref
        .read(platformBridgeProvider)
        .shouldShowPermissionRationale(which);
  }

  /// İzin isteme tek yerden: "soruldu" işareti burada yazılır.
  Future<void> requestBluetooth() =>
      _request(SettingKeys.askedBluetooth, (PlatformBridge b) =>
          b.requestBluetoothPermission());

  Future<void> requestNotification() =>
      _request(SettingKeys.askedNotification, (PlatformBridge b) =>
          b.requestNotificationPermission());

  /// K-30. Dönen değer: abonelik gerçekten kuruldu mu. Kural yalnız `true`
  /// gelirse açılır; aksi halde kural açık kalıp bildirimleri yutardı.
  Future<bool> enableMotion() async {
    final PlatformBridge bridge = ref.read(platformBridgeProvider);
    try {
      if (!await bridge.isMotionAvailable()) {
        return false;
      }
      if (!await bridge.hasMotionPermission()) {
        await _request(
          SettingKeys.askedMotion,
          (PlatformBridge b) => b.requestMotionPermission(),
        );
        if (!await bridge.hasMotionPermission()) {
          return false;
        }
      }
      final bool ok = await bridge.setMotionUpdates(enabled: true);
      await refresh();
      return ok;
    } on Object {
      return false;
    }
  }

  Future<void> disableMotion() async {
    try {
      await ref.read(platformBridgeProvider).setMotionUpdates(enabled: false);
    } on Object {
      // Kanal yoksa sessiz.
    }
    await refresh();
  }

  /// Açılışta/`resume`'da aboneliği tazeler: yeniden başlatma veya
  /// "force stop" aboneliği düşürebiliyor, kural açık kalıyor.
  ///
  /// Dönen değer: kural açık kalabilir mi. `false` ise izin ya da Play
  /// Hizmetleri gitmiştir; çağıran taraf kuralı kapatır, yoksa anahtar açık
  /// görünüp motor doğrulamayı atlıyor olurdu (cihaz testi bulgusu).
  Future<bool> ensureMotion() async {
    try {
      final PlatformBridge bridge = ref.read(platformBridgeProvider);
      if (!await bridge.isMotionAvailable() ||
          !await bridge.hasMotionPermission()) {
        return false;
      }
      await bridge.setMotionUpdates(enabled: true);
      return true;
    } on Object {
      // Kanal yoksa (test/masaüstü) kurala dokunma.
      return true;
    }
  }

  Future<void> _request(
    String askedKey,
    Future<bool> Function(PlatformBridge) ask,
  ) async {
    await ref.read(settingsRepoProvider).markPermissionAsked(askedKey);
    try {
      await ask(ref.read(platformBridgeProvider));
    } on Object {
      // Kanal yoksa sessiz; `refresh` durumu yine okur.
    }
    await refresh();
  }

  /// Kalıcı retten çıkış yolu (01-spec §9).
  Future<void> openSystemSettings() async {
    try {
      await ref.read(platformBridgeProvider).openAppSettings();
    } on Object {
      // Kanal yoksa sessiz.
    }
  }
}

final NotifierProvider<PermissionsNotifier, PermissionState>
permissionsProvider =
    NotifierProvider<PermissionsNotifier, PermissionState>(
      PermissionsNotifier.new,
    );

/// Bluetooth durumu; `resume`'da ve açılışta tazelenir (02-mimari §9).
class BluetoothStateNotifier extends Notifier<BluetoothState> {
  bool _disposed = false;

  @override
  BluetoothState build() {
    ref.onDispose(() => _disposed = true);
    return BluetoothState.unknown;
  }

  Future<void> refresh() async {
    if (_disposed) {
      return;
    }
    try {
      final BluetoothState next = await ref
          .read(platformBridgeProvider)
          .getBluetoothState();
      if (!_disposed) {
        state = next;
      }
    } on Object {
      // Kanal yoksa (test) varsayılanda kal.
    }
  }
}

final NotifierProvider<BluetoothStateNotifier, BluetoothState>
bluetoothStateProvider =
    NotifierProvider<BluetoothStateNotifier, BluetoothState>(
      BluetoothStateNotifier.new,
    );

/// Ayarlar tanı satırının kaynağı: prefs değil `trips` tablosu (01-spec §3.7,
/// T13). Kotlin'in prefs'teki kopyası yalnız motor için.
final StreamProvider<Trip?> lastTripProvider = StreamProvider<Trip?>(
  (Ref ref) => ref.watch(tripRepoProvider).watchLastTrip(),
);

/// Bildirime dokunularak açıldıysa `overdue` (01-spec §3.8).
final StateProvider<String?> launchActionProvider = StateProvider<String?>(
  (Ref ref) => null,
);

/// Her bildirim dokunuşunda artar. Vurgu animasyonu tek seferlik olduğu için
/// aynı değer ikinci kez gelince tekrar oynaması bu sayaçla sağlanıyor.
final StateProvider<int> launchActionSeqProvider = StateProvider<int>(
  (Ref ref) => 0,
);

// ------------------------------------------------------------ snapshot

/// Debounce süresi; test bunu `Duration.zero` ile override eder.
final Provider<Duration> snapshotDebounceProvider = Provider<Duration>(
  (Ref ref) => kSnapshotDebounce,
);

/// Durum veya kural değişince snapshot'ı Kotlin'e yazar (01-spec §6,
/// 02-mimari §9). `main.dart` bunu okuyup ayakta tutar.
///
/// T11'de asgari hâliyle kuruldu (Ayarlar'ın kabul kriteri `readSnapshot`
/// istiyor); kalan tetikleyiciler ve `resume` bağlantısı T15'te.
class SnapshotSync {
  SnapshotSync(this._ref);

  final Ref _ref;
  Timer? _timer;
  bool _disposed = false;

  /// Yalnız test için: kaç kez yazıldı.
  int writeCount = 0;

  /// K-27: gecikmiş sayısı >0'dan 0'a düştüğünde tepsideki bildirim iptal
  /// edilir. `null` = henüz gözlemlenmedi (açılışta iptal etmeyelim).
  int? _lastOverdueCount;

  void schedule() {
    if (_disposed) {
      return;
    }
    _timer?.cancel();
    _timer = Timer(_ref.read(snapshotDebounceProvider), write);
  }

  Future<void> write() async {
    if (_disposed) {
      return;
    }
    final Vehicle? vehicle = _ref.read(vehicleProvider).valueOrNull;
    final DateTime? installDay = _ref.read(installDayProvider);
    if (vehicle == null || installDay == null) {
      return;
    }
    final String json = SnapshotBuilder.buildJson(
      vehicle: vehicle,
      items: _ref.read(itemsProvider).valueOrNull ?? const <CheckItem>[],
      rules: _ref.read(rulesProvider).valueOrNull ?? Rules.defaults,
      installDay: installDay,
      today: _ref.read(todayProvider),
      generatedAt: DateTime.now(),
    );
    writeCount++;
    try {
      await _ref.read(platformBridgeProvider).writeSnapshot(json);
    } on Object {
      // 01-spec §9: sessiz; bir sonraki tetikleyicide tekrar denenir.
    }
    await _cancelIfNothingOverdue();
  }

  /// K-27. Kullanıcı gecikmişleri kaydedince tepsideki bildirim anlamsız
  /// kalıyordu; ertelemede de öyle (motor artık onları bildirmez).
  Future<void> _cancelIfNothingOverdue() async {
    final int count = engineOverdue(
      _ref.read(statusesProvider),
      _ref.read(todayProvider),
    ).length;
    final int? previous = _lastOverdueCount;
    _lastOverdueCount = count;
    // Yalnız **geçişte** iptal: açılışta zaten 0 ise dokunmuyoruz, aksi halde
    // az önce basılmış bir bildirimi silebilirdik.
    if (previous == null || previous == 0 || count != 0) {
      return;
    }
    try {
      await _ref.read(platformBridgeProvider).cancelNotification();
    } on Object {
      // Kanal yoksa sessiz.
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
  }
}

final Provider<SnapshotSync> snapshotSyncProvider = Provider<SnapshotSync>((
  Ref ref,
) {
  final SnapshotSync sync = SnapshotSync(ref);
  ref.onDispose(sync.dispose);
  // 01-spec §6'nın tetikleyicileri. Kayıt/silme/düzeltme/km/madde değişikliği
  // `statusesProvider` üzerinden gelir; araç ve cihaz değişikliği snapshot'ın
  // `car` bloğunu değiştirdiği için ayrıca dinleniyor (durum aynı kalabilir).
  ref.listen(statusesProvider, (_, _) => sync.schedule(), fireImmediately: true);
  ref.listen(rulesProvider, (_, _) => sync.schedule());
  ref.listen(vehicleProvider, (_, _) => sync.schedule());
  ref.keepAlive();
  return sync;
});

/// Toast'ları tek yerden göstermek için (widget'lar iş mantığı taşımasın).
final Provider<GlobalKey<ScaffoldMessengerState>> scaffoldMessengerKeyProvider =
    Provider<GlobalKey<ScaffoldMessengerState>>(
      (Ref ref) => GlobalKey<ScaffoldMessengerState>(),
    );
