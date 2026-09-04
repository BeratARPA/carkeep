import 'package:drift/drift.dart';

import '../../../domain/models/rules.dart';
import '../database.dart';
import '../tables.dart';

part 'settings_dao.g.dart';

/// `settings` tablosunun anahtarları (02-mimari §3).
abstract final class SettingKeys {
  static const String installDay = 'install_day';
  static const String templateVersion = 'template_version';
  static const String ruleOnlyOverdue = 'rule_only_overdue';
  static const String ruleOncePerDay = 'rule_once_per_day';
  static const String ruleMinTripMinutes = 'rule_min_trip_minutes';
  static const String ruleGraceMinutes = 'rule_grace_minutes';
  static const String ruleFallbackAfterDays = 'rule_fallback_after_days';

  /// K-30: hareket doğrulaması.
  static const String ruleRequireMotion = 'rule_require_motion';
  static const String globalSnoozeUntilDay = 'global_snooze_until_day';
  static const String batteryBannerDismissed = 'battery_banner_dismissed';

  /// K-31: kullanıcının sildiği şablon maddelerinin anahtarları (JSON dizi).
  /// Şablon yükseltmesi bunları geri eklemez.
  static const String deletedTemplateKeys = 'deleted_template_keys';

  /// Kalıcı ret ayrımı için: izin bir kez soruldu mu (01-spec §9).
  static const String askedBluetooth = 'asked_bluetooth';
  static const String askedNotification = 'asked_notification';

  /// K-30: hareket izni bir kez soruldu mu (kalıcı ret tespiti).
  static const String askedMotion = 'asked_motion';
}

@DriftAccessor(tables: <Type>[Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<String?> get(String key) async {
    final SettingRow? row =
        await (select(settings)..where(($SettingsTable t) => t.key.equals(key)))
            .getSingleOrNull();
    return row?.value;
  }

  Future<void> set(String key, String? value) async {
    if (value == null) {
      await (delete(settings)
            ..where(($SettingsTable t) => t.key.equals(key)))
          .go();
      return;
    }
    await into(settings).insertOnConflictUpdate(
      SettingsCompanion.insert(key: key, value: value),
    );
  }

  Stream<Map<String, String>> watchAll() {
    return select(settings).watch().map(
      (List<SettingRow> rows) => <String, String>{
        for (final SettingRow r in rows) r.key: r.value,
      },
    );
  }

  Future<Map<String, String>> getAll() async {
    final List<SettingRow> rows = await select(settings).get();
    return <String, String>{for (final SettingRow r in rows) r.key: r.value};
  }

  // ------------------------------------------------------------- tipli erişim

  Future<int?> getInt(String key) async => int.tryParse(await get(key) ?? '');

  Future<void> setInt(String key, int value) => set(key, value.toString());

  Future<bool?> getBool(String key) async {
    final String? v = await get(key);
    return v == null ? null : v == '1';
  }

  Future<void> setBool(String key, bool value) => set(key, value ? '1' : '0');

  Future<Rules> getRules() async {
    final Map<String, String> all = await getAll();
    return rulesFromMap(all);
  }

  Future<void> setRules(Rules rules) async {
    await batch((Batch b) {
      b.insertAllOnConflictUpdate(settings, <SettingsCompanion>[
        SettingsCompanion.insert(
          key: SettingKeys.ruleOnlyOverdue,
          value: rules.onlyOverdue ? '1' : '0',
        ),
        SettingsCompanion.insert(
          key: SettingKeys.ruleOncePerDay,
          value: rules.oncePerDay ? '1' : '0',
        ),
        SettingsCompanion.insert(
          key: SettingKeys.ruleMinTripMinutes,
          value: rules.minTripMinutes.toString(),
        ),
        SettingsCompanion.insert(
          key: SettingKeys.ruleGraceMinutes,
          value: rules.graceMinutes.toString(),
        ),
        SettingsCompanion.insert(
          key: SettingKeys.ruleFallbackAfterDays,
          value: rules.fallbackAfterDays.toString(),
        ),
        SettingsCompanion.insert(
          key: SettingKeys.ruleRequireMotion,
          value: rules.requireMotion ? '1' : '0',
        ),
      ]);
    });
  }

  Stream<Rules> watchRules() => watchAll().map(rulesFromMap);

  /// "Verileri sıfırla" (01-spec §3.7).
  Future<int> clearAll() => delete(settings).go();
}

/// `settings` haritasından [Rules]; eksik anahtar varsayılana düşer.
Rules rulesFromMap(Map<String, String> m) {
  const Rules d = Rules.defaults;
  return Rules(
    onlyOverdue: _boolOr(m[SettingKeys.ruleOnlyOverdue], d.onlyOverdue),
    oncePerDay: _boolOr(m[SettingKeys.ruleOncePerDay], d.oncePerDay),
    minTripMinutes:
        int.tryParse(m[SettingKeys.ruleMinTripMinutes] ?? '') ??
        d.minTripMinutes,
    graceMinutes:
        int.tryParse(m[SettingKeys.ruleGraceMinutes] ?? '') ?? d.graceMinutes,
    fallbackAfterDays:
        int.tryParse(m[SettingKeys.ruleFallbackAfterDays] ?? '') ??
        d.fallbackAfterDays,
    requireMotion: _boolOr(m[SettingKeys.ruleRequireMotion], d.requireMotion),
  );
}

bool _boolOr(String? raw, bool fallback) =>
    raw == null ? fallback : raw == '1';
