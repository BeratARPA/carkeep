import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_utils.dart';
import '../../core/format_tr.dart';
import '../../core/strings_tr.dart';
import '../../data/platform/device_list.dart';
import '../../data/platform/platform_bridge.dart';
import '../../data/repositories/item_list_repo.dart';
import '../../data/repositories/item_repo.dart';
import '../../data/repositories/settings_repo.dart';
import '../../data/repositories/vehicle_repo.dart';
import '../../data/seed/seed_loader.dart';
import '../../domain/models/check_item.dart';
import '../../providers.dart';

/// Kurulum sihirbazının toplam adım sayısı (01-spec §3.1).
const int kSetupStepCount = 6;

/// Cihaz listesinin durumu (01-spec §3.1 adım 4 + T05 bulgusu).
class SetupState {
  const SetupState({
    this.step = 1,
    this.brand = '',
    this.model = '',
    this.year = '',
    this.km = '',
    this.permissions = PermissionState.unknown,
    this.devices = const <BondedDevice>[],
    this.deviceListState = DeviceListState.loading,
    this.selectedAddress,
    this.selectedName,
    this.lastServiceDate,
    this.lastServiceKm = '',
    this.lastServiceDateRaw = false,
    this.enabledByKey = const <String, bool>{},
    this.error,
    this.submitting = false,
    this.finished = false,
  });

  /// 1..6
  final int step;

  final String brand;
  final String model;
  final String year;
  final String km;

  final PermissionState permissions;

  final List<BondedDevice> devices;
  final DeviceListState deviceListState;
  final String? selectedAddress;
  final String? selectedName;

  final DateTime? lastServiceDate;
  final String lastServiceKm;

  /// Kullanıcı tarih alanlarına bir şey yazdı ama geçerli tarih çıkmadı.
  final bool lastServiceDateRaw;

  /// `template_key` → açık mı (6. adım).
  final Map<String, bool> enabledByKey;

  /// Doğrulama uyarısı; gösterildikten sonra [clearError] ile temizlenir.
  final String? error;

  final bool submitting;
  final bool finished;

  bool get isFirstStep => step == 1;
  bool get isLastStep => step == kSetupStepCount;

  SetupState copyWith({
    int? step,
    String? brand,
    String? model,
    String? year,
    String? km,
    PermissionState? permissions,
    List<BondedDevice>? devices,
    DeviceListState? deviceListState,
    Object? selectedAddress = _sentinel,
    Object? selectedName = _sentinel,
    Object? lastServiceDate = _sentinel,
    String? lastServiceKm,
    bool? lastServiceDateRaw,
    Map<String, bool>? enabledByKey,
    Object? error = _sentinel,
    bool? submitting,
    bool? finished,
  }) {
    return SetupState(
      step: step ?? this.step,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      km: km ?? this.km,
      permissions: permissions ?? this.permissions,
      devices: devices ?? this.devices,
      deviceListState: deviceListState ?? this.deviceListState,
      selectedAddress: selectedAddress == _sentinel
          ? this.selectedAddress
          : selectedAddress as String?,
      selectedName: selectedName == _sentinel
          ? this.selectedName
          : selectedName as String?,
      lastServiceDate: lastServiceDate == _sentinel
          ? this.lastServiceDate
          : lastServiceDate as DateTime?,
      lastServiceKm: lastServiceKm ?? this.lastServiceKm,
      lastServiceDateRaw: lastServiceDateRaw ?? this.lastServiceDateRaw,
      enabledByKey: enabledByKey ?? this.enabledByKey,
      error: error == _sentinel ? this.error : error as String?,
      submitting: submitting ?? this.submitting,
      finished: finished ?? this.finished,
    );
  }

  static const Object _sentinel = Object();
}

class SetupController extends Notifier<SetupState> {
  bool _disposed = false;

  @override
  SetupState build() {
    final Seed seed = ref.watch(seedProvider);
    ref.onDispose(() => _disposed = true);
    return SetupState(
      enabledByKey: <String, bool>{
        for (final SeedItem i in seed.items) i.id: i.enabledByDefault,
      },
    );
  }

  // --------------------------------------------------------------- alanlar

  void setBrand(String v) => state = state.copyWith(brand: v);
  void setModel(String v) => state = state.copyWith(model: v);
  void setYear(String v) => state = state.copyWith(year: v);
  void setKm(String v) => state = state.copyWith(km: v);
  void setLastServiceKm(String v) => state = state.copyWith(lastServiceKm: v);

  void setLastServiceDate(DateTime? date, {required bool touched}) {
    state = state.copyWith(
      lastServiceDate: date,
      lastServiceDateRaw: touched && date == null,
    );
  }

  void toggleItem(String templateKey, bool enabled) {
    state = state.copyWith(
      enabledByKey: <String, bool>{...state.enabledByKey, templateKey: enabled},
    );
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  // -------------------------------------------------------------- izinler

  Future<void> refreshPermissions() async {
    if (_disposed) {
      return;
    }
    await ref.read(permissionsProvider.notifier).refresh();
    if (_disposed) {
      return;
    }
    state = state.copyWith(permissions: ref.read(permissionsProvider));
  }

  Future<void> requestBluetooth() async {
    await ref.read(platformBridgeProvider).requestBluetoothPermission();
    await refreshPermissions();
    if (state.step == 4 || state.permissions.bluetooth) {
      await loadDevices();
    }
  }

  Future<void> requestNotification() async {
    await ref.read(platformBridgeProvider).requestNotificationPermission();
    await refreshPermissions();
  }

  Future<void> openBatterySettings() async {
    await ref.read(platformBridgeProvider).openBatteryOptimizationSettings();
  }

  // --------------------------------------------------------------- cihazlar

  Future<void> loadDevices() async {
    state = state.copyWith(deviceListState: DeviceListState.loading);
    final DeviceListResult r = await loadBondedDevices(
      ref.read(platformBridgeProvider),
    );
    if (_disposed) {
      return;
    }
    state = state.copyWith(devices: r.devices, deviceListState: r.state);
  }

  void selectDevice(BondedDevice device) {
    state = state.copyWith(
      selectedAddress: device.address,
      selectedName: device.displayName,
    );
  }

  void clearDevice() {
    state = state.copyWith(
      selectedAddress: null,
      selectedName: null,
    );
  }

  // ----------------------------------------------------------------- akış

  void back() {
    if (state.step > 1) {
      state = state.copyWith(step: state.step - 1, error: null);
    }
  }

  /// Zorunlu alan eksikse `false` döner ve [SetupState.error] dolar.
  bool next() {
    final String? problem = validateStep(state);
    if (problem != null) {
      state = state.copyWith(error: problem);
      return false;
    }
    if (state.step < kSetupStepCount) {
      final int nextStep = state.step + 1;
      state = state.copyWith(step: nextStep, error: null);
      if (nextStep == 4) {
        Future<void>.microtask(loadDevices);
      }
      if (nextStep == 3) {
        Future<void>.microtask(refreshPermissions);
      }
    }
    return true;
  }

  /// Adım doğrulaması; saf tutuldu ki widget olmadan sınanabilsin.
  static String? validateStep(SetupState s) {
    switch (s.step) {
      case 1:
        return s.brand.trim().isEmpty ? S.errBrandRequired : null;
      case 2:
        final int? km = parseKm(s.km);
        return (km == null || km < 0) ? S.errKmRequired : null;
      case 5:
        // İkisi birlikte ya da ikisi de boş.
        final bool hasDate = s.lastServiceDate != null;
        final bool touchedDate = s.lastServiceDateRaw;
        final int? km = parseKm(s.lastServiceKm);
        final bool hasKm = km != null;
        if (!hasDate && !hasKm && !touchedDate) {
          return null;
        }
        if (hasDate && hasKm) {
          return null;
        }
        return S.errServiceIncomplete;
      default:
        return null;
    }
  }

  // ---------------------------------------------------------------- bitiş

  /// "Başla": araç + maddeler + ayarlar tek transaction, sonra snapshot ve
  /// günlük iş (01-spec §3.1).
  Future<bool> finish() async {
    // Tek araç (K-01): bitmis kurulum ikinci kez yazilmaz.
    if (state.submitting || state.finished) {
      return false;
    }
    final String? problem = validateStep(state);
    if (problem != null) {
      state = state.copyWith(error: problem);
      return false;
    }
    state = state.copyWith(submitting: true, error: null);

    try {
      final Seed seed = ref.read(seedProvider);
      final VehicleRepo vehicles = ref.read(vehicleRepoProvider);
      final ItemRepo items = ref.read(itemRepoProvider);
      final SettingsRepo settings = ref.read(settingsRepoProvider);
      final DateTime today = ref.read(todayProvider);

      final int km = parseKm(state.km) ?? 0;
      final int vehicleId = await vehicles.create(
        brand: state.brand.trim(),
        model: state.model.trim(),
        year: state.year.trim(),
        currentKm: km,
        createdAt: DateTime.now(),
        btAddress: state.selectedAddress,
        btName: state.selectedName,
      );

      await items.installSeed(vehicleId, seed);
      await settings.setInstallDay(today);

      // 6. adımdaki aç/kapat seçimleri.
      final List<CheckItem> inserted = await ref
          .read(itemListRepoProvider)
          .getAll(vehicleId);
      final Map<int, bool> flags = <int, bool>{};
      for (final CheckItem item in inserted) {
        final String? key = item.templateKey;
        if (key == null) {
          continue;
        }
        final bool wanted = state.enabledByKey[key] ?? item.enabled;
        if (wanted != item.enabled) {
          flags[item.id] = wanted;
        }
      }
      await ref.read(databaseProvider).applyEnabledFlags(flags);

      // 5. adım: `appliesLastService` maddelerinin son yapılışı.
      final DateTime? serviceDate = state.lastServiceDate;
      final int? serviceKm = parseKm(state.lastServiceKm);
      if (serviceDate != null && serviceKm != null) {
        for (final CheckItem item in inserted) {
          if (item.appliesLastService) {
            await ref
                .read(itemListRepoProvider)
                .setLastDone(
                  item.id,
                  day: dayKey(serviceDate),
                  km: serviceKm,
                );
          }
        }
      }

      ref.read(installDayProvider.notifier).state = today;
      // `vehicleProvider` bir Drift akisi; insert kendiliginde yayilir
      // (02-mimari §12), ayrica invalidate gerekmiyor.

      // Snapshot ve günlük iş; kanal yoksa (test) sessizce geç.
      try {
        await ref.read(platformBridgeProvider).scheduleDailyWorker();
      } on Object {
        // T15 açılış sırası bunu tekrar dener.
      }

      state = state.copyWith(submitting: false, finished: true);
      return true;
    } on Object {
      state = state.copyWith(submitting: false, error: S.errGeneric);
      return false;
    }
  }
}

final NotifierProvider<SetupController, SetupState> setupControllerProvider =
    NotifierProvider<SetupController, SetupState>(SetupController.new);
