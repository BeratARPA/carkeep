import 'package:drift/drift.dart';

import '../../domain/models/vehicle.dart';
import '../db/database.dart';

/// Drift satırı ↔ domain modeli. Tek araç (K-01).
class VehicleRepo {
  const VehicleRepo(this._db);

  final AppDatabase _db;

  Future<Vehicle?> get() async => _toModel(await _db.vehicleDao.get());

  Stream<Vehicle?> watch() => _db.vehicleDao.watch().map(_toModel);

  Future<int> create({
    required String brand,
    required String model,
    required String year,
    required int currentKm,
    required DateTime createdAt,
    String? btAddress,
    String? btName,
  }) {
    return _db.vehicleDao.insertVehicle(
      VehiclesCompanion.insert(
        brand: brand,
        model: Value<String>(model),
        year: Value<String>(year),
        currentKm: currentKm,
        btAddress: Value<String?>(btAddress),
        btName: Value<String?>(btName),
        createdAt: createdAt,
      ),
    );
  }

  Future<void> setCurrentKm(int id, int km) =>
      _db.vehicleDao.setCurrentKm(id, km);

  Future<void> setDevice(int id, {String? address, String? name}) =>
      _db.vehicleDao.setDevice(id, address: address, name: name);

  Future<void> setTargetPressure(int id, {double? front, double? rear}) =>
      _db.vehicleDao.setTargetPressure(id, front: front, rear: rear);

  Future<void> updateProfile(
    int id, {
    required String brand,
    required String model,
    required String year,
  }) async {
    final VehicleRow? row = await _db.vehicleDao.get();
    if (row == null) {
      return;
    }
    await _db.vehicleDao.updateVehicle(
      row.copyWith(brand: brand, model: model, year: year),
    );
  }

  static Vehicle? _toModel(VehicleRow? row) {
    if (row == null) {
      return null;
    }
    return Vehicle(
      id: row.id,
      brand: row.brand,
      model: row.model,
      year: row.year,
      currentKm: row.currentKm,
      btAddress: row.btAddress,
      btName: row.btName,
      tireFrontBar: row.tireFrontBar,
      tireRearBar: row.tireRearBar,
      createdAt: row.createdAt,
    );
  }
}
