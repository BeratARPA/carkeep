import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../domain/item_grouping.dart';
import '../../../domain/models/item_status.dart';
import '../home_controller.dart';

/// Ana ekran satırı (01-spec §3.2). Kart değil; ince çizgiyle ayrılmış,
/// yalnız gecikmiş satırda sol kırmızı çizgi.
class ItemRow extends StatelessWidget {
  const ItemRow({
    required this.entry,
    required this.refYear,
    required this.onTap,
    super.key,
  });

  final StatusedItem entry;
  final int refYear;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ItemState state = entry.status.state;

    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppSizes.minTapTarget,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: const BorderSide(color: AppColors.line),
              left: BorderSide(
                color: state == ItemState.overdue
                    ? AppColors.red
                    : Colors.transparent,
                width: AppSizes.overdueBarWidth,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenPadding - AppSizes.overdueBarWidth,
            14,
            AppSizes.screenPadding,
            14,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(entry.item.name, style: text.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      itemSubtitle(entry.item, refYear: refYear),
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                entry.status.shortText,
                textAlign: TextAlign.right,
                style: text.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: statusColor(state),
                  fontFeatures: tabularFigures,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Durum metni ve bölüm başlığı rengi (01-spec §10).
Color statusColor(ItemState state) => switch (state) {
  ItemState.overdue => AppColors.red,
  ItemState.soon => AppColors.amber,
  ItemState.ok => AppColors.ink3,
  ItemState.unknown => AppColors.ink3,
};
