import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings_tr.dart';
import '../../core/theme.dart';
import 'setup_controller.dart';
import 'steps/step_checklist.dart';
import 'steps/step_device.dart';
import 'steps/step_km.dart';
import 'steps/step_last_service.dart';
import 'steps/step_permissions.dart';
import 'steps/step_vehicle.dart';

/// Kurulum sihirbazı (01-spec §3.1). Altı adım, üstte ilerleme çubukları.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  @override
  Widget build(BuildContext context) {
    final SetupState state = ref.watch(setupControllerProvider);
    final SetupController controller = ref.read(
      setupControllerProvider.notifier,
    );

    ref.listen<SetupState>(setupControllerProvider, (
      SetupState? prev,
      SetupState next,
    ) {
      final String? error = next.error;
      if (error != null && error != prev?.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error)));
        controller.clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenPadding,
            8,
            AppSizes.screenPadding,
            AppSizes.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _ProgressDots(step: state.step),
              const SizedBox(height: 22),
              Expanded(child: _StepBody(step: state.step)),
              const SizedBox(height: 12),
              _Footer(state: state, controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$step / $kSetupStepCount',
      child: Row(
        children: <Widget>[
          for (int i = 1; i <= kSetupStepCount; i++) ...<Widget>[
            if (i > 1) const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i <= step ? AppColors.ink : AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return switch (step) {
      1 => const StepVehicle(),
      2 => const StepKm(),
      3 => const StepPermissions(),
      4 => const StepDevice(),
      5 => const StepLastService(),
      _ => const StepChecklist(),
    };
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.controller});

  final SetupState state;
  final SetupController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (!state.isFirstStep) ...<Widget>[
          Expanded(
            child: TextButton(
              key: const Key('setup_back'),
              onPressed: state.submitting ? null : controller.back,
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
              ),
              child: const Text(S.back),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: ElevatedButton(
            key: const Key('setup_next'),
            onPressed: state.submitting
                ? null
                : () {
                    if (state.isLastStep) {
                      controller.finish();
                    } else {
                      controller.next();
                    }
                  },
            child: Text(state.isLastStep ? S.start : S.next),
          ),
        ),
      ],
    );
  }
}

/// Adımların ortak başlık + yardım metni düzeni.
class SetupStepScaffold extends StatelessWidget {
  const SetupStepScaffold({
    required this.title,
    required this.help,
    required this.children,
    super.key,
  });

  final String title;
  final String? help;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        if (help != null) ...<Widget>[
          Text(help!, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: children,
          ),
        ),
      ],
    );
  }
}
