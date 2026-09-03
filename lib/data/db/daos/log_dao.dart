import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'log_dao.g.dart';

@DriftAccessor(tables: <Type>[CheckLogs, CheckItems])
class LogDao extends DatabaseAccessor<AppDatabase> with _$LogDaoMixin {
  LogDao(super.db);

  /// Yeni üstte.
  Stream<List<CheckLogRow>> watchAll() {
    return (select(checkLogs)..orderBy(_newestFirst)).watch();
  }

  Future<List<CheckLogRow>> getAll() {
    return (select(checkLogs)..orderBy(_newestFirst)).get();
  }

  /// Madde detayındaki "Önceki kayıtlar" (01-spec §3.3).
  Future<List<CheckLogRow>> lastN(int itemId, int n) {
    return (select(checkLogs)
          ..where(($CheckLogsTable t) => t.itemId.equals(itemId))
          ..orderBy(_newestFirst)
          ..limit(n))
        .get();
  }

  Future<CheckLogRow?> getById(int id) {
    return (select(checkLogs)..where(($CheckLogsTable t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// "Yaptım olarak kaydet". Tek transaction: log eklenir, maddenin
  /// `last_done_*`/`last_value` güncellenir, erteleme temizlenir (01-spec §3.3).
  Future<int> addLog({
    required int itemId,
    required DateTime doneAt,
    required String doneDay,
    required int km,
    String? value,
    String? note,
  }) {
    return transaction(() async {
      final int logId = await into(checkLogs).insert(
        CheckLogsCompanion.insert(
          itemId: itemId,
          doneAt: doneAt,
          doneDay: doneDay,
          km: km,
          value: Value<String?>(value),
          note: Value<String?>(note),
        ),
      );
      await _syncItemFromLatestLog(itemId, clearSnooze: true);
      return logId;
    });
  }

  /// Geçmişten kayıt silme (01-spec §3.6). Maddenin son yapılışı bir önceki
  /// kayda döner; kayıt kalmazsa null olur.
  ///
  /// Bilinen sınır (ILERLEME → doküman denetimi md. 5): "Tarih/km düzelt" log
  /// üretmediği için, elle girilmiş bir son yapılış bu yeniden hesapla
  /// kaybolabilir. T10'da karara bağlanacak.
  Future<void> deleteLog(int logId) {
    return transaction(() async {
      final CheckLogRow? row = await getById(logId);
      if (row == null) {
        return;
      }
      await (delete(checkLogs)
            ..where(($CheckLogsTable t) => t.id.equals(logId)))
          .go();
      await _syncItemFromLatestLog(row.itemId, clearSnooze: false);
    });
  }

  Future<void> _syncItemFromLatestLog(
    int itemId, {
    required bool clearSnooze,
  }) async {
    final CheckLogRow? latest =
        await (select(checkLogs)
              ..where(($CheckLogsTable t) => t.itemId.equals(itemId))
              ..orderBy(_newestFirst)
              ..limit(1))
            .getSingleOrNull();

    await (update(checkItems)
          ..where(($CheckItemsTable t) => t.id.equals(itemId)))
        .write(
          CheckItemsCompanion(
            lastDoneDay: Value<String?>(latest?.doneDay),
            lastDoneKm: Value<int?>(latest?.km),
            lastValue: Value<String?>(latest?.value),
            snoozeUntilDay: clearSnooze
                ? const Value<String?>(null)
                : const Value<String?>.absent(),
          ),
        );
  }

  static final List<OrderClauseGenerator<$CheckLogsTable>> _newestFirst =
      <OrderClauseGenerator<$CheckLogsTable>>[
        ($CheckLogsTable t) => OrderingTerm.desc(t.doneAt),
        ($CheckLogsTable t) => OrderingTerm.desc(t.id),
      ];
}
