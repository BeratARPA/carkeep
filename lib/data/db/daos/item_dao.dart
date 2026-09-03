import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'item_dao.g.dart';

@DriftAccessor(tables: <Type>[CheckItems])
class ItemDao extends DatabaseAccessor<AppDatabase> with _$ItemDaoMixin {
  ItemDao(super.db);

  /// `sort_order` sırasında yayınlar (T02 kabul kriteri).
  Stream<List<CheckItemRow>> watchAll(int vehicleId) {
    return (select(checkItems)
          ..where(($CheckItemsTable t) => t.vehicleId.equals(vehicleId))
          ..orderBy(<OrderClauseGenerator<$CheckItemsTable>>[
            ($CheckItemsTable t) => OrderingTerm.asc(t.sortOrder),
            ($CheckItemsTable t) => OrderingTerm.asc(t.id),
          ]))
        .watch();
  }

  Future<List<CheckItemRow>> getAll(int vehicleId) {
    return (select(checkItems)
          ..where(($CheckItemsTable t) => t.vehicleId.equals(vehicleId))
          ..orderBy(<OrderClauseGenerator<$CheckItemsTable>>[
            ($CheckItemsTable t) => OrderingTerm.asc(t.sortOrder),
            ($CheckItemsTable t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  Future<CheckItemRow?> getById(int id) {
    return (select(checkItems)
          ..where(($CheckItemsTable t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> insertAll(List<CheckItemsCompanion> rows) async {
    await batch((Batch b) => b.insertAll(checkItems, rows));
  }

  Future<int> insertOne(CheckItemsCompanion row) =>
      into(checkItems).insert(row);

  Future<bool> updateItem(CheckItemRow row) => update(checkItems).replace(row);

  Future<int> deleteItem(int id) {
    return (delete(checkItems)
          ..where(($CheckItemsTable t) => t.id.equals(id)))
        .go();
  }

  Future<int> setEnabled(int id, bool enabled) {
    return (update(checkItems)..where(($CheckItemsTable t) => t.id.equals(id)))
        .write(CheckItemsCompanion(enabled: Value<bool>(enabled)));
  }

  Future<int> setSchedule(
    int id, {
    required String kind,
    int? intervalDays,
    int? intervalKm,
    String? seasonalDates,
  }) {
    return (update(checkItems)..where(($CheckItemsTable t) => t.id.equals(id)))
        .write(
          CheckItemsCompanion(
            scheduleKind: Value<String>(kind),
            intervalDays: Value<int?>(intervalDays),
            intervalKm: Value<int?>(intervalKm),
            seasonalDates: Value<String?>(seasonalDates),
          ),
        );
  }

  /// "Tarih/km düzelt" (01-spec §3.4). Log **oluşturmaz**.
  /// Ertelemeyi temizler: düzeltme sonrası durum yeniden hesaplanır.
  Future<int> setLastDone(
    int id, {
    required String? day,
    required int? km,
    String? value,
  }) {
    return (update(checkItems)..where(($CheckItemsTable t) => t.id.equals(id)))
        .write(
          CheckItemsCompanion(
            lastDoneDay: Value<String?>(day),
            lastDoneKm: Value<int?>(km),
            lastValue: Value<String?>(value),
            snoozeUntilDay: const Value<String?>(null),
          ),
        );
  }

  Future<int> setSnooze(int id, String? untilDay) {
    return (update(checkItems)..where(($CheckItemsTable t) => t.id.equals(id)))
        .write(CheckItemsCompanion(snoozeUntilDay: Value<String?>(untilDay)));
  }

  /// Madde düzenleme sayfası (01-spec §3.7).
  Future<int> setNameAndMeasure(
    int id, {
    required String name,
    required String measureType,
    String? measureJson,
  }) {
    return (update(checkItems)..where(($CheckItemsTable t) => t.id.equals(id)))
        .write(
          CheckItemsCompanion(
            name: Value<String>(name),
            measureType: Value<String>(measureType),
            measureJson: Value<String?>(measureJson),
          ),
        );
  }

  /// Yeni kullanıcı maddesi listenin sonuna eklenir.
  Future<int> maxSortOrder(int vehicleId) async {
    final List<CheckItemRow> rows = await getAll(vehicleId);
    return rows.isEmpty ? -1 : rows.last.sortOrder;
  }

  Future<int> setSortOrder(int id, int sortOrder) {
    return (update(checkItems)..where(($CheckItemsTable t) => t.id.equals(id)))
        .write(CheckItemsCompanion(sortOrder: Value<int>(sortOrder)));
  }
}
