/// GEÇİCİ — yalnız T05 kontrol noktası için.
///
/// `docs/05-is-listesi.md` T05 kabul kriterleri fiziksel cihazda doğrulanmak
/// zorunda; gerçek ekranlar T06'da geliyor. Bu dosya T06'nın ilk işi olarak
/// silinir ve `app.dart` kurulum sihirbazına yönlendirilir.
///
/// Metinler `strings_tr.dart`'ta değil: bu ekran kullanıcıya değil,
/// cihaz testine bakıyor ve kalıcı değil.
library;

import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/platform/platform_bridge.dart';

class BridgeCheckScreen extends StatefulWidget {
  const BridgeCheckScreen({super.key});

  @override
  State<BridgeCheckScreen> createState() => _BridgeCheckScreenState();
}

class _BridgeCheckScreenState extends State<BridgeCheckScreen> {
  final PlatformBridge _bridge = PlatformBridge();
  final List<_LogLine> _log = <_LogLine>[];
  String? _launchAction;

  @override
  void initState() {
    super.initState();
    _bridge.setLaunchActionHandler((String action) {
      _add('onLaunchAction', action, ok: true);
      setState(() => _launchAction = action);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _readEnvironment());
  }

  @override
  void dispose() {
    _bridge.clearLaunchActionHandler();
    super.dispose();
  }

  void _add(String label, Object? value, {required bool ok}) {
    if (!mounted) {
      return;
    }
    setState(() {
      _log.insert(0, _LogLine(label: label, value: '$value', ok: ok));
      if (_log.length > 60) {
        _log.removeLast();
      }
    });
  }

  Future<void> _run(String label, Future<Object?> Function() action) async {
    try {
      final Object? value = await action();
      _add(label, value ?? '(void)', ok: true);
    } on Object catch (e) {
      _add(label, e, ok: false);
    }
  }

  Future<void> _readEnvironment() async {
    await _run('getSdkInt', _bridge.getSdkInt);
    await _run('getManufacturer', _bridge.getManufacturer);
    await _run('hasBluetoothPermission', _bridge.hasBluetoothPermission);
    await _run('isBluetoothEnabled', _bridge.isBluetoothEnabled);
    await _run('hasNotificationPermission', _bridge.hasNotificationPermission);
    await _run('areNotificationsEnabled', _bridge.areNotificationsEnabled);
    await _run(
      'isIgnoringBatteryOptimizations',
      _bridge.isIgnoringBatteryOptimizations,
    );
    await _run('drainPendingEvents', () async {
      final List<PendingEvent> events = await _bridge.drainPendingEvents();
      return '${events.length} olay';
    });
    await _run('getLaunchAction', _bridge.getLaunchAction);
  }

  Future<void> _listDevices() async {
    try {
      final List<BondedDevice> devices = await _bridge.getBondedDevices();
      if (devices.isEmpty) {
        _add('getBondedDevices', 'eşleşmiş cihaz yok', ok: true);
        return;
      }
      for (final BondedDevice d in devices) {
        _add('  cihaz', '${d.displayName}  ${d.address}', ok: true);
      }
      _add('getBondedDevices', '${devices.length} cihaz', ok: true);
    } on BluetoothPermissionException {
      _add('getBondedDevices', 'NO_PERMISSION (beklenen)', ok: true);
    } on BluetoothUnavailableException {
      _add('getBondedDevices', 'NO_ADAPTER (Bluetooth kapalı?)', ok: false);
    } on Object catch (e) {
      _add('getBondedDevices', e, ok: false);
    }
  }

  Future<void> _snapshotRoundTrip() async {
    final String json = jsonEncode(<String, Object?>{
      'version': 1,
      'generatedAt': DateTime.now().toIso8601String(),
      'car': <String, Object?>{
        'address': '00:11:22:33:44:55',
        'name': 'Uconnect',
        'km': 118420,
      },
      'rules': <String, Object?>{
        'onlyOverdue': true,
        'oncePerDay': true,
        'minTripMinutes': 5,
        'graceMinutes': 2,
        'fallbackAfterDays': 7,
      },
      'items': <Object?>[
        <String, Object?>{
          'id': 12,
          'name': 'Motor yağı seviyesi',
          'dueDay': '2026-08-26',
          'dueKm': null,
          'snoozeUntilDay': null,
        },
      ],
    });
    await _bridge.writeSnapshot(json);
    final String? back = await _bridge.readSnapshot();
    _add(
      'writeSnapshot → readSnapshot',
      back == json ? 'AYNI (${json.length} karakter)' : 'FARKLI!',
      ok: back == json,
    );
  }

  Future<void> _readSnapshotOnly() async {
    final String? back = await _bridge.readSnapshot();
    _add(
      'readSnapshot',
      back == null ? 'null (yazılmamış)' : '${back.length} karakter',
      ok: back != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('T05 köprü kontrolü'),
        bottom: _launchAction == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Container(
                  width: double.infinity,
                  color: AppColors.greenBg,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'onLaunchAction: $_launchAction',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _Btn('Durumu oku', _readEnvironment),
                _Btn('Eşleşmiş cihazlar', _listDevices),
                _Btn('Bluetooth izni iste', () async {
                  await _run(
                    'requestBluetoothPermission',
                    _bridge.requestBluetoothPermission,
                  );
                  await _run(
                    'hasBluetoothPermission',
                    _bridge.hasBluetoothPermission,
                  );
                }),
                _Btn('Bildirim izni iste', () async {
                  await _run(
                    'requestNotificationPermission',
                    _bridge.requestNotificationPermission,
                  );
                  await _run(
                    'hasNotificationPermission',
                    _bridge.hasNotificationPermission,
                  );
                }),
                _Btn('Snapshot yaz+oku', _snapshotRoundTrip),
                _Btn('Sadece oku', _readSnapshotOnly),
                _Btn('Bluetooth durumu', () async {
                  await _run('getBluetoothState', () async {
                    final BluetoothState s = await _bridge.getBluetoothState();
                    return 'connected=${s.connected} since=${s.since} '
                        'lastTrip=${s.lastTrip}';
                  });
                }),
                _Btn('Pil ayarını aç', () async {
                  await _run(
                    'openBatteryOptimizationSettings',
                    () async => _bridge.openBatteryOptimizationSettings(),
                  );
                }),
                _Btn('Uygulama ayarını aç', () async {
                  await _run(
                    'openAppSettings',
                    () async => _bridge.openAppSettings(),
                  );
                }),
                _Btn('Bildirim ayarını aç', () async {
                  await _run(
                    'openNotificationSettings',
                    () async => _bridge.openNotificationSettings(),
                  );
                }),
                _Btn('Günlük işi planla', () async {
                  await _run(
                    'scheduleDailyWorker',
                    () async => _bridge.scheduleDailyWorker(),
                  );
                }),
                _Btn('Motoru temizle', () async {
                  await _run(
                    'clearEngine',
                    () async => _bridge.clearEngine(),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _log.isEmpty
                ? const Center(child: Text('Bir düğmeye bas.'))
                : ListView.separated(
                    itemCount: _log.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int i) {
                      final _LogLine line = _log[i];
                      return ListTile(
                        dense: true,
                        title: Text(
                          line.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(line.value),
                        trailing: Icon(
                          line.ok ? Icons.check_circle : Icons.error,
                          color: line.ok ? AppColors.green : AppColors.red,
                          size: 18,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn(this.label, this.onPressed);

  final String label;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, AppSizes.minTapTarget),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      onPressed: () => onPressed(),
      child: Text(label),
    );
  }
}

class _LogLine {
  const _LogLine({
    required this.label,
    required this.value,
    required this.ok,
  });

  final String label;
  final String value;
  final bool ok;
}
