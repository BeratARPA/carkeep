import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_utils.dart';
import '../../core/format_tr.dart';
import '../../core/strings_tr.dart';
import '../../core/theme.dart';
import '../../domain/models/check_log.dart';
import '../../providers.dart';

/// Kayıt detayı (salt okunur) + Sil (01-spec §3.6).
Future<void> showHistoryLogSheet(
  BuildContext context, {
  required CheckLog log,
  required String itemName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) =>
        HistoryLogSheet(log: log, itemName: itemName),
  );
}

class HistoryLogSheet extends ConsumerWidget {
  const HistoryLogSheet({
    required this.log,
    required this.itemName,
    super.key,
  });

  final CheckLog log;
  final String itemName;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        content: const Text(S.historyDeleteConfirm),
        actions: <Widget>[
          TextButton(
            key: const Key('delete_cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(S.cancel),
          ),
          TextButton(
            key: const Key('delete_confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(S.historyDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await ref.read(logRepoProvider).delete(log.id);
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(S.historyDeleted)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final int refYear = ref.watch(todayProvider).year;
    final int? km = log.km;

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
            itemName,
            key: const Key('log_sheet_title'),
            style: text.titleLarge,
          ),
          const SizedBox(height: 8),
          _Line(
            label: S.fieldServiceDate,
            value: formatDate(parseDay(log.doneDay), refYear: refYear),
          ),
          if (km != null)
            _Line(label: S.fieldKm, value: '${formatKm(km)} ${S.unitKm}'),
          if (log.hasValue) _Line(label: S.measureLevel, value: log.value!),
          if (log.hasNote)
            _Line(label: S.detailNoteLabel, value: log.note!),
          if (log.isFix) _Line(label: S.detailFixDate, value: S.logKindFix),
          const SizedBox(height: 16),
          OutlinedButton(
            key: const Key('log_delete'),
            onPressed: () => _delete(context, ref),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
              foregroundColor: AppColors.red,
              side: const BorderSide(color: AppColors.line),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(AppSizes.buttonRadius),
                ),
              ),
            ),
            child: const Text(S.historyDelete),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(label, style: text.labelMedium),
          ),
          Expanded(child: Text(value, style: text.bodyMedium)),
        ],
      ),
    );
  }
}
