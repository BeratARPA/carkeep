import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings_tr.dart';
import '../../../core/theme.dart';
import '../../../data/seed/seed_loader.dart';
import '../../../domain/status_calculator.dart';
import '../../../providers.dart';
import '../setup_controller.dart';
import '../setup_screen.dart';

/// 6. adım: şablon maddeleri grup başlıklarıyla, aralık metni ve aç/kapat.
class StepChecklist extends ConsumerWidget {
  const StepChecklist({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Seed seed = ref.watch(seedProvider);
    final SetupState state = ref.watch(setupControllerProvider);
    final SetupController c = ref.read(setupControllerProvider.notifier);

    final List<Widget> rows = <Widget>[];
    String? lastGroup;
    for (final SeedItem item in seed.items) {
      if (item.group != lastGroup) {
        lastGroup = item.group;
        rows.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
            child: Text(
              seed.groups[item.group] ?? item.group,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        );
      }
      rows.add(
        _ItemRow(
          name: item.name,
          interval: intervalTextFor(item.schedule),
          enabled: state.enabledByKey[item.id] ?? item.enabledByDefault,
          onChanged: (bool v) => c.toggleItem(item.id, v),
          rowKey: Key('checklist_${item.id}'),
        ),
      );
    }

    return SetupStepScaffold(
      title: S.setupChecklistTitle,
      help: S.setupChecklistHelp,
      children: rows,
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.name,
    required this.interval,
    required this.enabled,
    required this.onChanged,
    required this.rowKey,
  });

  final String name;
  final String interval;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final Key rowKey;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      key: rowKey,
      constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(name, style: text.titleMedium),
                  const SizedBox(height: 2),
                  Text(interval, style: text.bodySmall),
                ],
              ),
            ),
            Switch(value: enabled, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
