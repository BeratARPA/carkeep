/// Eşleşmiş cihaz listesinin yüklenmesi. Kurulum 4. adımı ve Ayarlar'daki
/// cihaz seçici aynı kuralları kullanır (01-spec §3.1, §3.7).
library;

import 'platform_bridge.dart';

enum DeviceListState { loading, ok, empty, bluetoothOff, noPermission, error }

typedef DeviceListResult = ({
  DeviceListState state,
  List<BondedDevice> devices,
});

Future<DeviceListResult> loadBondedDevices(PlatformBridge bridge) async {
  try {
    final bool enabled = await bridge.isBluetoothEnabled();
    final List<BondedDevice> devices = await bridge.getBondedDevices();
    return (
      state: devices.isNotEmpty
          ? DeviceListState.ok
          // T05 cihaz testi: adaptör kapalıyken liste boş gelir; bu
          // "eşleşmiş cihaz yok" değildir.
          : (enabled ? DeviceListState.empty : DeviceListState.bluetoothOff),
      devices: devices,
    );
  } on BluetoothPermissionException {
    return (
      state: DeviceListState.noPermission,
      devices: const <BondedDevice>[],
    );
  } on BluetoothUnavailableException {
    return (
      state: DeviceListState.bluetoothOff,
      devices: const <BondedDevice>[],
    );
  } on Object {
    return (state: DeviceListState.error, devices: const <BondedDevice>[]);
  }
}
