import '../../core/constants.dart';
import '../../domain/models/check_log.dart';
import '../db/daos/log_dao.dart';
import '../db/database.dart';

/// `check_logs` satırları ↔ domain modeli. Yazma işlemleri `LogDao`'da tek
/// transaction içinde maddenin `last_done_*` alanlarını da günceller (T02).
class LogRepo {
  const LogRepo(this._db);

  final AppDatabase _db;

  Stream<List<CheckLog>> watchAll() =>
      _db.logDao.watchAll().map(_toModels);

  Future<List<CheckLog>> getAll() async => _toModels(await _db.logDao.getAll());

  /// Madde detayındaki "Önceki kayıtlar" (01-spec §3.3).
  Future<List<CheckLog>> recent(int itemId, {int limit = kRecentLogCount}) async
      => _toModels(await _db.logDao.lastN(itemId, limit));

  Future<int> add({
    required int itemId,
    required DateTime doneAt,
    required String doneDay,
    int? km,
    String? value,
    String? note,
    String kind = kLogKindDone,
  }) {
    return _db.logDao.addLog(
      itemId: itemId,
      doneAt: doneAt,
      doneDay: doneDay,
      km: km,
      value: value,
      note: note,
      kind: kind,
    );
  }

  Future<void> delete(int logId) => _db.logDao.deleteLog(logId);

  static List<CheckLog> _toModels(List<CheckLogRow> rows) =>
      <CheckLog>[for (final CheckLogRow r in rows) _toModel(r)];

  static CheckLog _toModel(CheckLogRow r) => CheckLog(
    id: r.id,
    itemId: r.itemId,
    doneAt: r.doneAt,
    doneDay: r.doneDay,
    km: r.km,
    value: r.value,
    note: r.note,
    kind: r.kind,
  );
}
