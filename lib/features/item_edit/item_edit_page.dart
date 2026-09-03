import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format_tr.dart';
import '../../core/strings_tr.dart';
import '../../core/theme.dart';
import '../../domain/item_form.dart';
import '../../domain/models/check_item.dart';
import '../../domain/models/measure.dart';
import '../../domain/models/schedule.dart';
import '../../domain/models/vehicle.dart';
import '../../providers.dart';
import '../item_detail/date_km_fix_dialog.dart';
import '../settings/settings_controller.dart';

/// Madde düzenleme / ekleme sayfası (01-spec §3.7).
/// [itemId] null ise boş form açılır ("Madde ekle").
Future<void> openItemEditPage(
  BuildContext context, {
  int? itemId,
  String groupKey = 'frequent',
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (BuildContext context) =>
          ItemEditPage(itemId: itemId, groupKey: groupKey),
    ),
  );
}

class ItemEditPage extends ConsumerStatefulWidget {
  const ItemEditPage({this.itemId, this.groupKey = 'frequent', super.key});

  final int? itemId;
  final String groupKey;

  @override
  ConsumerState<ItemEditPage> createState() => _ItemEditPageState();
}

class _ItemEditPageState extends ConsumerState<ItemEditPage> {
  late final CheckItem? _item = widget.itemId == null
      ? null
      : ref
            .read(itemsProvider)
            .valueOrNull
            ?.where((CheckItem e) => e.id == widget.itemId)
            .firstOrNull;

  late final TextEditingController _name = TextEditingController(
    text: _item?.name ?? '',
  );
  late final TextEditingController _days = TextEditingController(
    text: _item?.schedule.intervalDays?.toString() ?? '',
  );
  late final TextEditingController _km = TextEditingController(
    text: _item?.schedule.intervalKm?.toString() ?? '',
  );
  late final TextEditingController _levels = TextEditingController(
    text: _item?.measure.levels.join(', ') ?? '',
  );
  late final TextEditingController _unit = TextEditingController(
    text: _item?.measure.unit ?? '',
  );
  late final TextEditingController _label = TextEditingController(
    text: _item?.measure.label ?? '',
  );

  late ScheduleKind _kind = _item?.schedule.kind ?? ScheduleKind.days;
  late MeasureType _measureType = _item?.measure.type ?? MeasureType.none;
  late List<SeasonalDate> _dates = <SeasonalDate>[
    ...?_item?.schedule.dates,
  ];
  late String _groupKey = _item?.groupKey ?? widget.groupKey;

  Map<ItemFormField, String> _errors = <ItemFormField, String>{};

  bool get _isNew => _item == null;

  /// Şablon maddesinde ölçüm tipi kilitli (01-spec §3.7).
  bool get _measureLocked => _item?.isTemplateItem ?? false;

  @override
  void dispose() {
    _name.dispose();
    _days.dispose();
    _km.dispose();
    _levels.dispose();
    _unit.dispose();
    _label.dispose();
    super.dispose();
  }

  ItemFormData _form() => ItemFormData(
    name: _name.text,
    kind: _kind,
    intervalDays: int.tryParse(_days.text.trim()),
    intervalKm: parseKm(_km.text),
    dates: _dates,
    measureType: _measureType,
    levels: _levels.text.split(','),
    unit: _unit.text,
    label: _label.text,
  );

  Future<void> _save() async {
    final ItemFormData form = _form();
    final Map<ItemFormField, String> errors = validateItemForm(form);
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }
    final SettingsController c = ref.read(settingsControllerProvider);
    final Schedule schedule = buildSchedule(form);
    final Measure measure = buildMeasure(form);
    final CheckItem? item = _item;
    if (item == null) {
      final Vehicle? v = ref.read(vehicleProvider).valueOrNull;
      if (v == null) {
        return;
      }
      await c.createItem(
        vehicleId: v.id,
        name: _name.text.trim(),
        groupKey: _groupKey,
        schedule: schedule,
        measure: measure,
      );
    } else {
      await c.updateItem(
        item.id,
        name: _name.text.trim(),
        schedule: schedule,
        measure: measure,
      );
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    final CheckItem? item = _item;
    if (item == null) {
      return;
    }
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        content: const Text(S.itemEditDeleteConfirm),
        actions: <Widget>[
          TextButton(
            key: const Key('item_delete_cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(S.cancel),
          ),
          TextButton(
            key: const Key('item_delete_confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(S.itemEditDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    await ref.read(settingsControllerProvider).deleteItem(item.id);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(S.itemDeletedToast)));
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Map<String, String> groups = ref.watch(seedProvider).groups;
    final CheckItem? item = _item;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? S.itemEditNewTitle : S.itemEditTitle),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSizes.screenPadding,
          8,
          AppSizes.screenPadding,
          24 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: <Widget>[
          _LabeledField(
            label: S.itemEditName,
            fieldKey: const Key('item_name'),
            controller: _name,
            error: _errors[ItemFormField.name],
          ),
          if (_isNew) ...<Widget>[
            Text(S.itemEditGroup, style: text.labelMedium),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              key: const Key('item_group'),
              initialValue: groups.containsKey(_groupKey)
                  ? _groupKey
                  : groups.keys.first,
              items: <DropdownMenuItem<String>>[
                for (final MapEntry<String, String> e in groups.entries)
                  DropdownMenuItem<String>(value: e.key, child: Text(e.value)),
              ],
              onChanged: (String? v) =>
                  setState(() => _groupKey = v ?? _groupKey),
            ),
            const SizedBox(height: 16),
          ],
          Text(S.itemEditScheduleKind, style: text.labelMedium),
          const SizedBox(height: 6),
          DropdownButtonFormField<ScheduleKind>(
            key: const Key('item_kind'),
            initialValue: _kind,
            items: const <DropdownMenuItem<ScheduleKind>>[
              DropdownMenuItem<ScheduleKind>(
                value: ScheduleKind.days,
                child: Text(S.scheduleKindDays),
              ),
              DropdownMenuItem<ScheduleKind>(
                value: ScheduleKind.km,
                child: Text(S.scheduleKindKm),
              ),
              DropdownMenuItem<ScheduleKind>(
                value: ScheduleKind.both,
                child: Text(S.scheduleKindBoth),
              ),
              DropdownMenuItem<ScheduleKind>(
                value: ScheduleKind.seasonal,
                child: Text(S.scheduleKindSeasonal),
              ),
            ],
            onChanged: (ScheduleKind? v) =>
                setState(() => _kind = v ?? _kind),
          ),
          const SizedBox(height: 16),
          if (_kind == ScheduleKind.days || _kind == ScheduleKind.both)
            _LabeledField(
              label: S.itemEditIntervalDays,
              fieldKey: const Key('item_interval_days'),
              controller: _days,
              error: _errors[ItemFormField.intervalDays],
              digitsOnly: true,
            ),
          if (_kind == ScheduleKind.km || _kind == ScheduleKind.both)
            _LabeledField(
              label: S.itemEditIntervalKm,
              fieldKey: const Key('item_interval_km'),
              controller: _km,
              error: _errors[ItemFormField.intervalKm],
              digitsOnly: true,
            ),
          if (_kind == ScheduleKind.seasonal) _seasonalEditor(text),
          const SizedBox(height: 8),
          Text(S.itemEditMeasure, style: text.labelMedium),
          const SizedBox(height: 6),
          DropdownButtonFormField<MeasureType>(
            key: const Key('item_measure'),
            initialValue: _measureType,
            items: const <DropdownMenuItem<MeasureType>>[
              DropdownMenuItem<MeasureType>(
                value: MeasureType.none,
                child: Text(S.measureTypeNone),
              ),
              DropdownMenuItem<MeasureType>(
                value: MeasureType.level,
                child: Text(S.measureTypeLevel),
              ),
              DropdownMenuItem<MeasureType>(
                value: MeasureType.tires,
                child: Text(S.measureTypeTires),
              ),
              DropdownMenuItem<MeasureType>(
                value: MeasureType.number,
                child: Text(S.measureTypeNumber),
              ),
            ],
            onChanged: _measureLocked
                ? null
                : (MeasureType? v) =>
                      setState(() => _measureType = v ?? _measureType),
          ),
          if (_measureLocked) ...<Widget>[
            const SizedBox(height: 4),
            Text(S.itemEditMeasureLocked, style: text.bodySmall),
          ],
          const SizedBox(height: 12),
          if (_measureType == MeasureType.level)
            _LabeledField(
              label: S.itemEditLevels,
              fieldKey: const Key('item_levels'),
              controller: _levels,
              error: _errors[ItemFormField.measure],
            ),
          if (_measureType == MeasureType.number) ...<Widget>[
            _LabeledField(
              label: S.itemEditNumberUnit,
              fieldKey: const Key('item_unit'),
              controller: _unit,
              error: _errors[ItemFormField.measure],
            ),
            _LabeledField(
              label: S.itemEditNumberLabel,
              fieldKey: const Key('item_label'),
              controller: _label,
            ),
          ],
          const SizedBox(height: 8),
          ElevatedButton(
            key: const Key('item_edit_save'),
            onPressed: _save,
            child: const Text(S.save),
          ),
          if (item != null) ...<Widget>[
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('item_edit_fix'),
              onPressed: () => showDateKmFixDialog(context, item: item),
              style: _outlined(AppColors.ink),
              child: const Text(S.detailFixDate),
            ),
          ],
          if (item != null && !item.isTemplateItem) ...<Widget>[
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('item_edit_delete'),
              onPressed: _delete,
              style: _outlined(AppColors.red),
              child: const Text(S.itemEditDelete),
            ),
          ],
        ],
      ),
    );
  }

  ButtonStyle _outlined(Color color) => OutlinedButton.styleFrom(
    minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
    foregroundColor: color,
    side: const BorderSide(color: AppColors.line),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppSizes.buttonRadius)),
    ),
  );

  Widget _seasonalEditor(TextTheme text) {
    final String? error = _errors[ItemFormField.seasonalDates];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(S.itemEditSeasonalDates, style: text.labelMedium),
        const SizedBox(height: 6),
        for (int i = 0; i < _dates.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    formatMonthDay(_dates[i].month, _dates[i].day),
                    style: text.bodyLarge,
                  ),
                ),
                IconButton(
                  key: Key('seasonal_remove_$i'),
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() => _dates.removeAt(i)),
                ),
              ],
            ),
          ),
        if (error != null)
          Text(
            error,
            style: text.bodySmall?.copyWith(color: AppColors.red),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('seasonal_add'),
            onPressed: _addSeasonalDate,
            child: const Text(S.seasonalAddDate),
          ),
        ),
      ],
    );
  }

  Future<void> _addSeasonalDate() async {
    final SeasonalDate? picked = await showDialog<SeasonalDate>(
      context: context,
      builder: (BuildContext context) => const _SeasonalDateDialog(),
    );
    if (picked != null) {
      setState(() => _dates = <SeasonalDate>[..._dates, picked]);
    }
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.fieldKey,
    this.error,
    this.digitsOnly = false,
  });

  final String label;
  final TextEditingController controller;
  final Key fieldKey;
  final String? error;
  final bool digitsOnly;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          TextField(
            key: fieldKey,
            controller: controller,
            keyboardType: digitsOnly ? TextInputType.number : null,
            inputFormatters: digitsOnly
                ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
                : null,
            decoration: InputDecoration(errorText: error),
          ),
        ],
      ),
    );
  }
}

/// Gün + ay (yıl yok, mevsimsel tarih yıl taşımaz).
class _SeasonalDateDialog extends StatefulWidget {
  const _SeasonalDateDialog();

  @override
  State<_SeasonalDateDialog> createState() => _SeasonalDateDialogState();
}

class _SeasonalDateDialogState extends State<_SeasonalDateDialog> {
  final TextEditingController _day = TextEditingController();
  int _month = 1;

  @override
  void dispose() {
    _day.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(S.seasonalAddDate),
      content: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: TextField(
              key: const Key('seasonal_day'),
              controller: _day,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              decoration: const InputDecoration(labelText: S.dateDay),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: DropdownButtonFormField<int>(
              key: const Key('seasonal_month'),
              initialValue: _month,
              items: <DropdownMenuItem<int>>[
                for (int m = 1; m <= 12; m++)
                  DropdownMenuItem<int>(
                    value: m,
                    child: Text(trMonthsShort[m]),
                  ),
              ],
              onChanged: (int? v) => setState(() => _month = v ?? _month),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(S.cancel),
        ),
        TextButton(
          key: const Key('seasonal_ok'),
          onPressed: () {
            final int? day = int.tryParse(_day.text);
            if (day == null || day < 1 || day > 31) {
              return;
            }
            Navigator.of(context).pop(SeasonalDate(_month, day));
          },
          child: const Text(S.save),
        ),
      ],
    );
  }
}
