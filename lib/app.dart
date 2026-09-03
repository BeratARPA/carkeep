import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'core/strings_tr.dart';
import 'core/theme.dart';
import 'data/platform/platform_bridge.dart';
import 'domain/models/vehicle.dart';
import 'features/history/history_screen.dart';
import 'features/home/home_controller.dart';
import 'features/home/home_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/setup/setup_screen.dart';
import 'providers.dart';

/// Kök widget. `vehicles` boşsa kurulum sihirbazı, doluysa üç sekmeli
/// uygulama kabuğu (01-spec §3.1, §3.2).
class CarKeepApp extends ConsumerStatefulWidget {
  const CarKeepApp({super.key});

  @override
  ConsumerState<CarKeepApp> createState() => _CarKeepAppState();
}

class _CarKeepAppState extends ConsumerState<CarKeepApp> {
  /// `dispose` içinde `ref` okunamıyor; köprü açılışta yakalanıyor.
  late final PlatformBridge _bridge = ref.read(platformBridgeProvider);

  @override
  void initState() {
    super.initState();
    // Uygulama açıkken bildirime dokunulursa Kotlin `onLaunchAction` çağırır:
    // Kontroller sekmesine geç ve Gecikmiş bölümünü vurgula (01-spec §3.8).
    _bridge.setLaunchActionHandler(_onLaunchAction);
  }

  @override
  void dispose() {
    _bridge.clearLaunchActionHandler();
    super.dispose();
  }

  void _onLaunchAction(String action) {
    if (!mounted) {
      return;
    }
    ref.read(launchActionProvider.notifier).state = action;
    ref.read(launchActionSeqProvider.notifier).state++;
    if (action == kLaunchActionOverdue) {
      ref.read(homeTabProvider.notifier).select(HomeTab.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Snapshot senkronu uygulama yaşadığı sürece ayakta (02-mimari §9).
    // Burada okunuyor ki `main.dart` kablolaması olmadan da (testler) çalışsın.
    ref.watch(snapshotSyncProvider);
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
      // İlk DB okuması; süresiz animasyon koymuyoruz (widget testlerini kilitler).
      loading: () => const Scaffold(body: SizedBox.shrink()),
      error: (Object e, StackTrace _) => const FatalErrorScreen(S.errDbOpen),
      data: (Vehicle? v) => v == null ? const SetupScreen() : const AppShell(),
    );
  }
}

/// Üç sekme, `IndexedStack` ile durum korunur (01-spec §3.2).
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HomeTab tab = ref.watch(homeTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: tab.index,
        children: const <Widget>[
          HomeScreen(),
          HistoryScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        key: const Key('bottom_nav'),
        currentIndex: tab.index,
        onTap: (int i) =>
            ref.read(homeTabProvider.notifier).select(HomeTab.values[i]),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            activeIcon: Icon(Icons.check_circle),
            label: S.tabHome,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: S.tabHistory,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tune),
            label: S.tabSettings,
          ),
        ],
      ),
    );
  }
}

/// Tam ekran hata (01-spec §9).
class FatalErrorScreen extends StatelessWidget {
  const FatalErrorScreen(this.message, {super.key});

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
