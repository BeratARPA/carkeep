import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models/measure.dart';
import '../../domain/models/schedule.dart';
import '../../domain/template_merge.dart';
import '../db/daos/item_dao.dart';
import '../db/daos/settings_dao.dart';
import '../db/database.dart';
import 'settings_repo.dart';
import '../seed/seed_loader.dart';

/// Şablon yükseltmesinin sonucu (01-spec §5 toast'ı için).
class TemplateUpgradeResult {
  const TemplateUpgradeResult({
    required this.addedCount,
    required this.fromVersion,
    required this.toVersion,
  });

  final int addedCount;
  final int? fromVersion;
  final int toVersion;

  bool get hasNewItems => addedCount > 0;
}

/// Şablon → DB dönüşümü ve sürüm yükseltme (K-07).
class ItemRepo {
  const ItemRepo(this._db);

  final AppDatabase _db;

  ItemDao get _items => _db.itemDao;
  SettingsDao get _settings => _db.settingsDao;

  /// Kurulum: şablonun tamamı seed sırasında kopyalanır, `enabled` =
  /// `enabledByDefault`. `settings.template_version` yazılır.
  Future<void> installSeed(int vehicleId, Seed seed) async {
    await _db.transaction(() async {
      await _items.insertAll(<CheckItemsCompanion>[
        for (int i = 0; i < seed.items.length; i++)
          seedItemToCompanion(
            seed.items[i],
            vehicleId: vehicleId,
            sortOrder: i,
            enabled: seed.items[i].enabledByDefault,
          ),
      ]);
      await _settings.setInt(SettingKeys.templateVersion, seed.version);
    });
  }

  /// Açılışta çağrılır. `settings.template_version < seed.version` ise
  /// seed'de olup DB'de olmayan maddeler **kapalı** olarak eklenir; mevcut
  /// maddelerin kullanıcı değişiklikleri asla ezilmez (K-07).
  Future<TemplateUpgradeResult> upgradeTemplateIfNeeded(
    int vehicleId,
    Seed seed,
  ) async {
    final int? current = await _settings.getInt(SettingKeys.templateVersion);
    if (current != null && current >= seed.version) {
      return TemplateUpgradeResult(
        addedCount: 0,
        fromVersion: current,
        toVersion: seed.version,
      );
    }

    final List<CheckItemRow> rows = await _items.getAll(vehicleId);
    // K-31: kullanıcının sildiği şablon maddeleri geri gelmez. Silinmiş anahtar
    // "DB'de yok" göründüğü için birleştirme onu yeniden eklerdi.
    final Set<String> deleted = await SettingsRepo(_db).deletedTemplateKeys();
    final MergePlan plan = TemplateMerge.plan(
      <SeedItem>[
        for (final SeedItem i in seed.items)
          if (!deleted.contains(i.id)) i,
      ],
      <ExistingItem>[
        for (final CheckItemRow r in rows)
          ExistingItem(templateKey: r.templateKey, sortOrder: r.sortOrder),
      ],
    );

    await _db.transaction(() async {
      if (plan.toInsert.isNotEmpty) {
        await _items.insertAll(<CheckItemsCompanion>[
          for (int i = 0; i < plan.toInsert.length; i++)
            seedItemToCompanion(
              plan.toInsert[i],
              vehicleId: vehicleId,
              sortOrder: plan.nextSortOrder + i,
              enabled: false,
            ),
        ]);
      }
      await _settings.setInt(SettingKeys.templateVersion, seed.version);
    });

    return TemplateUpgradeResult(
      addedCount: plan.toInsert.length,
      fromVersion: current,
      toVersion: seed.version,
    );
  }
}

/// Şablon maddesini DB satırına çevirir.
CheckItemsCompanion seedItemToCompanion(
  SeedItem item, {
  required int vehicleId,
  required int sortOrder,
  required bool enabled,
}) {
  return CheckItemsCompanion.insert(
    vehicleId: vehicleId,
    templateKey: Value<String?>(item.id),
    name: item.name,
    groupKey: item.group,
    scheduleKind: scheduleKindToString(item.schedule.kind),
    intervalDays: Value<int?>(item.schedule.intervalDays),
    intervalKm: Value<int?>(item.schedule.intervalKm),
    seasonalDates: Value<String?>(item.schedule.seasonalDatesJson),
    measureType: measureTypeToString(item.measure.type),
    measureJson: Value<String?>(item.measure.json),
    why: Value<String>(item.why),
    howJson: Value<String>(jsonEncode(item.how)),
    warn: Value<String?>(item.warn),
    sourceNote: Value<String?>(item.sourceNote),
    verified: Value<String>(item.verified),
    startsFromInstall: Value<bool>(item.startsFromInstall),
    appliesLastService: Value<bool>(item.appliesLastService),
    enabled: Value<bool>(enabled),
    sortOrder: sortOrder,
  );
}
