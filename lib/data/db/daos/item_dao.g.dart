// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_dao.dart';

// ignore_for_file: type=lint
mixin _$ItemDaoMixin on DatabaseAccessor<AppDatabase> {
  $VehiclesTable get vehicles => attachedDatabase.vehicles;
  $CheckItemsTable get checkItems => attachedDatabase.checkItems;
  ItemDaoManager get managers => ItemDaoManager(this);
}

class ItemDaoManager {
  final _$ItemDaoMixin _db;
  ItemDaoManager(this._db);
  $$VehiclesTableTableManager get vehicles =>
      $$VehiclesTableTableManager(_db.attachedDatabase, _db.vehicles);
  $$CheckItemsTableTableManager get checkItems =>
      $$CheckItemsTableTableManager(_db.attachedDatabase, _db.checkItems);
}
