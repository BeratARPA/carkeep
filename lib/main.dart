import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/strings_tr.dart';
import 'core/theme.dart';
import 'data/db/database.dart';
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
    runApp(_StartupError(_startupMessage(e)));
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
class _StartupError extends StatelessWidget {
  const _StartupError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: S.appName,
      debugShowCheckedModeBanner: false,
      theme: buildCarKeepTheme(),
      home: Scaffold(
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
      ),
    );
  }
}
