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
import 'data/db/database.dart';
import 'data/platform/platform_bridge.dart';
import 'data/repositories/item_list_repo.dart';
import 'data/repositories/item_repo.dart';
import 'data/repositories/log_repo.dart';
import 'data/repositories/settings_repo.dart';
import 'data/repositories/vehicle_repo.dart';
import 'data/seed/seed_loader.dart';
import 'domain/item_grouping.dart';
import 'domain/models/check_item.dart';
import 'domain/models/check_log.dart';
import 'domain/models/rules.dart';
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

  /// Kanal kullanıcı tarafından kapatılmış mı (07 §8).
  final bool notificationsEnabled;
  final bool batteryIgnored;

  /// Adaptör açık mı (T05 cihaz testi bulgusu).
  final bool bluetoothEnabled;

  PermissionState copyWith({
    bool? bluetooth,
    bool? notification,
    bool? notificationsEnabled,
    bool? batteryIgnored,
    bool? bluetoothEnabled,
  }) {
    return PermissionState(
      bluetooth: bluetooth ?? this.bluetooth,
      notification: notification ?? this.notification,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      batteryIgnored: batteryIgnored ?? this.batteryIgnored,
      bluetoothEnabled: bluetoothEnabled ?? this.bluetoothEnabled,
    );
  }
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
      final PermissionState next = PermissionState(
        bluetooth: await bridge.hasBluetoothPermission(),
        notification: await bridge.hasNotificationPermission(),
        notificationsEnabled: await bridge.areNotificationsEnabled(),
        batteryIgnored: await bridge.isIgnoringBatteryOptimizations(),
        bluetoothEnabled: await bridge.isBluetoothEnabled(),
      );
      if (!_disposed) {
        state = next;
      }
    } on Object {
      // Kanal yoksa (test/masaüstü) varsayılanda kal.
    }
  }
}

final NotifierProvider<PermissionsNotifier, PermissionState>
permissionsProvider =
    NotifierProvider<PermissionsNotifier, PermissionState>(
      PermissionsNotifier.new,
    );

/// Bildirime dokunularak açıldıysa `overdue` (01-spec §3.8).
final StateProvider<String?> launchActionProvider = StateProvider<String?>(
  (Ref ref) => null,
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
  ref.listen(statusesProvider, (_, _) => sync.schedule(), fireImmediately: true);
  ref.listen(rulesProvider, (_, _) => sync.schedule());
  ref.keepAlive();
  return sync;
});

/// Toast'ları tek yerden göstermek için (widget'lar iş mantığı taşımasın).
final Provider<GlobalKey<ScaffoldMessengerState>> scaffoldMessengerKeyProvider =
    Provider<GlobalKey<ScaffoldMessengerState>>(
      (Ref ref) => GlobalKey<ScaffoldMessengerState>(),
    );
