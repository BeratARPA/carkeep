import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/format_tr.dart';
import '../../core/strings_tr.dart';
import '../../core/theme.dart';
import '../../data/platform/platform_bridge.dart';
import '../../domain/interval_stepper.dart';
import '../../domain/models/check_item.dart';
import '../../domain/models/rules.dart';
import '../../domain/models/schedule.dart';
import '../../domain/models/trip.dart';
import '../../domain/models/vehicle.dart';
import '../../providers.dart';
import '../item_edit/item_edit_page.dart';
import '../setup/steps/step_permissions.dart';
import 'debug_controller.dart';
import 'device_picker_sheet.dart';
import 'settings_controller.dart';
import 'vehicle_sheets.dart';
import 'widgets/settings_widgets.dart';

/// Ayarlar ekranı (01-spec §3.7).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(permissionsProvider.notifier).refresh();
      ref.read(bluetoothStateProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Vehicle? vehicle = ref.watch(vehicleProvider).valueOrNull;
    if (vehicle == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            _VehicleSection(vehicle: vehicle),
            _BluetoothSection(vehicle: vehicle),
            const _RulesSection(),
            const _ChecklistSection(),
            const _AppSection(),
            if (kDebugMode) const _DebugSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------- araç

class _VehicleSection extends StatelessWidget {
  const _VehicleSection({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: S.settingsSectionVehicle,
      children: <Widget>[
        SettingsRow(
          key: const Key('row_vehicle_edit'),
          title: S.settingsVehicleEdit,
          value: vehicleProfileText(vehicle),
          onTap: () => showVehicleEditSheet(context),
        ),
        SettingsRow(
          key: const Key('row_km_fix'),
          title: S.settingsKmFix,
          value: '${formatKm(vehicle.currentKm)} ${S.unitKm}',
          onTap: () => showKmFixSheet(context),
        ),
        SettingsRow(
          key: const Key('row_tire_targets'),
          title: S.settingsTireTargets,
          value: tireTargetsText(vehicle),
          onTap: () => showTireTargetSheet(context),
        ),
      ],
    );
  }
}

/// `Fiat Egea 2019`; boş alanlar atlanır.
String vehicleProfileText(Vehicle v) => <String>[
  v.brand,
  v.model,
  v.year,
].where((String e) => e.trim().isNotEmpty).join(' ');

/// `2,3 / 2,1 bar` veya `Girilmedi`.
String tireTargetsText(Vehicle v) {
  final double? front = v.tireFrontBar;
  final double? rear = v.tireRearBar;
  if (front == null && rear == null) {
    return S.settingsTireTargetsNotSet;
  }
  final String f = front == null ? '—' : formatBar(front);
  final String r = rear == null ? '—' : formatBar(rear);
  return '$f / $r ${S.unitBar}';
}

// -------------------------------------------------------------- bluetooth

class _BluetoothSection extends ConsumerWidget {
  const _BluetoothSection({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // T13: kaynak Kotlin prefs değil `trips` tablosu. Prefs'teki kopya yalnız
    // motorun kendi işi için; ekran drain edilmiş veriyi gösterir.
    final Trip? trip = ref.watch(lastTripProvider).valueOrNull;
    final int refYear = ref.watch(todayProvider).year;

    return SettingsSection(
      title: S.settingsSectionBluetooth,
      children: <Widget>[
        SettingsRow(
          key: const Key('row_device'),
          title: S.settingsDeviceRow,
          value: vehicle.btName ?? S.settingsDeviceNone,
          help: lastTripText(
            disconnectedAt: trip?.disconnectedAt,
            durationMin: trip?.durationMin ?? 0,
            counted: trip?.counted ?? false,
            notified: trip?.notified ?? false,
            refYear: refYear,
            note: trip?.note,
          ),
          onTap: () => showDevicePickerSheet(context),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------- hatırlatma

/// K-30 hareket doğrulaması. Açmak izin + abonelik gerektirdiği için ayrı
/// widget: kural yalnız abonelik gerçekten kurulunca yazılır.
class _MotionRow extends ConsumerWidget {
  const _MotionRow({required this.rules});

  final Rules rules;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PermissionState perms = ref.watch(permissionsProvider);
    final SettingsController c = ref.read(settingsControllerProvider);
    // `await`'ten sonra `ref.read` çağırmıyoruz: kullanıcı yazma sürerken
    // Ayarlar'dan çıkarsa widget düşer ve `disableMotion` atlanırdı.
    final PermissionsNotifier perm = ref.read(permissionsProvider.notifier);
    final bool available = perms.motionAvailable;

    return SettingsSwitchRow(
      key: const Key('rule_require_motion'),
      title: S.ruleRequireMotion,
      help: available
          ? S.ruleRequireMotionHelp
          : S.ruleRequireMotionUnavailable,
      value: rules.requireMotion && available,
      onChanged: !available
          ? null
          : (bool v) async {
              if (!v) {
                await c.setRules(rules.copyWith(requireMotion: false));
                await perm.disableMotion();
                return;
              }
              final bool ok = await perm.enableMotion();
              if (ok) {
                await c.setRules(rules.copyWith(requireMotion: true));
                return;
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text(S.ruleRequireMotionNoPermission),
                    ),
                  );
              }
            },
    );
  }
}


class _RulesSection extends ConsumerWidget {
  const _RulesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Rules rules =
        ref.watch(rulesProvider).valueOrNull ?? Rules.defaults;
    final SettingsController c = ref.read(settingsControllerProvider);

    return SettingsSection(
      title: S.settingsSectionRules,
      children: <Widget>[
        SettingsSwitchRow(
          key: const Key('rule_only_overdue'),
          title: S.ruleOnlyOverdue,
          help: S.ruleOnlyOverdueHelp,
          value: rules.onlyOverdue,
          onChanged: (bool v) =>
              c.setRules(rules.copyWith(onlyOverdue: v)),
        ),
        SettingsSwitchRow(
          key: const Key('rule_once_per_day'),
          title: S.ruleOncePerDay,
          help: S.ruleOncePerDayHelp,
          value: rules.oncePerDay,
          onChanged: (bool v) => c.setRules(rules.copyWith(oncePerDay: v)),
        ),
        SettingsStepperRow(
          key: const Key('rule_min_trip'),
          decreaseKey: const Key('rule_min_trip_minus'),
          increaseKey: const Key('rule_min_trip_plus'),
          title: S.ruleMinTrip,
          help: S.ruleMinTripHelp,
          valueText: minutesText(rules.minTripMinutes),
          decreaseLabel: S.settingsIntervalDecrease,
          increaseLabel: S.settingsIntervalIncrease,
          onDecrease: rules.minTripMinutes > kMinTripMinutesMin
              ? () => c.setRules(
                  rules.copyWith(minTripMinutes: rules.minTripMinutes - 1),
                )
              : null,
          onIncrease: rules.minTripMinutes < kMinTripMinutesMax
              ? () => c.setRules(
                  rules.copyWith(minTripMinutes: rules.minTripMinutes + 1),
                )
              : null,
        ),
        SettingsStepperRow(
          key: const Key('rule_grace'),
          decreaseKey: const Key('rule_grace_minus'),
          increaseKey: const Key('rule_grace_plus'),
          title: S.ruleGrace,
          help: S.ruleGraceHelp,
          valueText: minutesText(rules.graceMinutes),
          decreaseLabel: S.settingsIntervalDecrease,
          increaseLabel: S.settingsIntervalIncrease,
          onDecrease: rules.graceMinutes > kGraceMinutesMin
              ? () => c.setRules(
                  rules.copyWith(graceMinutes: rules.graceMinutes - 1),
                )
              : null,
          onIncrease: rules.graceMinutes < kGraceMinutesMax
              ? () => c.setRules(
                  rules.copyWith(graceMinutes: rules.graceMinutes + 1),
                )
              : null,
        ),
        _MotionRow(rules: rules),
        SettingsStepperRow(
          key: const Key('rule_fallback'),
          decreaseKey: const Key('rule_fallback_minus'),
          increaseKey: const Key('rule_fallback_plus'),
          title: S.ruleFallback,
          help: S.ruleFallbackHelp,
          valueText: fallbackDaysText(rules.fallbackAfterDays),
          decreaseLabel: S.settingsIntervalDecrease,
          increaseLabel: S.settingsIntervalIncrease,
          onDecrease: _fallbackAt(rules.fallbackAfterDays, -1) == null
              ? null
              : () => c.setRules(
                  rules.copyWith(
                    fallbackAfterDays:
                        _fallbackAt(rules.fallbackAfterDays, -1)!,
                  ),
                ),
          onIncrease: _fallbackAt(rules.fallbackAfterDays, 1) == null
              ? null
              : () => c.setRules(
                  rules.copyWith(
                    fallbackAfterDays:
                        _fallbackAt(rules.fallbackAfterDays, 1)!,
                  ),
                ),
        ),
      ],
    );
  }
}

/// Yedek bildirim seçenekleri listede bir adım ilerler; uçta null.
int? _fallbackAt(int current, int direction) {
  final int i = kFallbackAfterDaysOptions.indexOf(current);
  final int next = (i < 0 ? 0 : i) + direction;
  if (next < 0 || next >= kFallbackAfterDaysOptions.length) {
    return null;
  }
  return kFallbackAfterDaysOptions[next];
}

// -------------------------------------------------------- kontrol listesi

class _ChecklistSection extends ConsumerWidget {
  const _ChecklistSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<CheckItem> items =
        ref.watch(itemsProvider).valueOrNull ?? const <CheckItem>[];

    return SettingsSection(
      title: S.settingsSectionChecklist,
      help: S.settingsChecklistHelp,
      children: <Widget>[
        for (final CheckItem item in items)
          _ChecklistRow(key: Key('setting_item_${item.id}'), item: item),
        SettingsRow(
          key: const Key('add_item'),
          title: S.settingsAddItem,
          onTap: () => openItemEditPage(context),
        ),
      ],
    );
  }
}

/// Ad + aralık metni, −/+ adımlayıcı, aç/kapat (01-spec §3.7).
class _ChecklistRow extends ConsumerWidget {
  const _ChecklistRow({required this.item, super.key});

  final CheckItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final SettingsController c = ref.read(settingsControllerProvider);

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: InkWell(
        onTap: () => openItemEditPage(context, itemId: item.id),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
          padding: const EdgeInsets.fromLTRB(AppSizes.screenPadding, 6, 6, 6),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(item.name, style: text.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      intervalText(
                        intervalDays: item.schedule.intervalDays,
                        intervalKm: item.schedule.intervalKm,
                        seasonalDates: <({int day, int month})>[
                          for (final SeasonalDate d in item.schedule.dates)
                            (month: d.month, day: d.day),
                        ],
                      ),
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              _StepIcon(
                iconKey: Key('interval_minus_${item.id}'),
                icon: Icons.remove,
                tooltip: S.settingsIntervalDecrease,
                onPressed: _stepAction(c, -1),
              ),
              _StepIcon(
                iconKey: Key('interval_plus_${item.id}'),
                icon: Icons.add,
                tooltip: S.settingsIntervalIncrease,
                onPressed: _stepAction(c, 1),
              ),
              Switch(
                key: Key('enabled_${item.id}'),
                value: item.enabled,
                onChanged: (bool v) => c.setEnabled(item.id, v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// `both` maddede −/+ yalnız km'yi değiştirir; mevsimselde adımlayıcı yok
  /// (01-spec §3.7).
  VoidCallback? _stepAction(SettingsController c, int direction) {
    final Schedule s = item.schedule;
    switch (s.kind) {
      case ScheduleKind.seasonal:
        return null;
      case ScheduleKind.days:
        final int next = stepInterval(
          s.intervalDays!,
          kIntervalDaysPresets,
          direction,
        );
        if (next == s.intervalDays) {
          return null;
        }
        return () => c.setSchedule(item.id, Schedule.days(next));
      case ScheduleKind.km:
      case ScheduleKind.both:
        final int next = stepInterval(
          s.intervalKm!,
          kIntervalKmPresets,
          direction,
        );
        if (next == s.intervalKm) {
          return null;
        }
        return () => c.setSchedule(
          item.id,
          s.kind == ScheduleKind.km
              ? Schedule.km(next)
              : Schedule.both(days: s.intervalDays!, km: next),
        );
    }
  }
}

class _StepIcon extends StatelessWidget {
  const _StepIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.iconKey,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Key iconKey;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: iconKey,
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(
        minWidth: AppSizes.minTapTarget,
        minHeight: AppSizes.minTapTarget,
      ),
      style: IconButton.styleFrom(
        foregroundColor: AppColors.ink,
        disabledForegroundColor: AppColors.line,
      ),
    );
  }
}

// --------------------------------------------------------------- uygulama

class _AppSection extends ConsumerWidget {
  const _AppSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PermissionState p = ref.watch(permissionsProvider);
    final PlatformBridge bridge = ref.read(platformBridgeProvider);
    final PermissionsNotifier permissions = ref.read(
      permissionsProvider.notifier,
    );
    final int? version = ref.watch(templateVersionProvider).valueOrNull;

    return SettingsSection(
      title: S.settingsSectionApp,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.screenPadding, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PermissionRow(
                rowKey: const Key('settings_perm_bluetooth'),
                title: S.permBluetooth,
                why: S.permBluetoothWhy,
                granted: p.bluetooth,
                blocked: p.bluetoothBlocked,
                onAction: permissions.requestBluetooth,
                onOpenSettings: permissions.openSystemSettings,
              ),
              PermissionRow(
                rowKey: const Key('settings_perm_notification'),
                title: S.permNotification,
                why: S.permNotificationWhy,
                granted: p.notification,
                blocked: p.notificationBlocked,
                onAction: permissions.requestNotification,
                onOpenSettings: permissions.openSystemSettings,
              ),
              PermissionRow(
                rowKey: const Key('settings_perm_battery'),
                title: S.permBattery,
                why: S.permBatteryWhy,
                granted: p.batteryIgnored,
                optional: true,
                grantedLabel: S.permBatteryOff,
                deniedLabel: S.permBatteryOn,
                actionLabel: S.open,
                onAction: bridge.openBatteryOptimizationSettings,
              ),
            ],
          ),
        ),
        SettingsRow(
          key: const Key('row_template_version'),
          title: '${S.templateVersionPrefix} ${version ?? '—'}',
        ),
        SettingsRow(
          key: const Key('row_reset'),
          title: S.settingsReset,
          danger: true,
          onTap: () => _confirmReset(context, ref),
        ),
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        content: const Text(S.settingsResetConfirm),
        actions: <Widget>[
          TextButton(
            key: const Key('reset_cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(S.cancel),
          ),
          TextButton(
            key: const Key('reset_confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(S.settingsReset),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      return;
    }
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    await ref.read(settingsControllerProvider).resetAll();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(S.settingsResetDone)));
  }
}

// ------------------------------------------------------------ geliştirici

/// Yalnız debug derlemede (01-spec §3.7).
class _DebugSection extends ConsumerWidget {
  const _DebugSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DebugController c = ref.read(debugControllerProvider);

    return SettingsSection(
      title: S.settingsSectionDebug,
      children: <Widget>[
        SettingsRow(
          key: const Key('debug_long_trip'),
          title: S.debugSimulateLongTrip,
          onTap: () => c.simulateDisconnect(context, minutes: kDebugLongTripMin),
        ),
        SettingsRow(
          key: const Key('debug_short_trip'),
          title: S.debugSimulateShortTrip,
          onTap: () =>
              c.simulateDisconnect(context, minutes: kDebugShortTripMin),
        ),
        SettingsRow(
          key: const Key('debug_connect'),
          title: S.debugSimulateConnect,
          onTap: () => c.simulateConnect(context),
        ),
        SettingsRow(
          key: const Key('debug_snapshot'),
          title: S.debugShowSnapshot,
          onTap: () => c.showSnapshot(context),
        ),
        SettingsRow(
          key: const Key('debug_fallback'),
          title: S.debugRunFallback,
          onTap: () => c.runFallback(context),
        ),
      ],
    );
  }
}
