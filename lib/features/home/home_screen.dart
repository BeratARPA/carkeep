/// GEÇİCİ yer tutucu. Gerçek Kontroller ekranı T07'de (01-spec §3.2);
/// bölümler, sıralama, chip ve uyarı şeritleri orada geliyor.
///
/// T06'nın "Başla sonrası ana ekrana geçilir" kabul kriteri için var.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format_tr.dart';
import '../../core/strings_tr.dart';
import '../../core/theme.dart';
import '../../domain/item_grouping.dart';
import '../../domain/models/vehicle.dart';
import '../../providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Vehicle? vehicle = ref.watch(vehicleProvider).valueOrNull;
    final GroupedItems grouped = ref.watch(groupedItemsProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (vehicle != null) ...<Widget>[
                Text(vehicle.displayName, style: text.bodySmall),
                const SizedBox(height: 2),
                Text(
                  '${formatKm(vehicle.currentKm)} ${S.unitKm}',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.68,
                    fontFeatures: tabularFigures,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Gecikmiş ${grouped.overdue.length} · '
                'Yaklaşan ${grouped.soon.length} · '
                'Zamanında ${grouped.ok.length} · '
                'Bilinmiyor ${grouped.unknown.length}',
                key: const Key('home_counts'),
                style: text.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
