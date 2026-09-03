import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings_tr.dart';
import '../setup_controller.dart';
import '../setup_screen.dart';

/// 1. adım: marka (zorunlu), model, yıl.
class StepVehicle extends ConsumerWidget {
  const StepVehicle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SetupState state = ref.watch(setupControllerProvider);
    final SetupController c = ref.read(setupControllerProvider.notifier);

    return SetupStepScaffold(
      title: S.setupVehicleTitle,
      help: S.setupVehicleHelp,
      children: <Widget>[
        _Field(
          fieldKey: const Key('setup_brand'),
          label: S.fieldBrand,
          initial: state.brand,
          onChanged: c.setBrand,
        ),
        _Field(
          fieldKey: const Key('setup_model'),
          label: S.fieldModel,
          initial: state.model,
          onChanged: c.setModel,
        ),
        _Field(
          fieldKey: const Key('setup_year'),
          label: S.fieldYear,
          initial: state.year,
          keyboardType: TextInputType.number,
          onChanged: c.setYear,
        ),
      ],
    );
  }
}

class _Field extends StatefulWidget {
  const _Field({
    required this.fieldKey,
    required this.label,
    required this.initial,
    required this.onChanged,
    this.keyboardType,
  });

  final Key fieldKey;
  final String label;
  final String initial;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(widget.label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          TextField(
            key: widget.fieldKey,
            controller: _controller,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
          ),
        ],
      ),
    );
  }
}
