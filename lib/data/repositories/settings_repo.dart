import 'dart:convert';

import '../../core/date_utils.dart';
import '../../domain/models/rules.dart';
import '../db/daos/settings_dao.dart';
import '../db/database.dart';

/// `settings` tablosunun tipli yüzü (02-mimari §3).
class SettingsRepo {
  const SettingsRepo(this._db);

  final AppDatabase _db;

  SettingsDao get _dao => _db.settingsDao;

  // ------------------------------------------------------------ kurulum günü

  Future<DateTime?> installDay() async =>
      tryParseDay(await _dao.get(SettingKeys.installDay));

  Future<void> setInstallDay(DateTime day) =>
      _dao.set(SettingKeys.installDay, dayKey(day));

  // ------------------------------------------------------------ şablon sürümü

  Future<int?> templateVersion() => _dao.getInt(SettingKeys.templateVersion);

  // ------------------------------------------------------------------ kurallar

  Future<Rules> rules() => _dao.getRules();

  Stream<Rules> watchRules() => _dao.watchRules();

  Future<void> setRules(Rules rules) => _dao.setRules(rules);

  // -------------------------------------------------------- genel erteleme

  /// Bildirimden "Yarın" (K-13). `yyyy-MM-dd`.
  Future<String?> globalSnoozeUntilDay() =>
      _dao.get(SettingKeys.globalSnoozeUntilDay);

  Future<void> setGlobalSnoozeUntilDay(String? day) =>
      _dao.set(SettingKeys.globalSnoozeUntilDay, day);

  // --------------------------------------------- silinen şablon maddeleri

  /// K-31. Şablon yükseltmesi bu anahtarları geri eklemez.
  Future<Set<String>> deletedTemplateKeys() async {
    final String? raw = await _dao.get(SettingKeys.deletedTemplateKeys);
    if (raw == null || raw.isEmpty) {
      return <String>{};
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List<Object?>) {
        return <String>{};
      }
      return <String>{
        for (final Object? e in decoded)
          if (e is String) e,
      };
    } on FormatException {
      return <String>{};
    }
  }

  Future<void> markTemplateKeyDeleted(String key) async {
    final Set<String> keys = await deletedTemplateKeys()..add(key);
    await _dao.set(
      SettingKeys.deletedTemplateKeys,
      jsonEncode(keys.toList()..sort()),
    );
  }

  // -------------------------------------------------------- izin soruldu mu

  Future<bool> permissionAsked(String key) async =>
      await _dao.getBool(key) ?? false;

  Future<void> markPermissionAsked(String key) => _dao.setBool(key, true);

  // ------------------------------------------------------------ pil şeridi

  Future<bool> batteryBannerDismissed() async =>
      await _dao.getBool(SettingKeys.batteryBannerDismissed) ?? false;

  Future<void> dismissBatteryBanner() =>
      _dao.setBool(SettingKeys.batteryBannerDismissed, true);

  // ------------------------------------------------------------------ toplu

  Stream<Map<String, String>> watchAll() => _dao.watchAll();

  Future<Map<String, String>> getAll() => _dao.getAll();

  /// "Verileri sıfırla": araç (cascade ile maddeler ve kayıtlar), sürüşler ve
  /// ayarlar silinir (01-spec §3.7). Motor prefs'i çağıran taraf temizler.
  Future<void> resetAll() async {
    await _db.transaction(() async {
      await _db.vehicleDao.deleteAll();
      await _db.tripDao.deleteAll();
      await _dao.clearAll();
    });
  }
}
