import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings_tr.dart';
import '../../../core/widgets/tr_date_field.dart';
import '../../../providers.dart';
import '../setup_controller.dart';
import '../setup_screen.dart';

/// 5. adım: son yağ değişimi (isteğe bağlı). Girilirse `appliesLastService`
/// maddelerinin son yapılışı bu değere set edilir (01-spec §3.1).
class StepLastService extends ConsumerStatefulWidget {
  const StepLastService({super.key});

  @override
  ConsumerState<StepLastService> createState() => _StepLastServiceState();
}

class _StepLastServiceState extends ConsumerState<StepLastService> {
  late final TextEditingController _km = TextEditingController(
    text: ref.read(setupControllerProvider).lastServiceKm,
  );

  @override
  void dispose() {
    _km.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SetupState state = ref.watch(setupControllerProvider);
    final SetupController c = ref.read(setupControllerProvider.notifier);
    final DateTime today = ref.watch(todayProvider);

    return SetupStepScaffold(
      title: S.setupLastServiceTitle,
      help: S.setupLastServiceHelp,
      children: <Widget>[
        Text(
          S.setupLastServiceQuestion,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        TrDateField(
          key: const Key('service_date'),
          value: state.lastServiceDate,
          today: today,
          label: S.fieldServiceDate,
          onChanged: (DateTime? d) =>
              c.setLastServiceDate(d, touched: true),
        ),
        const SizedBox(height: 16),
        Text(S.fieldServiceKm, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        TextField(
          key: const Key('service_km'),
          controller: _km,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(7),
          ],
          onChanged: c.setLastServiceKm,
        ),
      ],
    );
  }
}
