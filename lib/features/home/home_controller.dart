import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format_tr.dart';
import '../../core/strings_tr.dart';
import '../../data/platform/platform_bridge.dart';
import '../../domain/models/check_item.dart';
import '../../domain/models/item_status.dart';
import '../../domain/models/schedule.dart';
import '../../domain/models/vehicle.dart';
import '../../providers.dart';

/// Ana ekranın hangi uyarı şeridini göstereceği (01-spec §3.2).
enum HomeBanner { noBluetooth, noNotification, noDevice, battery }

/// Alt sekmeler (01-spec §3.2).
enum HomeTab { home, history, settings }

final NotifierProvider<HomeTabNotifier, HomeTab> homeTabProvider =
    NotifierProvider<HomeTabNotifier, HomeTab>(HomeTabNotifier.new);

class HomeTabNotifier extends Notifier<HomeTab> {
  @override
  HomeTab build() => HomeTab.home;

  void select(HomeTab tab) => state = tab;
}

/// Pil şeridi kapatıldı mı; `settings.battery_banner_dismissed`.
class BatteryBannerNotifier extends Notifier<bool> {
  @override
  bool build() {
    Future<void>.microtask(_load);
    return false;
  }

  Future<void> _load() async {
    final bool dismissed = await ref
        .read(settingsRepoProvider)
        .batteryBannerDismissed();
    state = dismissed;
  }

  Future<void> dismiss() async {
    state = true;
    await ref.read(settingsRepoProvider).dismissBatteryBanner();
  }
}

final NotifierProvider<BatteryBannerNotifier, bool>
batteryBannerDismissedProvider =
    NotifierProvider<BatteryBannerNotifier, bool>(BatteryBannerNotifier.new);

/// Gösterilecek şeritler, sırayla (01-spec §3.2).
final Provider<List<HomeBanner>> homeBannersProvider =
    Provider<List<HomeBanner>>((Ref ref) {
      final PermissionState p = ref.watch(permissionsProvider);
      final Vehicle? vehicle = ref.watch(vehicleProvider).valueOrNull;
      final bool batteryDismissed = ref.watch(batteryBannerDismissedProvider);

      return <HomeBanner>[
        if (!p.bluetooth) HomeBanner.noBluetooth,
        if (!p.notification) HomeBanner.noNotification,
        if (vehicle != null && !vehicle.hasDevice) HomeBanner.noDevice,
        if (!p.batteryIgnored && !batteryDismissed) HomeBanner.battery,
      ];
    });

String bannerText(HomeBanner banner) => switch (banner) {
  HomeBanner.noBluetooth => S.bannerNoBluetooth,
  HomeBanner.noNotification => S.bannerNoNotification,
  HomeBanner.noDevice => S.bannerNoDevice,
  HomeBanner.battery => S.bannerBattery,
};

/// Yalnız pil şeridi kapatılabilir (01-spec §3.2).
bool bannerDismissible(HomeBanner banner) => banner == HomeBanner.battery;

/// Bluetooth chip metni: `Uconnect bağlı, sürüşte` / `Uconnect bağlı değil`.
/// Cihaz seçilmemişse `Araba seçilmedi`.
String bluetoothChipText({
  required String? deviceName,
  required bool connected,
}) {
  if (deviceName == null || deviceName.isEmpty) {
    return S.chipNoDevice;
  }
  return connected
      ? '$deviceName ${S.chipConnectedSuffix}'
      : '$deviceName ${S.chipDisconnectedSuffix}';
}

/// Liste satırının alt metni (01-spec §3.2). Takvim türüne göre km'nin yeri
/// değişir; son yapılış yoksa K-18 metni.
String itemSubtitle(CheckItem item, {required int refYear}) {
  final bool isKmOnly = item.schedule.kind == ScheduleKind.km;
  final bool isBoth = item.schedule.kind == ScheduleKind.both;
  return lastDoneText(
    day: item.lastDoneDay,
    km: item.lastDoneKm,
    value: item.lastValue,
    showKm: isKmOnly || isBoth,
    kmFirst: isKmOnly,
    refYear: refYear,
  );
}

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

/// Bölüm başlığı metni ve sayısı.
String sectionTitle(ItemState state, int count) {
  final String label = switch (state) {
    ItemState.overdue => S.sectionOverdue,
    ItemState.soon => S.sectionSoon,
    ItemState.ok => S.sectionOk,
    ItemState.unknown => S.sectionUnknown,
  };
  return '$label ($count)';
}
