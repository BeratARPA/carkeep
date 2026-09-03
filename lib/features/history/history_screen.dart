import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_utils.dart';
import '../../core/format_tr.dart';
import '../../core/strings_tr.dart';
import '../../core/theme.dart';
import '../../domain/models/check_item.dart';
import '../../domain/models/check_log.dart';
import '../../providers.dart';
import 'history_log_sheet.dart';

/// Geçmiş ekranı (01-spec §3.6). Kayıtlar güne göre gruplu, yeni üstte.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<CheckLog> logs =
        ref.watch(logsProvider).valueOrNull ?? const <CheckLog>[];
    final List<CheckItem> items =
        ref.watch(itemsProvider).valueOrNull ?? const <CheckItem>[];
    final int refYear = ref.watch(todayProvider).year;

    if (logs.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            child: Text(
              S.historyEmpty,
              key: const Key('history_empty'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    final Map<int, String> nameById = <int, String>{
      for (final CheckItem i in items) i.id: i.name,
    };

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            for (final Widget w in _rows(context, logs, nameById, refYear)) w,
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  List<Widget> _rows(
    BuildContext context,
    List<CheckLog> logs,
    Map<int, String> nameById,
    int refYear,
  ) {
    final List<Widget> out = <Widget>[];
    String? lastDay;
    for (final CheckLog log in logs) {
      if (log.doneDay != lastDay) {
        lastDay = log.doneDay;
        out.add(_DayHeader(day: log.doneDay));
      }
      out.add(
        HistoryRow(
          key: Key('log_${log.id}'),
          log: log,
          itemName: nameById[log.itemId] ?? '',
          refYear: refYear,
        ),
      );
    }
    return out;
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final String day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.screenPadding, 20, 20, 8),
      child: Text(
        formatDateWithYear(parseDay(day)),
        key: Key('day_$day'),
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}

class HistoryRow extends ConsumerWidget {
  const HistoryRow({
    required this.log,
    required this.itemName,
    required this.refYear,
    super.key,
  });

  final CheckLog log;
  final String itemName;
  final int refYear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: () => showHistoryLogSheet(context, log: log, itemName: itemName),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenPadding,
            vertical: 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(itemName, style: text.titleMedium),
              const SizedBox(height: 2),
              Text(historyLogSubtitle(log), style: text.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// `2,3 / 2,3 / 2,3 / 2,2 bar, 118.100 km. Arka sağ düşük` (01-spec §3.6).
/// K-23 düzeltme satırları `düzeltme` etiketiyle ayrılır.
String historyLogSubtitle(CheckLog log) {
  final int? km = log.km;
  final String head = <String>[
    if (log.hasValue) log.value!,
    if (km != null) '${formatKm(km)} ${S.unitKm}',
    if (log.isFix) S.logKindFix,
  ].join(', ');
  if (head.isEmpty) {
    return log.hasNote ? log.note! : '';
  }
  return log.hasNote ? '$head. ${log.note}' : head;
}
