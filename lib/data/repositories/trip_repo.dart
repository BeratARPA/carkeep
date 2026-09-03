import 'package:drift/drift.dart';

import '../../core/constants.dart';
import '../../domain/models/trip.dart';
import '../db/daos/settings_dao.dart';
import '../db/database.dart';
import '../platform/platform_bridge.dart';

/// `trips` tablosunun tipli yüzü ve Kotlin olaylarının işlendiği yer
/// (01-spec §7.3, 02-mimari §9).
class TripRepo {
  const TripRepo(this._db);

  final AppDatabase _db;

  // ------------------------------------------------------------------ okuma

  /// Ayarlar tanı satırı. Yedek bildirim satırları hariç (K-26).
  Stream<Trip?> watchLastTrip() =>
      _db.tripDao.watchLastTrip().map((TripRow? r) => r == null ? null : _toModel(r));

  Future<Trip?> lastTrip() async {
    final TripRow? row = await _db.tripDao.lastTrip();
    return row == null ? null : _toModel(row);
  }

  Future<List<Trip>> getAll() async =>
      <Trip>[for (final TripRow r in await _db.tripDao.getAll()) _toModel(r)];

  // ----------------------------------------------------------------- yazma

  /// Kotlin'in biriktirdiği olayları sırayla işler (01-spec §7.3).
  ///
  /// `drainPendingEvents` oku+sil tek çağrı olduğu için buraya gelen olaylar
  /// Kotlin tarafında zaten silinmiş demektir; hepsi **tek transaction**'da
  /// yazılır ki yarısı işlenmiş bir durum kalmasın.
  ///
  /// Dönen sayı: yazılan olay sayısı.
  Future<int> applyPendingEvents(List<PendingEvent> events) async {
    if (events.isEmpty) {
      return 0;
    }
    await _db.transaction(() async {
      for (final PendingEvent event in events) {
        switch (event) {
          case TripEvent():
            await _db.tripDao.insertTrip(_tripCompanion(event));
          case FallbackEvent():
            // K-26: yedek bildirim de `trips`'e yazılır (02-mimari §3 `note`
            // listesinde `fallback` var), ama sürüş değildir.
            await _db.tripDao.insertTrip(_fallbackCompanion(event));
          case SnoozeEvent():
            await _db.settingsDao.set(
              SettingKeys.globalSnoozeUntilDay,
              event.untilDay.isEmpty ? null : event.untilDay,
            );
        }
      }
    });
    return events.length;
  }

  static TripsCompanion _tripCompanion(TripEvent e) => TripsCompanion.insert(
    connectedAt: Value<DateTime?>(e.connectedAt),
    disconnectedAt: e.disconnectedAt,
    durationMin: e.durationMin,
    counted: e.counted,
    notified: e.notified,
    overdueCount: Value<int>(e.overdueCount),
    note: Value<String?>(e.note),
  );

  static TripsCompanion _fallbackCompanion(FallbackEvent e) =>
      TripsCompanion.insert(
        connectedAt: const Value<DateTime?>(null),
        disconnectedAt: e.at,
        durationMin: 0,
        counted: false,
        notified: true,
        overdueCount: Value<int>(e.overdueCount),
        note: const Value<String?>(kTripNoteFallback),
      );

  static Trip _toModel(TripRow r) => Trip(
    id: r.id,
    connectedAt: r.connectedAt,
    disconnectedAt: r.disconnectedAt,
    durationMin: r.durationMin,
    counted: r.counted,
    notified: r.notified,
    overdueCount: r.overdueCount,
    note: r.note,
  );
}
