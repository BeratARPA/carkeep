# 06 — Test planı

## 1. StatusCalculator birim testleri (T04) — her satır bir test

Sabitler: `today = 2026-09-03`, `currentKm = 118.420`, `installDay = 2026-08-20`, eşikler `soonDays=3`, `soonKm=1000`, `soonSeasonalDays=14`. Seasonal tarihler `[1 Kas, 1 Nis]`.

| # | Takvim | Son yapılış | Ek | Beklenen durum | Kısa metin | Uzun metin |
|---|---|---|---|---|---|---|
| 1 | days 14 | 2026-08-12 | – | overdue, daysLeft −8 | `8 gün gecikti` | `8 gün gecikti. 14 günde bir.` |
| 2 | days 14 | 2026-08-31 | – | ok, daysLeft 11 | `14 Eyl` | `14 Eyl. 14 günde bir.` |
| 3 | days 14 | 2026-08-21 | – | soon, daysLeft 1 | `1 gün kaldı` | |
| 4 | days 14 | 2026-08-20 | – | soon, daysLeft 0 | `Bugün` | |
| 5 | days 14 | null | startsFromInstall=true | soon, daysLeft 0 (vade = install + 14 = 2026-09-03) | `Bugün` | |
| 6 | days 14 | null | startsFromInstall=false | unknown | `Tarih gir` | `Tarih gir. 14 günde bir.` |
| 7 | days 30 | 2026-08-05 | – | soon, daysLeft 1 | `1 gün kaldı` | `1 gün kaldı. Ayda bir.` |
| 8 | days 730 | 2025-09-16 | – | ok | `16 Eyl 2027` | `16 Eyl 2027. 2 yılda bir.` |
| 9 | km 30.000 | km 100.000 | – | ok, kmLeft 11.580 | `11.580 km kaldı` | `11.580 km kaldı. 30.000 km'de bir.` |
| 10 | km 30.000 | km 88.000 | – | overdue, kmLeft −420 | `420 km geçti` | |
| 11 | km 30.000 | km 89.000 | – | soon, kmLeft 580 | `580 km kaldı` | |
| 12 | km 30.000 | km 89.420 | – | soon, kmLeft 1.000 (eşik dahil) | `1.000 km kaldı` | |
| 13 | km 30.000 | null | – | unknown | `Tarih gir` | |
| 14 | both 15.000 / 365 | 2026-03-12, km 104.900 | – | ok; km bağlayıcı (oran 0,099 < 0,52), kmLeft 1.480 | `1.480 km kaldı` | `1.480 km kaldı. 15.000 km'de bir veya yılda bir.` |
| 15 | both 15.000 / 365 | 2025-09-10, km 110.000 | – | ok; gün bağlayıcı, daysLeft 7 | `10 Eyl` | |
| 16 | both 15.000 / 365 | 2025-08-20, km 110.000 | – | overdue; gün bağlayıcı, daysLeft −14 | `14 gün gecikti` | |
| 17 | both 15.000 / 365 | 2026-01-01, km 103.000 | – | overdue; km bağlayıcı, kmLeft −420 | `420 km geçti` | |
| 18 | both 1.000 / 100 | 2026-08-24, km 118.320 | oranlar eşit (0,9 / 0,9) | soon; eşitlikte km bağlayıcı, kmLeft 900 | `900 km kaldı` | |
| 19 | both | null | – | unknown | `Tarih gir` | |
| 20 | days 14 | 2026-08-12 | snoozeUntilDay 2026-09-04 | soon | `Yarın` | `Yarın. 14 günde bir.` |
| 21 | days 14 | 2026-08-12 | snoozeUntilDay 2026-09-03 | overdue (bugün > today değil) | `8 gün gecikti` | |
| 22 | days 14 | 2026-08-31 | snoozeUntilDay 2026-09-04 | ok (erteleme yalnız overdue'yu etkiler) | `14 Eyl` | |
| 23 | seasonal | 2026-04-05 | – | ok, dueDay 2026-11-01, daysLeft 59 | `1 Kas` | `1 Kas. Her yıl 1 Kas ve 1 Nis.` |
| 24 | seasonal | 2025-10-20 | – | **K-29 ile değişti:** overdue, dueDay 2026-04-01, daysLeft −155 | `155 gün gecikti` | K-29 öncesi 2025-11-01 / −306 idi; 20 Eki yapılışı 1 Kas 2025 değişimi sayılıyor |
| 25 | seasonal | 2026-04-05 | today = 2026-10-20 | soon, daysLeft 12 | `12 gün kaldı` | |
| 26 | seasonal | null | startsFromInstall=true | ok, dueDay 2026-11-01 | `1 Kas` | |
| 27 | seasonal | 2026-11-02 | – | ok, dueDay 2027-04-01, daysLeft 210 | `1 Nis 2027` | |
| 28 | seasonal | 2026-11-01 | – | ok, dueDay 2027-04-01 (aynı gün "sonraki" sayılmaz) | `1 Nis 2027` | |

Mevsimsel erken yapılış (K-29). Son yapılış vadeye `soonSeasonalDays` (14 gün) **veya
daha yakınsa ve geçmiş tarihten daha yakınsa** o tarih yapılmış sayılır, vade sıradaki
tarihe geçer. 29–31 varsayılan `[1 Kas, 1 Nis]` şablonuyla; 32–34 kullanıcının
ekleyebildiği yakın tarihli `[1 Kas, 10 Kas]` ile.

| # | Takvim | Son yapılış | Bağlam | Beklenen |
|---|---|---|---|---|
| 29 | seasonal | 2026-10-20 | 1 Kas'a 12 gün | dueDay 2027-04-01 (1 Kas yapılmış sayılır) |
| 30 | seasonal | 2026-10-18 | tam 14 gün, eşik dahil | dueDay 2027-04-01 |
| 31 | seasonal | 2026-10-17 | 15 gün, eşik dışı | dueDay 2026-11-01 |
| 32 | seasonal [1 Kas, 10 Kas] | 2026-11-01 | today 2026-11-01 | dueDay 2026-11-10 — tek yapılış iki tarihi yutmaz |
| 33 | seasonal [1 Kas, 10 Kas] | 2026-11-02 | today 2026-11-02 | dueDay 2026-11-10 |
| 34 | seasonal [1 Kas, 10 Kas] | 2026-11-06 | today 2026-11-06; 10 Kas'a 4, 1 Kas'a 5 gün | dueDay 2027-11-01 — yakın olan yapılmış sayılır |
| 35 | seasonal [1 Kas] | 2026-10-25 | tek tarihli madde | dueDay 2027-11-01 |
| 36 | seasonal | null | startsFromInstall, installDay 2026-10-25, today 2026-10-26 | dueDay 2026-11-01 — kurulum günü yedeği K-29'u tetiklemez |

Sıralama testleri: gecikmişler oran sırasında (#16 `−14/365 = −0,038` önce, #17 `−420/15000 = −0,028` sonra → #16 daha gecikmiş); yaklaşanlar `daysLeft` / normalize km ile artan.

SnapshotBuilder testleri: kapalı madde yok; `unknown` yok; `dueDay` `yyyy-MM-dd`; `dueKm` int veya null; `snoozeUntilDay` geçiyor; `car.address` null ise snapshot yine yazılır (motor araç eşleşmediği için susar).

TemplateMerge testleri: T03 kabul kriterleri.

## 2. ReminderEngine JVM testleri (T12, Kotlin `test/`)
`evaluateDisconnect(snapshot, state, today, durationMin)` saf fonksiyon (07 §4 imzası). Snapshot: 3 madde: A `dueDay 2026-09-01` (gecikmiş), B `dueKm 118.000` (gecikmiş, km 118.420), C `dueDay 2026-09-10`.

| # | Girdi | Beklenen |
|---|---|---|
| E1 | duration 2, minTrip 5 | Skip `short_trip` |
| E2 | duration 25, snapshot null | Skip `no_snapshot` |
| E3 | duration 25, globalSnooze 2026-09-04, today 09-03 | Skip `snoozed` |
| E4 | duration 25, A ve B snoozeUntilDay 09-04, C yaklaşan | Skip `no_overdue` (onlyOverdue=true) |
| E5 | E4 + onlyOverdue=false | Notify boş liste ("Kontroller zamanında") |
| E6 | duration 25, lastNotifiedDay = today, oncePerDay=true | Skip `once_per_day` |
| E7 | duration 25, lastNotifiedDay = dün | Notify [A, B] (sıra snapshot sırası) |
| E8 | duration 5 (eşik dahil) | Notify |
| E9 | oncePerDay=false, lastNotifiedDay = today | Notify |
| E10 | connectedAt yok (−1) | duration 0 → Skip `short_trip` |
| R1 | `onConnected` bildirimden 60 sn sonra, grace 2 | bildirim iptal, `last_notified_day = prev`, trip `reconnect`, `connected_at` korunur |
| R2 | `onConnected` bildirimden 5 dk sonra | yeni sürüş: `connected_at = now` |
| R3 | `onConnected` `connected_at` doluyken (çift bağlanma olayı) | `connected_at` korunur |

## 3. Gerçek araba protokolü (T12 sonu ve T17)
Ön koşul: telefon Uconnect ile eşleşmiş, kurulum bitmiş, Uconnect seçili, Bluetooth ve bildirim izni verilmiş, pil optimizasyonu kapatılmış, en az bir madde gecikmiş (Ayarlar'dan "Tarih/km düzelt" ile eski tarih verilerek yapılır).

| Adım | Yap | Bekle | Kaydet |
|---|---|---|---|
| 1 | Arabaya bin, kontağı aç, Uconnect bağlansın. Uygulamayı aç. | Chip "Uconnect bağlı, sürüşte". | Bağlanma saati (`adb logcat -s CarKeep`). |
| 2 | En az 6 dk sür. Kontağı kapat, arabadan in, telefonu cepte tut. | ≤ 30 sn içinde heads-up bildirim. | Kopma → bildirim süresi. |
| 3 | Bildirime dokun. | Uygulama Kontroller'de, Gecikmiş vurgulu. | |
| 4 | Aynı gün tekrar 6 dk sür, kontağı kapat. | Bildirim yok. Ayarlar tanı satırı "Bugün zaten hatırlatıldı". | |
| 5 | Ertesi gün: kontağı aç, 2 dk sonra kapat. | Bildirim yok, tanı "sürüş sayılmadı". | |
| 6 | Aynı gün 6 dk sür, kontağı kapat, **hemen** (≤ 1 dk) tekrar aç. | Bildirim çıkıp iptal olur; tanı "reconnect". Tekrar kapatınca bildirim gelir (grace dışı). | |
| 7 | "Yarın" eylemine bas, sonra tekrar sür. | O gün bildirim yok; ertesi gün var. | |
| 8 | Telefonu yeniden başlat, uygulamayı **açma**, sür, kapat. | Bildirim geliyor (manifest receiver reboot sonrası aktif). | |
| 9 | Ayarlar → Uygulama → pil "Kısıtlı" yap, sür, kapat. | Davranışı kaydet (OEM'e göre gelmeyebilir). Sonra "Kısıtlamasız"a al. | Cihaz marka/model, Android sürümü. |
| 10 | Uygulamayı "Durmaya zorla", sür, kapat. | Bildirim gelmez (beklenen Android davranışı). Uygulamayı bir kez aç, tekrar sür. | |
| 11 | 3 gün art arda normal kullanım. | Her gün ilk inişte (gecikmiş varsa) tek bildirim. | Günlük not. |

Her adımda `adb logcat -s CarKeep` çıktısı `docs/ILERLEME.md` "Cihaz testi" bölümüne özetlenir.

## 4. adb komutları
```
# receiver kayıtlı mı
adb shell dumpsys package com.beratarpa.carkeep | grep -A3 ACL

# Doze testi: force idle, sonra arabayla kopma yaşat (veya debugSimulate)
adb shell dumpsys battery unplug
adb shell dumpsys deviceidle force-idle
adb shell dumpsys deviceidle unforce
adb shell dumpsys battery reset

# app standby bucket
adb shell am get-standby-bucket com.beratarpa.carkeep
adb shell am set-standby-bucket com.beratarpa.carkeep restricted

# izinler
adb shell pm grant com.beratarpa.carkeep android.permission.BLUETOOTH_CONNECT
adb shell pm revoke com.beratarpa.carkeep android.permission.POST_NOTIFICATIONS

# WorkManager işini tetikle (JOB_ID dumpsys çıktısından)
adb shell dumpsys jobscheduler | grep -A5 com.beratarpa.carkeep
adb shell cmd jobscheduler run -f com.beratarpa.carkeep <JOB_ID>

# log
adb logcat -s CarKeep
```
`ACL_CONNECTED/DISCONNECTED` korumalı broadcast'tir; `adb shell am broadcast` ile gönderilemez. Simülasyon için Ayarlar → Geliştirici menüsü (`debugSimulate`) kullanılır.

## 5. Widget ve entegrasyon testleri (T06–T11, T15)
- Kurulum 6 adım akışı; zorunlu alan uyarıları; "Başla" sonrası DB içeriği.
- Ana ekran bölümleri ve sıralama; boş durum; uyarı şeritleri (provider override ile izin yok senaryosu).
- Madde detayı: level zorunlu, tires dört alan, number isteğe bağlı, hedef sapma vurgusu, düzeltme diyaloğu ileri tarih engeli.
- Km giriş doğrulamaları.
- Geçmiş silme → `last_*` geri alma.
- Ayarlar: kural değişikliği → `readSnapshot` (sahte bridge ile) beklenen JSON.
- `snapshotSyncProvider`: kayıt sonrası bridge'e çağrı sayısı 1 (debounce).
- Tüm testler `flutter test` altında; entegrasyon testi gerekiyorsa `integration_test/` ve fiziksel cihaz.

## 6. Yayın öncesi regresyon listesi (T18)
1. Temiz kurulum → kurulum sihirbazı → 34 madde.
2. Debug simülasyon: gecikmiş varken bildirim, yokken sessiz.
3. Gerçek kopma (§3 adım 2).
4. Yeniden başlatma sonrası receiver (§3 adım 8).
5. Release APK'da (R8) receiver ve worker sınıfları çalışıyor.
6. Yazı ölçeği 1.3'te taşma yok; 5,5" ekranda kurulum adımları kaydırılabilir.
7. Verileri sıfırla → kurulum → tekrar çalışıyor, eski snapshot silinmiş.
