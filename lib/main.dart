import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/strings_tr.dart';
import 'core/theme.dart';
import 'data/db/database.dart';
import 'data/platform/platform_bridge.dart';
import 'data/repositories/item_repo.dart';
import 'data/repositories/settings_repo.dart';
import 'data/repositories/vehicle_repo.dart';
import 'data/seed/seed_loader.dart';
import 'domain/models/vehicle.dart';
import 'lifecycle.dart';
import 'providers.dart';

/// Açılış sırası 02-mimari §10.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppDatabase db;
  final Seed seed;
  try {
    db = AppDatabase();
    seed = await const SeedLoader().load();
  } on Object catch (e) {
    // 01-spec §9: şablon bozuksa geliştirici hatası, sıfırlamak fayda etmez;
    // DB açılamıyorsa tek çıkış verileri silmek.
    runApp(
      StartupErrorApp(
        message: _startupMessage(e),
        canReset: e is! SeedFormatException,
      ),
    );
    return;
  }

  final SettingsRepo settings = SettingsRepo(db);
  final DateTime? installDay = await settings.installDay();

  // Şablon sürüm yükseltmesi (K-07). Kurulum yapılmamışsa atlanır;
  // kurulum zaten şablonun tamamını kopyalar.
  final Vehicle? vehicle = await VehicleRepo(db).get();
  if (vehicle != null) {
    await ItemRepo(db).upgradeTemplateIfNeeded(vehicle.id, seed);
  }

  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      databaseProvider.overrideWithValue(db),
      seedProvider.overrideWithValue(seed),
      installDayProvider.overrideWith((Ref ref) => installDay),
    ],
  );

  // 3–4: Kotlin'in biriktirdiklerini DB'ye işle, bildirimden mi açıldık bak.
  final AppLifecycle lifecycle = container.read(appLifecycleProvider);
  await lifecycle.drainPendingEvents();
  await lifecycle.readLaunchAction();
  // 5: sürüşsüz dönem yedeği; `REPLACE` ile her açılışta yeniden planlanır.
  await lifecycle.scheduleDailyWorker();
  // K-34: `resume` soğuk açılışta tetiklenmiyor; hareket aboneliği yeniden
  // başlatmada düştüğü için burada da kuruluyor.
  await lifecycle.syncMotionRule();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CarKeepApp(),
    ),
  );
}

String _startupMessage(Object error) =>
    error is SeedFormatException ? S.errSeedLoad : S.errDbOpen;

/// DB veya şablon açılamazsa tam ekran hata (01-spec §9).
class StartupErrorApp extends StatefulWidget {
  const StartupErrorApp({
    required this.message,
    this.canReset = false,
    this.bridge,
    super.key,
  });

  final String message;

  /// DB açılamadıysa "Verileri sıfırla" sunulur.
  final bool canReset;

  /// Test için enjekte edilebilir.
  final PlatformBridge? bridge;

  @override
  State<StartupErrorApp> createState() => _StartupErrorAppState();
}

class _StartupErrorAppState extends State<StartupErrorApp> {
  late final PlatformBridge _bridge = widget.bridge ?? PlatformBridge();
  bool _reset = false;

  Future<void> _confirmReset(BuildContext context) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        content: const Text(S.settingsResetConfirm),
        actions: <Widget>[
          TextButton(
            key: const Key('startup_reset_cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(S.cancel),
          ),
          TextButton(
            key: const Key('startup_reset_confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(S.settingsReset),
          ),
        ],
      ),
    );
    if (ok != true) {
      return;
    }
    try {
      await _bridge.deleteDatabase();
    } on Object {
      // Silinemezse de kullanıcıya söyleyecek başka şey yok.
    }
    if (mounted) {
      setState(() => _reset = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: S.appName,
      debugShowCheckedModeBanner: false,
      theme: buildCarKeepTheme(),
      home: Builder(
        builder: (BuildContext context) => Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    _reset ? S.errDbResetDone : widget.message,
                    key: const Key('startup_error_text'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (widget.canReset && !_reset) ...<Widget>[
                    const SizedBox(height: 24),
                    OutlinedButton(
                      key: const Key('startup_reset'),
                      onPressed: () => _confirmReset(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, AppSizes.minTapTarget),
                        foregroundColor: AppColors.red,
                        side: const BorderSide(color: AppColors.line),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(AppSizes.buttonRadius),
                          ),
                        ),
                      ),
                      child: const Text(S.settingsReset),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
