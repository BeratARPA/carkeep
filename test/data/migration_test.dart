/// Şema yükseltme testi.
///
/// Diğer testler `NativeDatabase.memory()` ile sıfırdan DB kurduğu için
/// `onCreate` yolunu izliyor ve `onUpgrade` hiç çalışmıyordu. K-23'ün
/// migration'ı bu yüzden cihazda "no such column: kind" ile patladı; bu dosya
/// aynı hatanın tekrar kaçmasını engelliyor.
library;

import 'dart:io';

import 'package:carkeep/data/db/daos/log_dao.dart';
import 'package:carkeep/data/db/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// K-23 öncesi (schemaVersion 1) `check_logs`: `km` NOT NULL, `kind` yok.
const String _v1CheckLogs = '''
CREATE TABLE check_logs (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  item_id INTEGER NOT NULL REFERENCES check_items (id) ON DELETE CASCADE,
  done_at INTEGER NOT NULL,
  done_day TEXT NOT NULL,
  km INTEGER NOT NULL,
  value TEXT NULL,
  note TEXT NULL
);
''';

const String _v1CheckItems = '''
CREATE TABLE check_items (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  vehicle_id INTEGER NOT NULL,
  template_key TEXT NULL,
  name TEXT NOT NULL,
  group_key TEXT NOT NULL,
  schedule_kind TEXT NOT NULL,
  interval_days INTEGER NULL,
  interval_km INTEGER NULL,
  seasonal_dates TEXT NULL,
  measure_type TEXT NOT NULL,
  measure_json TEXT NULL,
  why TEXT NOT NULL DEFAULT '',
  how_json TEXT NOT NULL DEFAULT '[]',
  warn TEXT NULL,
  source_note TEXT NULL,
  verified TEXT NOT NULL DEFAULT 'true',
  starts_from_install INTEGER NOT NULL DEFAULT 0,
  applies_last_service INTEGER NOT NULL DEFAULT 0,
  enabled INTEGER NOT NULL DEFAULT 1,
  sort_order INTEGER NOT NULL,
  last_done_day TEXT NULL,
  last_done_km INTEGER NULL,
  last_value TEXT NULL,
  snooze_until_day TEXT NULL,
  UNIQUE (vehicle_id, template_key)
);
''';

const String _v1Vehicles = '''
CREATE TABLE vehicles (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  brand TEXT NOT NULL,
  model TEXT NOT NULL DEFAULT '',
  year TEXT NOT NULL DEFAULT '',
  current_km INTEGER NOT NULL,
  bt_address TEXT NULL,
  bt_name TEXT NULL,
  tire_front_bar REAL NULL,
  tire_rear_bar REAL NULL,
  created_at INTEGER NOT NULL
);
''';

const String _v1Trips = '''
CREATE TABLE trips (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  connected_at INTEGER NULL,
  disconnected_at INTEGER NOT NULL,
  duration_min INTEGER NOT NULL,
  counted INTEGER NOT NULL,
  notified INTEGER NOT NULL,
  overdue_count INTEGER NOT NULL DEFAULT 0,
  note TEXT NULL
);
''';

const String _v1Settings = '''
CREATE TABLE settings (
  key TEXT NOT NULL,
  value TEXT NOT NULL,
  PRIMARY KEY (key)
);
''';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('carkeep_migration');
    file = File('${dir.path}/carkeep.sqlite');
  });

  tearDown(() {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  /// Elle v1 şemasını kurar ve bir kayıt yazar.
  void writeV1Database() {
    final Database raw = sqlite3.open(file.path);
    raw
      ..execute(_v1Vehicles)
      ..execute(_v1CheckItems)
      ..execute(_v1CheckLogs)
      ..execute(_v1Trips)
      ..execute(_v1Settings);
    raw.execute(
      'INSERT INTO vehicles (brand, model, year, current_km, created_at) '
      "VALUES ('Fiat', 'Egea', '2019', 118420, 1756900000)",
    );
    raw.execute(
      'INSERT INTO check_items (vehicle_id, template_key, name, group_key, '
      'schedule_kind, interval_days, measure_type, sort_order, last_done_day, '
      "last_done_km, last_value) VALUES (1, 'oil_level', 'Motor yağı seviyesi', "
      "'frequent', 'days', 14, 'level', 0, '2026-08-12', 117900, 'Orta')",
    );
    raw.execute(
      'INSERT INTO check_logs (item_id, done_at, done_day, km, value, note) '
      "VALUES (1, 1756900000, '2026-08-12', 117900, 'Orta', 'Yarım litre')",
    );
    raw.execute('PRAGMA user_version = 1');
    raw.close();
  }

  test('v1 → v2 yükseltmesi çalışıyor ve veri korunuyor', () async {
    writeV1Database();

    final AppDatabase db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);

    // Açılış migration'ı tetikler.
    final List<CheckLogRow> logs = await db.logDao.getAll();

    expect(logs.length, 1);
    final CheckLogRow log = logs.single;
    expect(log.doneDay, '2026-08-12');
    expect(log.km, 117900);
    expect(log.value, 'Orta');
    expect(log.note, 'Yarım litre');
    // Yeni sütun varsayılanla dolduruldu.
    expect(log.kind, kLogKindDone);

    // Madde ve araç el değmeden duruyor.
    expect((await db.vehicleDao.get())!.brand, 'Fiat');
    final List<CheckItemRow> items = await db.itemDao.getAll(1);
    expect(items.single.templateKey, 'oil_level');
    expect(items.single.lastDoneDay, '2026-08-12');
  });

  test('yükseltmeden sonra km null yazılabiliyor (K-23 düzeltme satırı)',
      () async {
    writeV1Database();

    final AppDatabase db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);

    await db.logDao.addLog(
      itemId: 1,
      doneAt: DateTime(2026, 9, 3, 10),
      doneDay: '2022-05-10',
      value: null,
      kind: kLogKindFix,
    );

    final CheckLogRow fix = (await db.logDao.getAll()).firstWhere(
      (CheckLogRow r) => r.kind == kLogKindFix,
    );
    expect(fix.km, isNull);
    expect(fix.doneDay, '2022-05-10');
  });

  test('sıfırdan kurulan DB doğrudan v2', () async {
    final AppDatabase db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    await db.logDao.getAll();
    expect(db.schemaVersion, 2);
  });

  test('yükseltilmiş DB üzerinde silme yeniden hesabı çalışıyor', () async {
    writeV1Database();

    final AppDatabase db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);

    final int newer = await db.logDao.addLog(
      itemId: 1,
      doneAt: DateTime(2026, 9, 3, 10),
      doneDay: '2026-09-03',
      km: 118420,
      value: "Max'a yakın",
    );
    expect((await db.itemDao.getById(1))!.lastDoneDay, '2026-09-03');

    await db.logDao.deleteLog(newer);
    final CheckItemRow row = (await db.itemDao.getById(1))!;
    expect(row.lastDoneDay, '2026-08-12');
    expect(row.lastDoneKm, 117900);
  });
}
