# 02 — Teknik mimari

## 1. Genel resim
```
┌──────────────────────── Flutter (Dart) ─────────────────────────┐
│ features/  (ekranlar, Riverpod controller'lar)                   │
│ domain/    StatusCalculator, SnapshotBuilder, modeller (saf Dart)│
│ data/      Drift DB + DAO'lar, seed yükleyici, PlatformBridge    │
└──────────────┬───────────────────────────────▲──────────────────┘
               │ MethodChannel                 │ invokeMethod (Dart'a)
               │ com.beratarpa.carkeep/platform  │ onLaunchAction
┌──────────────▼───────────────────────────────┴──────────────────┐
│ Kotlin                                                           │
│ MainActivity      : channel handler, intent extras, izin akışı   │
│ EnginePrefs       : SharedPreferences "carkeep_engine" sarmalayıcı │
│ BtReceiver        : ACL_CONNECTED / ACL_DISCONNECTED (manifest)  │
│ ReminderEngine    : kural motoru (01-spec §7), bildirim bas/iptal│
│ Notifications     : kanal + builder                              │
│ NotifActionReceiver: "Yarın" eylemi                              │
│ DailyCheckWorker  : sürüşsüz dönem yedeği (WorkManager)          │
└──────────────────────────────────────────────────────────────────┘
```
Kotlin tarafı uygulama süreci ölüyken de çalışır (receiver + worker); bu yüzden Flutter motorunu **başlatmaz**. Tek ortak veri: `EnginePrefs`. Dart snapshot yazar, Kotlin okur; Kotlin olay yazar, Dart okur.

## 2. Klasör yapısı
```
carkeep/
  CLAUDE.md, docs/, seed/, preview/          (kit dosyaları, repo'da kalır)
  assets/
    seed/checklist_seed.json                 (seed/ kopyası; build'e giren bu)
    fonts/Manrope-*.ttf
  lib/
    main.dart                                (ProviderScope, DB aç, şablon migrasyonu, drain, snapshot, app)
    app.dart                                 (MaterialApp, tema, kök yönlendirme: kurulum mu ana mı)
    core/
      theme.dart, strings_tr.dart, format_tr.dart, date_utils.dart, constants.dart
    domain/
      models/ (vehicle.dart, check_item.dart, schedule.dart, measure.dart, check_log.dart, rules.dart, trip.dart, item_status.dart)
      status_calculator.dart
      snapshot_builder.dart
      template_merge.dart                    (şablon sürüm yükseltme)
    data/
      db/ database.dart, tables.dart, daos/ (vehicle_dao, item_dao, log_dao, trip_dao, settings_dao)
      seed/ seed_loader.dart
      platform/ platform_bridge.dart          (MethodChannel sarmalayıcı, tek sınıf)
      repositories/ (vehicle_repo, item_repo, log_repo, trip_repo, settings_repo) — DAO + model dönüşümü
    features/
      setup/       setup_screen.dart, setup_controller.dart, steps/*.dart
      home/        home_screen.dart, home_controller.dart, widgets/
      item_detail/ item_detail_sheet.dart, item_detail_controller.dart
      item_edit/   item_edit_screen.dart
      km_entry/    km_entry_sheet.dart
      history/     history_screen.dart
      settings/    settings_screen.dart, device_picker_sheet.dart, permissions_section.dart, developer_section.dart
    providers.dart                           (DB, repo, bridge, sync providers)
  android/app/src/main/kotlin/com/beratarpa/carkeep/
    MainActivity.kt, EnginePrefs.kt, BtReceiver.kt, ReminderEngine.kt, Notifications.kt,
    NotifActionReceiver.kt, DailyCheckWorker.kt, DayKey.kt
  test/
    domain/status_calculator_test.dart, snapshot_builder_test.dart, template_merge_test.dart
    data/seed_loader_test.dart, daos_test.dart (in-memory NativeDatabase)
    features/ widget testleri
```

## 3. Veri modeli (Drift, `tables.dart`)

```
vehicles
  id INTEGER PK AUTOINCREMENT
  brand TEXT NOT NULL, model TEXT NOT NULL DEFAULT '', year TEXT NOT NULL DEFAULT ''
  current_km INTEGER NOT NULL
  bt_address TEXT NULL, bt_name TEXT NULL
  tire_front_bar REAL NULL, tire_rear_bar REAL NULL
  created_at DATETIME NOT NULL

check_items
  id INTEGER PK AUTOINCREMENT
  vehicle_id INTEGER NOT NULL REFERENCES vehicles(id)
  template_key TEXT NULL                     -- seed id; kullanıcı maddesinde NULL; (vehicle_id, template_key) UNIQUE
  name TEXT NOT NULL
  group_key TEXT NOT NULL                    -- frequent|monthly|quarterly|service|yearly|seasonal|custom
  schedule_kind TEXT NOT NULL                -- days|km|both|seasonal
  interval_days INTEGER NULL
  interval_km INTEGER NULL
  seasonal_dates TEXT NULL                   -- JSON [{"month":11,"day":1},...]
  measure_type TEXT NOT NULL                 -- none|level|tires|number
  measure_json TEXT NULL                     -- {"levels":[...]} | {"unit":"mm","label":"Diş derinliği"}
  why TEXT NOT NULL DEFAULT '', how_json TEXT NOT NULL DEFAULT '[]', warn TEXT NULL
  starts_from_install BOOLEAN NOT NULL DEFAULT 0
  applies_last_service BOOLEAN NOT NULL DEFAULT 0
  enabled BOOLEAN NOT NULL DEFAULT 1
  sort_order INTEGER NOT NULL
  last_done_day TEXT NULL                    -- yyyy-MM-dd
  last_done_km INTEGER NULL
  last_value TEXT NULL
  snooze_until_day TEXT NULL

check_logs
  id INTEGER PK AUTOINCREMENT
  item_id INTEGER NOT NULL REFERENCES check_items(id) ON DELETE CASCADE
  done_at DATETIME NOT NULL, done_day TEXT NOT NULL
  km INTEGER NOT NULL
  value TEXT NULL, note TEXT NULL
  INDEX (item_id, done_at DESC)

trips
  id INTEGER PK AUTOINCREMENT
  connected_at DATETIME NULL, disconnected_at DATETIME NOT NULL
  duration_min INTEGER NOT NULL
  counted BOOLEAN NOT NULL, notified BOOLEAN NOT NULL
  overdue_count INTEGER NOT NULL DEFAULT 0
  note TEXT NULL                             -- short_trip|no_overdue|once_per_day|snoozed|reconnect|fallback|ok

settings (key TEXT PK, value TEXT)
  install_day, template_version,
  rule_only_overdue ('1'/'0'), rule_once_per_day, rule_min_trip_minutes, rule_grace_minutes, rule_fallback_after_days ('0' = kapalı),
  global_snooze_until_day, battery_banner_dismissed
```
- `last_done_*` denormalize alanlardır; her log ekleme/silmede ve düzeltmede DAO tek transaction içinde günceller.
- Migrasyon: `schemaVersion = 1`; ileride `MigrationStrategy` ile. Test: in-memory `NativeDatabase.memory()`.
- Yabancı anahtarlar açık: `customStatement('PRAGMA foreign_keys = ON')`.

## 4. Domain modelleri (saf Dart, Drift'ten bağımsız)
```dart
enum ScheduleKind { days, km, both, seasonal }
enum MeasureType { none, level, tires, number }
enum ItemState { overdue, soon, ok, unknown }
enum BindingDim { days, km }

class Schedule { kind; intervalDays?; intervalKm?; List<SeasonalDate> dates; }
class CheckItem { id; templateKey?; name; groupKey; schedule; measure; why; how; warn?;
                  startsFromInstall; appliesLastService; enabled; sortOrder;
                  lastDoneDay?; lastDoneKm?; lastValue?; snoozeUntilDay?; }
class ItemStatus { state; dueDay?; dueKm?; daysLeft?; kmLeft?; binding?; shortText; longText; sortKey; }
class Rules { onlyOverdue; oncePerDay; minTripMinutes; graceMinutes; fallbackAfterDays; }
```
`StatusCalculator.compute(item, currentKm, installDay, today) → ItemStatus` (01-spec §2). `SnapshotBuilder.build(vehicle, items, rules, installDay, today) → Map` (§5). İkisi de yan etkisiz; testler bunlara.

## 5. Snapshot şeması (Dart yazar, Kotlin okur)
```json
{
  "version": 1,
  "generatedAt": "2026-09-03T14:05:12+03:00",
  "car": { "address": "00:11:22:33:44:55", "name": "Uconnect", "km": 118420 },
  "rules": { "onlyOverdue": true, "oncePerDay": true, "minTripMinutes": 5,
             "graceMinutes": 2, "fallbackAfterDays": 7 },
  "items": [
    { "id": 12, "name": "Motor yağı seviyesi", "dueDay": "2026-08-26", "dueKm": null, "snoozeUntilDay": null },
    { "id": 21, "name": "Motor yağı ve yağ filtresi", "dueDay": "2027-03-12", "dueKm": 119900, "snoozeUntilDay": null }
  ]
}
```
Kotlin tarafı `org.json` ile okur; tarih karşılaştırması `yyyy-MM-dd` string karşılaştırmasıdır (leksikografik = kronolojik).

## 6. Platform köprüsü (`MethodChannel "com.beratarpa.carkeep/platform"`)

Dart → Kotlin:
| Metot | Argüman | Dönüş |
|---|---|---|
| `getBondedDevices` | – | `List<{name:String, address:String}>`; izin yoksa `PlatformException(code:"NO_PERMISSION")` |
| `hasBluetoothPermission` | – | bool |
| `requestBluetoothPermission` | – | bool (sonuç `onRequestPermissionsResult` ile döner) |
| `hasNotificationPermission` | – | bool (API < 33 → true) |
| `requestNotificationPermission` | – | bool |
| `isIgnoringBatteryOptimizations` | – | bool |
| `openBatteryOptimizationSettings` | – | – (`ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS`; başarısızsa `ACTION_APPLICATION_DETAILS_SETTINGS`) |
| `openAppSettings` | – | – |
| `writeSnapshot` | `json: String` | – |
| `readSnapshot` | – | String? |
| `drainPendingEvents` | – | `String` (JSON dizi), okuduktan sonra Kotlin diziyi boşaltır |
| `getBluetoothState` | – | `{connected: bool, since: long?, lastTrip: {...}?}` |
| `getLaunchAction` | – | `String?` (`overdue`), okununca temizlenir |
| `scheduleDailyWorker` | – | – (REPLACE) |
| `clearEngine` | – | – (prefs temizle + bildirimi iptal; "Verileri sıfırla") |
| `getSdkInt` | – | int |
| `debugSimulate` | `{event: "connect"\|"disconnect", minutes: int}` | – (yalnız `BuildConfig.DEBUG`) |
| `debugRunDailyWorker` | – | – (debug) |

Kotlin → Dart: `onLaunchAction(String)` (uygulama açıkken bildirime dokunulursa, `onNewIntent`).

Pending event kayıt biçimi:
```json
{ "type": "trip", "connectedAt": 1756900000000, "disconnectedAt": 1756901500000,
  "durationMin": 25, "counted": true, "notified": true, "overdueCount": 2, "note": "ok" }
{ "type": "snooze", "untilDay": "2026-09-04" }
{ "type": "fallback", "at": 1756990800000, "overdueCount": 1 }
```

## 7. EnginePrefs (Kotlin, `SharedPreferences("carkeep_engine", MODE_PRIVATE)`)
| Anahtar | Tip | Anlam |
|---|---|---|
| `snapshot_json` | String | son snapshot |
| `car_address` | String | seçili araç MAC'i (snapshot'tan kopya; receiver hızlı filtre için) |
| `connected_at` | Long (-1 = yok) | araç bağlantısının başladığı an |
| `last_notified_day` | String | `yyyy-MM-dd` |
| `prev_last_notified_day` | String | hızlı geri bağlanmada geri almak için |
| `last_notified_at` | Long | grace hesabı |
| `global_snooze_until_day` | String | bildirimden "Yarın" |
| `pending_events_json` | String | JSON dizi |
| `last_trip_json` | String | Ayarlar tanı satırı için |
| `launch_action` | String | ayrılmış, v1'de kullanılmaz (intent extra yeterli) |
Tüm yazımlar `commit()` (receiver ölmeden diske insin).

## 8. Kotlin bileşenleri
- **BtReceiver**: manifest, `exported=true`, filtre `ACL_CONNECTED`, `ACL_DISCONNECTED`. `EXTRA_DEVICE.address` ≠ `car_address` ise çık. `ReminderEngine.onConnected(ctx, now)` / `onDisconnected(ctx, now)`. Toplam süre < 1 sn hedef; ağır iş yok.
- **ReminderEngine**: 01-spec §7 birebir. Saf fonksiyon + prefs; test edilebilir olması için `evaluate(snapshot, state, now) → Decision` ayrı, yan etkiler `apply(decision)` içinde.
- **Notifications**: `ensureChannel(ctx)` idempotent; `buildOverdue(ctx, names, fallbackDays?)`; `cancel(ctx)`.
- **NotifActionReceiver**: `ACTION_SNOOZE` → prefs + cancel + pending event. `exported=false`.
- **DailyCheckWorker**: `OneTimeWorkRequest` + `initialDelay = sonraki 19:00 - now`, `uniqueWork "daily_check"`, çalışınca §7.2'yi uygular ve kendini yeniden planlar.
- **MainActivity**: `FlutterActivity`; channel; `onNewIntent` → `onLaunchAction`; izin isteği sonucu için `pendingResult` tutar.

## 9. Riverpod sağlayıcıları (`providers.dart`)
```
databaseProvider            → AppDatabase (tek örnek)
platformBridgeProvider      → PlatformBridge
vehicleRepoProvider, itemRepoProvider, logRepoProvider, tripRepoProvider, settingsRepoProvider
vehicleProvider             → Stream<Vehicle?>          (watch)
itemsProvider               → Stream<List<CheckItem>>   (watch, sort_order)
rulesProvider               → Stream<Rules>
todayProvider               → DateTime (dateOnly; test için override edilebilir)
statusesProvider            → List<(CheckItem, ItemStatus)>  (vehicle+items+today'den türetilir)
snapshotSyncProvider        → statusesProvider/rulesProvider değişince SnapshotBuilder → bridge.writeSnapshot (debounce 300 ms)
bluetoothStateProvider      → resume'da bridge.getBluetoothState
permissionsProvider         → resume'da üç izin durumu
launchActionProvider        → StateNotifier<String?>; main + onLaunchAction besler
```
`snapshotSyncProvider` uygulama yaşadığı sürece `ref.keepAlive()` ile ayakta; `main.dart` `ProviderContainer.read` ile başlatır.

## 10. Açılış sırası (`main.dart`)
1. `WidgetsFlutterBinding.ensureInitialized()`; DB aç; `PRAGMA foreign_keys`.
2. Seed'i yükle; `template_version` karşılaştır → `TemplateMerge`.
3. `drainPendingEvents` → `trips`/`settings`'e işle.
4. `getLaunchAction` → provider.
5. `scheduleDailyWorker`.
6. `runApp`. İlk frame sonrası `snapshotSyncProvider` tetiklenir (snapshot yazılır).
7. `AppLifecycleListener.onResume`: 3, 4 ve `bluetoothStateProvider`/`permissionsProvider` yenile.

## 11. Android yapılandırma
- `android/app/build.gradle(.kts)`: `minSdk 26`, `applicationId "com.beratarpa.carkeep"`, Kotlin, `androidx.core:core-ktx`, `androidx.work:work-runtime-ktx`. Release'te `isMinifyEnabled=true` olacaksa `proguard-rules.pro`'ya `-keep class com.beratarpa.carkeep.** { *; }` (receiver/worker sınıf adları manifest'te).
- `AndroidManifest.xml`: 07-android-notlar §2.
- İkon: basit anahtar/kontrol işareti, `flutter_launcher_icons` **kullanılmaz**; `mipmap` PNG'leri elle (T18).

## 12. Veri akışları
**Kayıt (Yaptım)**: sheet → controller → `logRepo.addLog` (transaction: insert log, update item last_*) → `itemsProvider` yayını → `statusesProvider` → `snapshotSyncProvider` → `writeSnapshot`.

**Kopma**: Bluetooth yığını → `BtReceiver` → `ReminderEngine.onDisconnected` → `EnginePrefs` oku → karar → `Notifications` → `pending_events_json` ekle. Uygulama süreci hiç uyanmaz.

**Bildirime dokunma**: `PendingIntent(MainActivity, extra)` → uygulama kapalıysa `getLaunchAction` main'de; açıksa `onNewIntent` → `onLaunchAction` → `launchActionProvider` → Home vurgu.

**Yarın**: `NotifActionReceiver` → prefs `global_snooze_until_day` + pending `snooze` → Dart drain → `settings.global_snooze_until_day` (Ayarlar'da "Yarına ertelendi" bilgisi).
