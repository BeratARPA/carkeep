import 'package:drift/drift.dart';

import '../../../core/constants.dart';
import '../database.dart';
import '../tables.dart';

part 'trip_dao.g.dart';

@DriftAccessor(tables: <Type>[Trips])
class TripDao extends DatabaseAccessor<AppDatabase> with _$TripDaoMixin {
  TripDao(super.db);

  Future<int> insertTrip(TripsCompanion row) => into(trips).insert(row);

  /// Ayarlar tanı satırı (01-spec §3.7). Yedek bildirim satırları **hariç**:
  /// onlar kopma değil, "Son kopma:" metnine giremez (K-26).
  Future<TripRow?> lastTrip() => _lastTripQuery().getSingleOrNull();

  Stream<TripRow?> watchLastTrip() => _lastTripQuery().watchSingleOrNull();

  SimpleSelectStatement<$TripsTable, TripRow> _lastTripQuery() {
    return select(trips)
      // `note IS NULL` satırları da sürüştür: SQL'de `note = 'fallback'`
      // NULL döner, `NOT NULL` da NULL olur ve satır sessizce elenirdi.
      ..where(
        ($TripsTable t) =>
            t.note.isNull() | t.note.equals(kTripNoteFallback).not(),
      )
      ..orderBy(<OrderClauseGenerator<$TripsTable>>[
        ($TripsTable t) => OrderingTerm.desc(t.disconnectedAt),
        ($TripsTable t) => OrderingTerm.desc(t.id),
      ])
      ..limit(1);
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
