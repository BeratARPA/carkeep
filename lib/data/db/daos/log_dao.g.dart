// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_dao.dart';

// ignore_for_file: type=lint
mixin _$LogDaoMixin on DatabaseAccessor<AppDatabase> {
  $VehiclesTable get vehicles => attachedDatabase.vehicles;
  $CheckItemsTable get checkItems => attachedDatabase.checkItems;
  $CheckLogsTable get checkLogs => attachedDatabase.checkLogs;
  LogDaoManager get managers => LogDaoManager(this);
}

class LogDaoManager {
  final _$LogDaoMixin _db;
  LogDaoManager(this._db);
  $$VehiclesTableTableManager get vehicles =>
      $$VehiclesTableTableManager(_db.attachedDatabase, _db.vehicles);
  $$CheckItemsTableTableManager get checkItems =>
      $$CheckItemsTableTableManager(_db.attachedDatabase, _db.checkItems);
  $$CheckLogsTableTableManager get checkLogs =>
      $$CheckLogsTableTableManager(_db.attachedDatabase, _db.checkLogs);
}
