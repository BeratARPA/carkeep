import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings_tr.dart';
import '../../core/theme.dart';
import '../../data/platform/device_list.dart';
import '../../data/platform/platform_bridge.dart';
import '../../domain/models/vehicle.dart';
import '../../providers.dart';
import '../setup/steps/step_device.dart';
import 'settings_controller.dart';

/// Ayarlar → "Arabanın Bluetooth'u" satırının alt sayfası (01-spec §3.7).
/// Seçim anında DB'ye yazılır; kurulumdaki listeyle aynı hata durumları.
Future<void> showDevicePickerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => const DevicePickerSheet(),
  );
}

class DevicePickerSheet extends ConsumerStatefulWidget {
  const DevicePickerSheet({super.key});

  @override
  ConsumerState<DevicePickerSheet> createState() => _DevicePickerSheetState();
}

class _DevicePickerSheetState extends ConsumerState<DevicePickerSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(devicePickerProvider.notifier).load();
    });
  }

  Future<void> _select(BondedDevice device) async {
    final Vehicle? v = ref.read(vehicleProvider).valueOrNull;
    if (v == null) {
      return;
    }
    await ref
        .read(settingsControllerProvider)
        .setDevice(v.id, address: device.address, name: device.displayName);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final DevicePickerState state = ref.watch(devicePickerProvider);
    final DevicePickerNotifier notifier = ref.read(
      devicePickerProvider.notifier,
    );
    final Vehicle? vehicle = ref.watch(vehicleProvider).valueOrNull;
    final TextTheme text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        10,
        AppSizes.screenPadding,
        18 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            S.settingsDevicePickTitle,
            key: const Key('device_picker_title'),
            style: text.titleLarge,
          ),
          const SizedBox(height: 12),
          ...switch (state.listState) {
            // Süresiz animasyon `pumpAndSettle`ı takıyor; liste anında geliyor.
            DeviceListState.loading => const <Widget>[SizedBox(height: 48)],
            DeviceListState.ok => <Widget>[
              for (final BondedDevice d in state.devices)
                DeviceTile(
                  key: Key('device_${d.address}'),
                  device: d,
                  selected: d.address == vehicle?.btAddress,
                  onTap: () => _select(d),
                ),
            ],
            DeviceListState.empty => <Widget>[
              _Message(S.deviceListEmpty, onAction: notifier.load),
            ],
            DeviceListState.bluetoothOff => <Widget>[
              _Message(S.deviceListBluetoothOff, onAction: notifier.load),
            ],
            DeviceListState.noPermission => <Widget>[
              _Message(
                S.deviceListNoPermission,
                actionLabel: S.allow,
                onAction: notifier.requestPermission,
              ),
            ],
            DeviceListState.error => <Widget>[
              _Message(S.errGeneric, onAction: notifier.load),
            ],
          },
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {required this.onAction, this.actionLabel});

  final String text;
  final Future<void> Function() onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        OutlinedButton(
          key: const Key('device_picker_retry'),
          onPressed: () => onAction(),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, AppSizes.minTapTarget),
            foregroundColor: AppColors.ink,
            side: const BorderSide(color: AppColors.line),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(AppSizes.fieldRadius),
              ),
            ),
          ),
          child: Text(actionLabel ?? S.refresh),
        ),
      ],
    );
  }
}
