import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings_tr.dart';
import '../setup_controller.dart';
import '../setup_screen.dart';

/// 2. adım: güncel km (zorunlu).
class StepKm extends ConsumerStatefulWidget {
  const StepKm({super.key});

  @override
  ConsumerState<StepKm> createState() => _StepKmState();
}

class _StepKmState extends ConsumerState<StepKm> {
  late final TextEditingController _controller = TextEditingController(
    text: ref.read(setupControllerProvider).km,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SetupController c = ref.read(setupControllerProvider.notifier);
    return SetupStepScaffold(
      title: S.setupKmTitle,
      help: S.setupKmHelp,
      children: <Widget>[
        Text(S.fieldKm, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        TextField(
          key: const Key('setup_km'),
          controller: _controller,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(7),
          ],
          onChanged: c.setKm,
        ),
      ],
    );
  }
}
