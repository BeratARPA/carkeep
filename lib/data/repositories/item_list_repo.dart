import 'package:drift/drift.dart';

import '../../domain/models/check_item.dart';
import '../../domain/models/measure.dart';
import '../../domain/models/schedule.dart';
import '../db/database.dart';
import 'settings_repo.dart';

/// `check_items` satırlarını domain modeline çevirir.
///
/// (Şablon kurulumu ve sürüm yükseltmesi `item_repo.dart`'ta; burası okuma ve
/// tekil güncelleme tarafı.)
class ItemListRepo {
  const ItemListRepo(this._db);

  final AppDatabase _db;

  Stream<List<CheckItem>> watchAll(int vehicleId) =>
      _db.itemDao.watchAll(vehicleId).map(toModels);

  Future<List<CheckItem>> getAll(int vehicleId) async =>
      toModels(await _db.itemDao.getAll(vehicleId));

  Future<CheckItem?> getById(int id) async {
    final CheckItemRow? row = await _db.itemDao.getById(id);
    return row == null ? null : toModel(row);
  }

  Future<void> setEnabled(int id, bool enabled) =>
      _db.itemDao.setEnabled(id, enabled);

  Future<void> setSnooze(int id, String? untilDay) =>
      _db.itemDao.setSnooze(id, untilDay);

  /// "Tarih/km düzelt" (01-spec §3.4). Log oluşturmaz.
  Future<void> setLastDone(
    int id, {
    required String? day,
    required int? km,
  }) => _db.itemDao.setLastDone(id, day: day, km: km);

  Future<void> setSchedule(int id, Schedule schedule) => _db.itemDao.setSchedule(
    id,
    kind: scheduleKindToString(schedule.kind),
    intervalDays: schedule.intervalDays,
    intervalKm: schedule.intervalKm,
    seasonalDates: schedule.seasonalDatesJson,
  );

  /// Madde ekle (01-spec §3.7). Kullanıcı maddesi: `template_key` null.
  Future<int> createUserItem({
    required int vehicleId,
    required String name,
    required String groupKey,
    required Schedule schedule,
    required Measure measure,
  }) async {
    final int maxOrder = await _db.itemDao.maxSortOrder(vehicleId);
    return _db.itemDao.insertOne(
      CheckItemsCompanion.insert(
        vehicleId: vehicleId,
        name: name,
        groupKey: groupKey,
        scheduleKind: scheduleKindToString(schedule.kind),
        intervalDays: Value<int?>(schedule.intervalDays),
        intervalKm: Value<int?>(schedule.intervalKm),
        seasonalDates: Value<String?>(schedule.seasonalDatesJson),
        measureType: measureTypeToString(measure.type),
        measureJson: Value<String?>(measure.json),
        sortOrder: maxOrder + 1,
      ),
    );
  }

  /// Madde düzenleme sayfasının kaydı: ad, takvim, ölçüm.
  Future<void> updateItemForm(
    int id, {
    required String name,
    required Schedule schedule,
    required Measure measure,
  }) async {
    final CheckItemRow? before = await _db.itemDao.getById(id);
    final String type = measureTypeToString(measure.type);
    await _db.transaction(() async {
      await _db.itemDao.setNameAndMeasure(
        id,
        name: name,
        measureType: type,
        measureJson: measure.json,
        // Tip değiştiyse eski biçimli son değer artık okunamaz.
        clearLastValue: before != null && before.measureType != type,
      );
      await setSchedule(id, schedule);
    });
  }

  /// Madde silme; kayıtları FK ile birlikte gider.
  ///
  /// K-31: şablon maddesi de silinebiliyor. Silinen şablon anahtarı
  /// `settings`'e yazılıyor, yoksa bir sonraki şablon sürümü onu geri ekler.
  Future<void> deleteItem(int id) async {
    final CheckItemRow? row = await _db.itemDao.getById(id);
    final String? templateKey = row?.templateKey;
    await _db.transaction(() async {
      await _db.itemDao.deleteItem(id);
      if (templateKey != null) {
        await SettingsRepo(_db).markTemplateKeyDeleted(templateKey);
      }
    });
  }

  static List<CheckItem> toModels(List<CheckItemRow> rows) =>
      <CheckItem>[for (final CheckItemRow r in rows) toModel(r)];

  static CheckItem toModel(CheckItemRow r) {
    return CheckItem(
      id: r.id,
      templateKey: r.templateKey,
      name: r.name,
      groupKey: r.groupKey,
      schedule: Schedule.fromDb(
        kind: r.scheduleKind,
        intervalDays: r.intervalDays,
        intervalKm: r.intervalKm,
        seasonalDatesJson: r.seasonalDates,
      ),
      measure: Measure.fromDb(type: r.measureType, json: r.measureJson),
      why: r.why,
      how: decodeHow(r.howJson),
      warn: r.warn,
      sourceNote: r.sourceNote,
      verified: r.verified,
      startsFromInstall: r.startsFromInstall,
      appliesLastService: r.appliesLastService,
      enabled: r.enabled,
      sortOrder: r.sortOrder,
      lastDoneDay: r.lastDoneDay,
      lastDoneKm: r.lastDoneKm,
      lastValue: r.lastValue,
      snoozeUntilDay: r.snoozeUntilDay,
    );
  }
}

/// Toplu `enabled` yazımı (kurulum 6. adımı).
extension ItemBulkEnable on AppDatabase {
  Future<void> applyEnabledFlags(Map<int, bool> byId) async {
    if (byId.isEmpty) {
      return;
    }
    await batch((Batch b) {
      byId.forEach((int id, bool enabled) {
        b.update(
          checkItems,
          CheckItemsCompanion(enabled: Value<bool>(enabled)),
          where: ($CheckItemsTable t) => t.id.equals(id),
        );
      });
    });
  }
}
