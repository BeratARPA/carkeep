import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings_tr.dart';
import '../../../core/theme.dart';
import '../../../providers.dart';
import '../setup_controller.dart';
import '../setup_screen.dart';

/// 3. adım: üç izin satırı. Reddedilse de ilerlemeye izin verilir
/// (01-spec §3.1); ana ekranda uyarı şeridi çıkar.
class StepPermissions extends ConsumerWidget {
  const StepPermissions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SetupState state = ref.watch(setupControllerProvider);
    final SetupController c = ref.read(setupControllerProvider.notifier);
    final PermissionState p = state.permissions;

    return SetupStepScaffold(
      title: S.setupPermissionsTitle,
      help: null,
      children: <Widget>[
        PermissionRow(
          rowKey: const Key('perm_bluetooth'),
          title: S.permBluetooth,
          why: S.permBluetoothWhy,
          granted: p.bluetooth,
          blocked: p.bluetoothBlocked,
          onAction: c.requestBluetooth,
          onOpenSettings: c.openSystemSettings,
        ),
        PermissionRow(
          rowKey: const Key('perm_notification'),
          title: S.permNotification,
          why: S.permNotificationWhy,
          granted: p.notification,
          blocked: p.notificationBlocked,
          onAction: c.requestNotification,
          onOpenSettings: c.openSystemSettings,
        ),
        PermissionRow(
          rowKey: const Key('perm_battery'),
          title: S.permBattery,
          why: S.permBatteryWhy,
          granted: p.batteryIgnored,
          optional: true,
          grantedLabel: S.permBatteryOff,
          deniedLabel: S.permBatteryOn,
          actionLabel: S.open,
          onAction: c.openBatterySettings,
        ),
      ],
    );
  }
}

/// Ayarlar → Uygulama bölümü de aynı satırı kullanır (T11).
class PermissionRow extends StatelessWidget {
  const PermissionRow({
    required this.title,
    required this.why,
    required this.granted,
    required this.onAction,
    this.optional = false,
    this.blocked = false,
    this.onOpenSettings,
    this.grantedLabel = S.granted,
    this.deniedLabel = S.notGranted,
    this.actionLabel = S.allow,
    this.rowKey,
    super.key,
  });

  final String title;
  final String why;
  final bool granted;
  final Future<void> Function() onAction;
  final bool optional;

  /// 01-spec §9: "bir daha sorma" seçilmiş; sistem diyaloğu artık açılmaz.
  final bool blocked;
  final Future<void> Function()? onOpenSettings;

  final String grantedLabel;
  final String deniedLabel;
  final String actionLabel;
  final Key? rowKey;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      key: rowKey,
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(title, style: text.titleMedium)),
              Text(
                granted ? grantedLabel : deniedLabel,
                style: text.labelMedium?.copyWith(
                  color: granted ? AppColors.green : AppColors.ink3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(why, style: text.bodySmall),
          if (blocked) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              S.permDeniedPermanently,
              key: const Key('perm_blocked'),
              style: text.bodySmall?.copyWith(color: AppColors.red),
            ),
          ],
          if (optional) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              S.optional,
              style: text.labelSmall,
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: granted && !optional
                  ? null
                  : () => blocked ? onOpenSettings?.call() : onAction(),
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
              child: Text(blocked ? S.openSettings : actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}
