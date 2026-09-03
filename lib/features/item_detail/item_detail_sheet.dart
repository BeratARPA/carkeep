import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format_tr.dart';
import '../../core/strings_tr.dart';
import '../../core/theme.dart';
import '../../domain/models/check_item.dart';
import '../../domain/item_grouping.dart';
import '../../domain/models/check_log.dart';
import '../../domain/models/item_status.dart';
import '../../domain/models/measure.dart';
import '../../domain/models/vehicle.dart';
import '../../providers.dart';
import '../home/widgets/item_row.dart' show statusColor;
import 'date_km_fix_dialog.dart';
import 'item_detail_controller.dart';

/// Madde detayı alt sayfası (01-spec §3.3).
Future<void> showItemDetailSheet(
  BuildContext context, {
  required int itemId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => ItemDetailSheet(itemId: itemId),
  );
}

class ItemDetailSheet extends ConsumerStatefulWidget {
  const ItemDetailSheet({required this.itemId, super.key});

  final int itemId;

  @override
  ConsumerState<ItemDetailSheet> createState() => _ItemDetailSheetState();
}

class _ItemDetailSheetState extends ConsumerState<ItemDetailSheet> {
  MeasureInput _input = const MeasureInput();
  List<CheckLog> _recent = const <CheckLog>[];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecent());
  }

  Future<void> _loadRecent() async {
    final List<CheckLog> logs = await ref
        .read(itemDetailControllerProvider)
        .recentLogs(widget.itemId);
    if (mounted) {
      setState(() => _recent = logs);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save(CheckItem item) async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    final SaveOutcome outcome = await ref
        .read(itemDetailControllerProvider)
        .saveDone(item: item, input: _input);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    switch (outcome) {
      case SaveInvalid(:final String message):
        _toast(message);
      case SaveDone(:final String toast):
        Navigator.of(context).pop();
        _toast(toast);
    }
  }

  Future<void> _snooze(CheckItem item) async {
    await ref.read(itemDetailControllerProvider).snoozeTomorrow(item);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    _toast(S.snoozedToast);
  }

  Future<void> _fix(CheckItem item) async {
    final bool? saved = await showDateKmFixDialog(context, item: item);
    if (saved == true && mounted) {
      await _loadRecent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<StatusedItem> statuses = ref.watch(statusesProvider);
    final int index = statuses.indexWhere(
      (StatusedItem e) => e.item.id == widget.itemId,
    );
    if (index < 0) {
      return const SizedBox.shrink();
    }
    final CheckItem item = statuses[index].item;
    final ItemStatus status = statuses[index].status;
    final Vehicle? vehicle = ref.watch(vehicleProvider).valueOrNull;
    final TextTheme text = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (BuildContext context, ScrollController controller) {
        return Column(
          children: <Widget>[
            _Grabber(name: item.name, status: status),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenPadding,
                  6,
                  AppSizes.screenPadding,
                  20,
                ),
                children: <Widget>[
                  if (status.state == ItemState.unknown)
                    _UnknownCallout(onFix: () => _fix(item)),
                  if (item.why.isNotEmpty) ...<Widget>[
                    Text(
                      item.why,
                      key: const Key('detail_why'),
                      style: text.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (item.how.isNotEmpty) ...<Widget>[
                    Text(S.detailHow, style: text.labelMedium),
                    const SizedBox(height: 6),
                    for (int i = 0; i < item.how.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${i + 1}. ${item.how[i]}',
                          style: text.bodyMedium?.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                  ],
                  if (item.warn != null) _WarnRow(item.warn!),
                  _MeasureBlock(
                    item: item,
                    vehicle: vehicle,
                    input: _input,
                    onChanged: (MeasureInput next) =>
                        setState(() => _input = next),
                  ),
                  const SizedBox(height: 6),
                  Text(S.detailNoteLabel, style: text.labelMedium),
                  const SizedBox(height: 6),
                  TextField(
                    key: const Key('detail_note'),
                    decoration: const InputDecoration(
                      hintText: S.detailNoteHint,
                    ),
                    onChanged: (String v) =>
                        setState(() => _input = _input.copyWith(note: v)),
                  ),
                  if (_recent.isNotEmpty) _RecentLogs(logs: _recent),
                ],
              ),
            ),
            _Footer(
              item: item,
              status: status,
              saving: _saving,
              onSave: () => _save(item),
              onSnooze: () => _snooze(item),
              onFix: () => _fix(item),
            ),
          ],
        );
      },
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber({required this.name, required this.status});

  final String name;
  final ItemStatus status;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        10,
        AppSizes.screenPadding,
        6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Text(name, key: const Key('detail_title'), style: text.titleLarge),
          const SizedBox(height: 4),
          Text(
            status.longText,
            key: const Key('detail_status'),
            style: text.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: statusColor(status.state),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarnRow extends StatelessWidget {
  const _WarnRow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('detail_warn'),
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.error_outline, size: 18, color: AppColors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }
}

/// `unknown` maddede düzeltme öne çıkarılır (01-spec §3.4).
class _UnknownCallout extends StatelessWidget {
  const _UnknownCallout({required this.onFix});

  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('detail_unknown_callout'),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amberBg,
        borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            S.detailUnknownCallout,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.amber),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('detail_fix_callout'),
              onPressed: onFix,
              style: TextButton.styleFrom(foregroundColor: AppColors.amber),
              child: const Text(S.detailFixDate),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasureBlock extends StatelessWidget {
  const _MeasureBlock({
    required this.item,
    required this.vehicle,
    required this.input,
    required this.onChanged,
  });

  final CheckItem item;
  final Vehicle? vehicle;
  final MeasureInput input;
  final ValueChanged<MeasureInput> onChanged;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    switch (item.measure.type) {
      case MeasureType.none:
        return const SizedBox.shrink();

      case MeasureType.level:
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(S.measureLevel, style: text.labelMedium),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final String level in item.measure.levels)
                    ChoiceChip(
                      key: Key('level_$level'),
                      label: Text(level),
                      selected: input.level == level,
                      onSelected: (_) =>
                          onChanged(input.copyWith(level: level)),
                    ),
                ],
              ),
            ],
          ),
        );

      case MeasureType.tires:
        const List<String> labels = <String>[
          S.tireFrontLeft,
          S.tireFrontRight,
          S.tireRearLeft,
          S.tireRearRight,
        ];
        final String? target = tireTargetText(
          front: vehicle?.tireFrontBar,
          rear: vehicle?.tireRearBar,
        );
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(S.measureTires, style: text.labelMedium),
              const SizedBox(height: 8),
              for (int row = 0; row < 2; row++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: <Widget>[
                      for (int col = 0; col < 2; col++) ...<Widget>[
                        if (col == 1) const SizedBox(width: 10),
                        Expanded(
                          child: _TireField(
                            index: row * 2 + col,
                            label: labels[row * 2 + col],
                            value: input.tires[row * 2 + col],
                            target: tireTargetFor(
                              row * 2 + col,
                              front: vehicle?.tireFrontBar,
                              rear: vehicle?.tireRearBar,
                            ),
                            onChanged: (String v) =>
                                onChanged(input.withTire(row * 2 + col, v)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              Text(
                target ?? S.tireTargetUnknown,
                key: const Key('tire_target'),
                style: text.bodySmall,
              ),
            ],
          ),
        );

      case MeasureType.number:
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.measure.label ?? S.measureLevel,
                style: text.labelMedium,
              ),
              const SizedBox(height: 6),
              TextField(
                key: const Key('measure_number'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(suffixText: item.measure.unit),
                onChanged: (String v) => onChanged(input.copyWith(number: v)),
              ),
            ],
          ),
        );
    }
  }
}

class _TireField extends StatelessWidget {
  const _TireField({
    required this.index,
    required this.label,
    required this.value,
    required this.target,
    required this.onChanged,
  });

  final int index;
  final String label;
  final String value;
  final double? target;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool deviates = tireDeviates(value, target);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        TextField(
          key: Key('tire_$index'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            LengthLimitingTextInputFormatter(4),
          ],
          decoration: InputDecoration(
            hintText: S.unitBar,
            // Hedeften 0,3 bar ve fazla sapan alan amber vurgulanır
            // (01-spec §3.3; bilgi amaçlı, kaydetmeyi engellemez).
            filled: true,
            fillColor: deviates ? AppColors.amberBg : AppColors.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(
                Radius.circular(AppSizes.fieldRadius),
              ),
              borderSide: BorderSide(
                color: deviates ? AppColors.amber : AppColors.line,
              ),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _RecentLogs extends ConsumerWidget {
  const _RecentLogs({required this.logs});

  final List<CheckLog> logs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int refYear = ref.watch(todayProvider).year;
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      key: const Key('detail_recent'),
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Divider(),
          const SizedBox(height: 6),
          Text(S.detailPreviousLogs, style: text.labelMedium),
          const SizedBox(height: 4),
          for (final CheckLog log in logs)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(recentLogLine(log, refYear: refYear),
                  style: text.bodySmall),
            ),
        ],
      ),
    );
  }
}

/// `16 Ağu, 118.100 km, 2,3 / 2,3 / 2,3 / 2,2 bar. Arka sağ düşük`
String recentLogLine(CheckLog log, {required int refYear}) {
  final DateTime day = DateTime(
    int.parse(log.doneDay.substring(0, 4)),
    int.parse(log.doneDay.substring(5, 7)),
    int.parse(log.doneDay.substring(8, 10)),
  );
  final int? km = log.km;
  final String head = <String>[
    formatDate(day, refYear: refYear),
    if (km != null) '${formatKm(km)} ${S.unitKm}',
    if (log.hasValue) log.value!,
    // K-23: elle girilen düzeltmeler ayırt edilebilsin.
    if (log.isFix) S.logKindFix,
  ].join(', ');
  return log.hasNote ? '$head. ${log.note}' : head;
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.item,
    required this.status,
    required this.saving,
    required this.onSave,
    required this.onSnooze,
    required this.onFix,
  });

  final CheckItem item;
  final ItemStatus status;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onSnooze;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      // Alt sayfa ekranın dibine oturuyor; sistem gezinme çubuğunun altında
      // kalmasın diye güvenli alan kadar boşluk bırakılıyor.
      padding: EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        12,
        AppSizes.screenPadding,
        18 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ElevatedButton(
            key: const Key('detail_save'),
            onPressed: saving ? null : onSave,
            child: const Text(S.detailSaveDone),
          ),
          if (status.state == ItemState.overdue)
            TextButton(
              key: const Key('detail_snooze'),
              onPressed: saving ? null : onSnooze,
              child: const Text(S.detailSnooze),
            ),
          TextButton(
            key: const Key('detail_fix'),
            onPressed: saving ? null : onFix,
            child: const Text(S.detailFixDate),
          ),
        ],
      ),
    );
  }
}
