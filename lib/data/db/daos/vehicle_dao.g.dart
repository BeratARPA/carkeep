// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_dao.dart';

// ignore_for_file: type=lint
mixin _$VehicleDaoMixin on DatabaseAccessor<AppDatabase> {
  $VehiclesTable get vehicles => attachedDatabase.vehicles;
  VehicleDaoManager get managers => VehicleDaoManager(this);
}

class VehicleDaoManager {
  final _$VehicleDaoMixin _db;
  VehicleDaoManager(this._db);
  $$VehiclesTableTableManager get vehicles =>
      $$VehiclesTableTableManager(_db.attachedDatabase, _db.vehicles);
}
