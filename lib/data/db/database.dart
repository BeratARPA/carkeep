import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/item_dao.dart';
import 'daos/log_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/trip_dao.dart';
import 'daos/vehicle_dao.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: <Type>[Vehicles, CheckItems, CheckLogs, Trips, Settings],
  daos: <Type>[VehicleDao, ItemDao, LogDao, TripDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'carkeep'));

  /// Testler için: `NativeDatabase.memory()` veya başka bir executor.
  AppDatabase.forTesting(super.executor);

  /// 2: K-23 — `check_logs.kind` eklendi, `check_logs.km` nullable oldu.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // K-23: `kind` eklenir ve `km` nullable olur. Tablo yeniden kurulur;
        // `newColumns` olmadan drift eski tablodan `kind`i seçmeye çalışıp
        // "no such column: kind" ile patlıyor.
        await m.alterTable(
          TableMigration(
            checkLogs,
            newColumns: <GeneratedColumn<Object>>[checkLogs.kind],
            columnTransformer: <GeneratedColumn<Object>, Expression<Object>>{
              checkLogs.kind: const Constant<String>(kLogKindDone),
            },
          ),
        );
      }
    },
    beforeOpen: (OpeningDetails details) async {
      // 02-mimari §3: yabancı anahtarlar açık.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
