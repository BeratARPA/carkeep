import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/strings_tr.dart';
import 'core/theme.dart';
import 'domain/models/vehicle.dart';
import 'features/home/home_screen.dart';
import 'features/setup/setup_screen.dart';
import 'providers.dart';

/// Kök widget. `vehicles` boşsa kurulum sihirbazı, doluysa ana ekran
/// (01-spec §3.1).
class CarKeepApp extends ConsumerWidget {
  const CarKeepApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: S.appName,
      debugShowCheckedModeBanner: false,
      theme: buildCarKeepTheme(),
      scaffoldMessengerKey: ref.watch(scaffoldMessengerKeyProvider),
      home: const _Root(),
    );
  }
}

class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Vehicle?> vehicle = ref.watch(vehicleProvider);
    return vehicle.when(
      // İlk DB okuması; süresiz animasyon koymuyoruz (bkz. step_device).
      loading: () => const Scaffold(body: SizedBox.shrink()),
      error: (Object e, StackTrace _) => const _FatalError(S.errDbOpen),
      data: (Vehicle? v) =>
          v == null ? const SetupScreen() : const HomeScreen(),
    );
  }
}

/// Tam ekran hata (01-spec §9).
class _FatalError extends StatelessWidget {
  const _FatalError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
