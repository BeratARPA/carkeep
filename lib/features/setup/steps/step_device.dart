import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings_tr.dart';
import '../../../core/theme.dart';
import '../../../data/platform/device_list.dart';
import '../../../data/platform/platform_bridge.dart';
import '../setup_controller.dart';
import '../setup_screen.dart';

/// 4. adım: eşleşmiş cihaz listesi, tekli seçim. "Sonra seçerim" ile geçilir
/// (01-spec §3.1).
class StepDevice extends ConsumerWidget {
  const StepDevice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SetupState state = ref.watch(setupControllerProvider);
    final SetupController c = ref.read(setupControllerProvider.notifier);

    return SetupStepScaffold(
      title: S.setupDeviceTitle,
      help: S.setupDeviceHelp,
      children: <Widget>[
        ...switch (state.deviceListState) {
          // Yükleniyor: bilerek boş. Süresiz bir animasyon `pumpAndSettle`
          // ile takılır ve liste zaten anında geliyor.
          DeviceListState.loading => const <Widget>[SizedBox(height: 48)],
          DeviceListState.ok => <Widget>[
            for (final BondedDevice d in state.devices)
              DeviceTile(
                device: d,
                selected: d.address == state.selectedAddress,
                onTap: () => c.selectDevice(d),
              ),
          ],
          DeviceListState.empty => <Widget>[
            _Message(S.deviceListEmpty, onRetry: c.loadDevices),
          ],
          // T05 cihaz testi bulgusu: adaptör kapalıyken "cihaz yok" demek
          // yanlış yönlendirme olur.
          DeviceListState.bluetoothOff => <Widget>[
            _Message(S.deviceListBluetoothOff, onRetry: c.loadDevices),
          ],
          DeviceListState.noPermission => <Widget>[
            _Message(
              S.deviceListNoPermission,
              actionLabel: S.allow,
              onRetry: c.requestBluetooth,
            ),
          ],
          DeviceListState.error => <Widget>[
            _Message(S.errGeneric, onRetry: c.loadDevices),
          ],
        },
        const SizedBox(height: 8),
        if (state.selectedAddress != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('device_clear'),
              onPressed: c.clearDevice,
              child: const Text(S.skipForNow),
            ),
          ),
      ],
    );
  }
}

/// Ayarlar → cihaz seçici de aynı satırı kullanır (T11).
class DeviceTile extends StatelessWidget {
  const DeviceTile({
    required this.device,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final BondedDevice device;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? AppColors.ink : AppColors.ink3,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(device.displayName, style: text.titleMedium),
                  const SizedBox(height: 2),
                  Text(device.address, style: text.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {required this.onRetry, this.actionLabel});

  final String text;
  final Future<void> Function() onRetry;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        OutlinedButton(
          key: const Key('device_retry'),
          onPressed: () => onRetry(),
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
