import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/platform/device_list.dart';
import '../../data/platform/platform_bridge.dart';
import '../../domain/models/measure.dart';
import '../../domain/models/rules.dart';
import '../../domain/models/schedule.dart';
import '../../providers.dart';

/// Cihaz seçicinin durumu (01-spec §3.7). Kurulumdaki listeyle aynı kuralları
/// kullanır; farkı, seçim anında DB'ye yazılması.
class DevicePickerState {
  const DevicePickerState({required this.listState, required this.devices});

  static const DevicePickerState loading = DevicePickerState(
    listState: DeviceListState.loading,
    devices: <BondedDevice>[],
  );

  final DeviceListState listState;
  final List<BondedDevice> devices;
}

class DevicePickerNotifier extends Notifier<DevicePickerState> {
  bool _disposed = false;

  @override
  DevicePickerState build() {
    ref.onDispose(() => _disposed = true);
    return DevicePickerState.loading;
  }

  Future<void> load() async {
    if (_disposed) {
      return;
    }
    state = DevicePickerState.loading;
    final DeviceListResult r = await loadBondedDevices(
      ref.read(platformBridgeProvider),
    );
    if (_disposed) {
      return;
    }
    state = DevicePickerState(listState: r.state, devices: r.devices);
  }

  Future<void> requestPermission() async {
    await ref.read(permissionsProvider.notifier).requestBluetooth();
    await load();
  }
}

final NotifierProvider<DevicePickerNotifier, DevicePickerState>
devicePickerProvider =
    NotifierProvider<DevicePickerNotifier, DevicePickerState>(
      DevicePickerNotifier.new,
    );

/// `settings.template_version`; "Şablon sürümü 1" satırı.
final FutureProvider<int?> templateVersionProvider = FutureProvider<int?>(
  (Ref ref) => ref.watch(settingsRepoProvider).templateVersion(),
);

/// Ayarlar ekranının yazma işlemleri. Ekran iş mantığı taşımaz (CLAUDE.md).
class SettingsController {
  const SettingsController(this._ref);

  final Ref _ref;

  // ---------------------------------------------------------------- araç

  Future<void> updateProfile({
    required int vehicleId,
    required String brand,
    required String model,
    required String year,
  }) => _ref.read(vehicleRepoProvider).updateProfile(
    vehicleId,
    brand: brand,
    model: model,
    year: year,
  );

  /// Km düzelt: her değere izin var (01-spec §3.7); geriye alma onayını ekran
  /// [isKmGoingBack] ile sorar.
  Future<void> setCurrentKm(int vehicleId, int km) =>
      _ref.read(vehicleRepoProvider).setCurrentKm(vehicleId, km);

  Future<void> setTargetPressure(
    int vehicleId, {
    required double? front,
    required double? rear,
  }) => _ref
      .read(vehicleRepoProvider)
      .setTargetPressure(vehicleId, front: front, rear: rear);

  Future<void> setDevice(
    int vehicleId, {
    required String? address,
    required String? name,
  }) => _ref
      .read(vehicleRepoProvider)
      .setDevice(vehicleId, address: address, name: name);

  // ------------------------------------------------------------- kurallar

  Future<void> setRules(Rules rules) =>
      _ref.read(settingsRepoProvider).setRules(rules);

  // ------------------------------------------------------ kontrol listesi

  Future<void> setEnabled(int itemId, bool enabled) =>
      _ref.read(itemListRepoProvider).setEnabled(itemId, enabled);

  Future<void> setSchedule(int itemId, Schedule schedule) =>
      _ref.read(itemListRepoProvider).setSchedule(itemId, schedule);

  Future<void> updateItem(
    int itemId, {
    required String name,
    required Schedule schedule,
    required Measure measure,
  }) => _ref.read(itemListRepoProvider).updateItemForm(
    itemId,
    name: name,
    schedule: schedule,
    measure: measure,
  );

  Future<int> createItem({
    required int vehicleId,
    required String name,
    required String groupKey,
    required Schedule schedule,
    required Measure measure,
  }) => _ref.read(itemListRepoProvider).createUserItem(
    vehicleId: vehicleId,
    name: name,
    groupKey: groupKey,
    schedule: schedule,
    measure: measure,
  );

  Future<void> deleteItem(int itemId) =>
      _ref.read(itemListRepoProvider).deleteItem(itemId);

  // ------------------------------------------------------------- uygulama

  /// "Verileri sıfırla": DB temizlenir, Kotlin'deki snapshot ve prefs silinir,
  /// uygulama kuruluma döner (01-spec §3.7).
  Future<void> resetAll() async {
    await _ref.read(settingsRepoProvider).resetAll();
    try {
      await _ref.read(platformBridgeProvider).clearEngine();
    } on Object {
      // Kanal yoksa (test) sessiz geç; DB zaten temizlendi.
    }
    _ref.read(installDayProvider.notifier).state = null;
  }
}

final Provider<SettingsController> settingsControllerProvider =
    Provider<SettingsController>((Ref ref) => SettingsController(ref));
