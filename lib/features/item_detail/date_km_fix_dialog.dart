import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format_tr.dart';
import '../../core/strings_tr.dart';
import '../../core/theme.dart';
import '../../core/widgets/tr_date_field.dart';
import '../../domain/models/check_item.dart';
import '../../domain/models/schedule.dart';
import '../../providers.dart';
import 'item_detail_controller.dart';

/// "Tarih/km düzelt" (01-spec §3.4). Log oluşturmaz; `unknown` maddeler için
/// tek çıkış yolu budur.
Future<bool?> showDateKmFixDialog(
  BuildContext context, {
  required CheckItem item,
}) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) => _DateKmFixDialog(item: item),
  );
}

class _DateKmFixDialog extends ConsumerStatefulWidget {
  const _DateKmFixDialog({required this.item});

  final CheckItem item;

  @override
  ConsumerState<_DateKmFixDialog> createState() => _DateKmFixDialogState();
}

class _DateKmFixDialogState extends ConsumerState<_DateKmFixDialog> {
  late final TextEditingController _km = TextEditingController(
    text: widget.item.lastDoneKm?.toString() ?? '',
  );
  DateTime? _date;
  String? _error;

  /// km ve both maddelerde km zorunlu, diğerlerinde alan gizli (§3.4).
  bool get _needsKm =>
      widget.item.schedule.kind == ScheduleKind.km ||
      widget.item.schedule.kind == ScheduleKind.both;

  @override
  void initState() {
    super.initState();
    final String? day = widget.item.lastDoneDay;
    if (day != null) {
      _date = DateTime(
        int.parse(day.substring(0, 4)),
        int.parse(day.substring(5, 7)),
        int.parse(day.substring(8, 10)),
      );
    }
  }

  @override
  void dispose() {
    _km.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final DateTime? date = _date;
    if (date == null) {
      setState(() => _error = S.errFixDateRequired);
      return;
    }
    final int? km = parseKm(_km.text);
    if (_needsKm && km == null) {
      setState(() => _error = S.errFixKmRequired);
      return;
    }
    await ref
        .read(itemDetailControllerProvider)
        .fixLastDone(widget.item, day: date, km: _needsKm ? km : null);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime today = ref.watch(todayProvider);
    return AlertDialog(
      title: const Text(S.fixDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TrDateField(
            key: const Key('fix_date'),
            value: _date,
            today: today,
            onChanged: (DateTime? d) => setState(() {
              _date = d;
              _error = null;
            }),
          ),
          if (_needsKm) ...<Widget>[
            const SizedBox(height: 16),
            Text(S.fieldKm, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
            TextField(
              key: const Key('fix_km'),
              controller: _km,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(7),
              ],
            ),
          ],
          if (_error != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              _error!,
              key: const Key('fix_error'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.red),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          key: const Key('fix_cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(S.cancel),
        ),
        TextButton(
          key: const Key('fix_save'),
          onPressed: _save,
          child: const Text(S.save),
        ),
      ],
    );
  }
}
