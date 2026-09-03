/// Drift tablo tanımları (02-mimari §3). Şema burada; iş mantığı `domain/`'de.
library;

import 'package:drift/drift.dart';

@DataClassName('VehicleRow')
class Vehicles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get brand => text()();
  TextColumn get model => text().withDefault(const Constant<String>(''))();
  TextColumn get year => text().withDefault(const Constant<String>(''))();
  IntColumn get currentKm => integer()();
  TextColumn get btAddress => text().nullable()();
  TextColumn get btName => text().nullable()();
  RealColumn get tireFrontBar => real().nullable()();
  RealColumn get tireRearBar => real().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('CheckItemRow')
class CheckItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get vehicleId =>
      integer().references(Vehicles, #id, onDelete: KeyAction.cascade)();

  /// Seed `id`; kullanıcı maddesinde null.
  TextColumn get templateKey => text().nullable()();
  TextColumn get name => text()();

  /// `frequent|monthly|quarterly|service|yearly|seasonal|custom`
  TextColumn get groupKey => text()();

  /// `days|km|both|seasonal`
  TextColumn get scheduleKind => text()();
  IntColumn get intervalDays => integer().nullable()();
  IntColumn get intervalKm => integer().nullable()();

  /// JSON `[{"month":11,"day":1},...]`
  TextColumn get seasonalDates => text().nullable()();

  /// `none|level|tires|number`
  TextColumn get measureType => text()();

  /// `{"levels":[...]}` | `{"unit":"mm","label":"..."}`
  TextColumn get measureJson => text().nullable()();

  TextColumn get why => text().withDefault(const Constant<String>(''))();
  TextColumn get howJson => text().withDefault(const Constant<String>('[]'))();
  TextColumn get warn => text().nullable()();

  /// Denetim maddesi 14 / K-18 çevresi: seed'in `sourceNote` alanı burada saklanır.
  TextColumn get sourceNote => text().nullable()();

  /// `true|partial|false` (seed `verified`).
  TextColumn get verified =>
      text().withDefault(const Constant<String>('true'))();

  BoolColumn get startsFromInstall =>
      boolean().withDefault(const Constant<bool>(false))();
  BoolColumn get appliesLastService =>
      boolean().withDefault(const Constant<bool>(false))();
  BoolColumn get enabled => boolean().withDefault(const Constant<bool>(true))();
  IntColumn get sortOrder => integer()();

  /// `yyyy-MM-dd`
  TextColumn get lastDoneDay => text().nullable()();
  IntColumn get lastDoneKm => integer().nullable()();
  TextColumn get lastValue => text().nullable()();

  /// `yyyy-MM-dd`
  TextColumn get snoozeUntilDay => text().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{vehicleId, templateKey},
  ];
}

@DataClassName('CheckLogRow')
class CheckLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId =>
      integer().references(CheckItems, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get doneAt => dateTime()();

  /// `yyyy-MM-dd`
  TextColumn get doneDay => text()();
  IntColumn get km => integer()();
  TextColumn get value => text().nullable()();
  TextColumn get note => text().nullable()();
}

@DataClassName('TripRow')
class Trips extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get connectedAt => dateTime().nullable()();
  DateTimeColumn get disconnectedAt => dateTime()();
  IntColumn get durationMin => integer()();
  BoolColumn get counted => boolean()();
  BoolColumn get notified => boolean()();
  IntColumn get overdueCount =>
      integer().withDefault(const Constant<int>(0))();

  /// `short_trip|no_snapshot|no_overdue|once_per_day|snoozed|reconnect|fallback|ok`
  TextColumn get note => text().nullable()();
}

@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};
}
