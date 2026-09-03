import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'vehicle_dao.g.dart';

@DriftAccessor(tables: <Type>[Vehicles])
class VehicleDao extends DatabaseAccessor<AppDatabase> with _$VehicleDaoMixin {
  VehicleDao(super.db);

  /// Tek araç (K-01). İlk kayıt.
  Future<VehicleRow?> get() async {
    return (select(vehicles)..limit(1)).getSingleOrNull();
  }

  Stream<VehicleRow?> watch() {
    return (select(vehicles)..limit(1)).watchSingleOrNull();
  }

  Future<int> insertVehicle(VehiclesCompanion row) =>
      into(vehicles).insert(row);

  Future<bool> updateVehicle(VehicleRow row) => update(vehicles).replace(row);

  Future<int> setCurrentKm(int id, int km) {
    return (update(vehicles)..where(($VehiclesTable t) => t.id.equals(id)))
        .write(VehiclesCompanion(currentKm: Value<int>(km)));
  }

  Future<int> setDevice(int id, {String? address, String? name}) {
    return (update(vehicles)..where(($VehiclesTable t) => t.id.equals(id)))
        .write(
          VehiclesCompanion(
            btAddress: Value<String?>(address),
            btName: Value<String?>(name),
          ),
        );
  }

  Future<int> setTargetPressure(int id, {double? front, double? rear}) {
    return (update(vehicles)..where(($VehiclesTable t) => t.id.equals(id)))
        .write(
          VehiclesCompanion(
            tireFrontBar: Value<double?>(front),
            tireRearBar: Value<double?>(rear),
          ),
        );
  }

  /// "Verileri sıfırla" (01-spec §3.7). Cascade ile maddeler ve kayıtlar da gider.
  Future<int> deleteAll() => delete(vehicles).go();
}
