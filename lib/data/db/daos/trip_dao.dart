import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'trip_dao.g.dart';

@DriftAccessor(tables: <Type>[Trips])
class TripDao extends DatabaseAccessor<AppDatabase> with _$TripDaoMixin {
  TripDao(super.db);

  Future<int> insertTrip(TripsCompanion row) => into(trips).insert(row);

  /// Ayarlar tanı satırı (01-spec §3.7).
  Future<TripRow?> last() {
    return (select(trips)
          ..orderBy(<OrderClauseGenerator<$TripsTable>>[
            ($TripsTable t) => OrderingTerm.desc(t.disconnectedAt),
            ($TripsTable t) => OrderingTerm.desc(t.id),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Stream<TripRow?> watchLast() {
    return (select(trips)
          ..orderBy(<OrderClauseGenerator<$TripsTable>>[
            ($TripsTable t) => OrderingTerm.desc(t.disconnectedAt),
            ($TripsTable t) => OrderingTerm.desc(t.id),
          ])
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<List<TripRow>> getAll() {
    return (select(trips)
          ..orderBy(<OrderClauseGenerator<$TripsTable>>[
            ($TripsTable t) => OrderingTerm.desc(t.disconnectedAt),
          ]))
        .get();
  }

  Future<int> deleteAll() => delete(trips).go();
}
