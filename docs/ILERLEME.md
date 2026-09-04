# İlerleme

Claude Code her ticket sonunda bu dosyayı günceller. Durum: `bekliyor` / `devam` / `bitti` / `engel`.

## Ortam
- Flutter: 3.47.2 (stable, revision d3b14c8769, 2026-08-26) — `C:\src\flutter`
- Dart: 3.13.2 (DevTools 2.60.0)
- AGP / Gradle / Kotlin: 9.1.0 / 9.3.1 / 2.4.0 (Flutter şablonu varsayılanı)
- JDK: OpenJDK 21.0.8 (Microsoft build) — `C:\Program Files\Android\openjdk\jdk-21.0.8`.
  `jvmTarget = 17`, `sourceCompatibility/targetCompatibility = 17`.
- Android SDK: `%LOCALAPPDATA%\Android\Sdk` — platform `android-36`, build-tools `36.1.0`,
  platform-tools `37.0.1`. Tüm lisanslar kabul edildi.
- `compileSdk = 36`, `targetSdk = 36`, `minSdk = 26` (K-14).
- Test cihazı: **Samsung SM-A556E (Galaxy A55 5G)**, Android 16, API 36, One UI.
  OEM pil kısıtı notu 07 §7'deki **Samsung** satırı geçerli (T17).
- Aracın Bluetooth'u: `Uconnect NM000000000N00000` — `12:34:56:78:9A:BC`
  (sistemde `device_type=Carkit` olarak işaretli).

### Ortam kurulumu notu
Bu makinede Flutter, Android SDK ve `java` PATH'te yoktu; T01 kapsamında kuruldu.
Kullanıcı ortam değişkenleri (`HKCU:\Environment`) ayarlandı:
`JAVA_HOME`, `ANDROID_HOME`, `ANDROID_SDK_ROOT` ve PATH'e
`C:\src\flutter\bin`, `%LOCALAPPDATA%\Android\Sdk\platform-tools`,
`%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest\bin`, `%JAVA_HOME%\bin`.
Yeni açılan terminallerde geçerli olur. Android Studio kurulmadı (gerekmiyor).

## Ticket durumu
| Ticket | Durum | Commit (`git log --grep`) | Not |
|---|---|---|---|
| T01 Proje iskeleti | bitti | `feat(T01)` | ortam kurulumu dahil; cihazda `flutter run` beklemede |
| T02 Drift şeması ve DAO'lar | bitti | `feat(T02)` | 75 test yeşil |
| T03 Seed ve şablon birleştirme | bitti | `feat(T03)` | 125 test yeşil |
| T04 StatusCalculator ve SnapshotBuilder | bitti | `feat(T04)` | 195 test yeşil; 06 §1'in 28 satırı ayrı test |
| T05 Platform köprüsü | bitti | `feat(T05)` | cihaz testi geçti, 13/13 |
| T06 Kurulum sihirbazı | bitti | `feat(T06)` | 268 test yeşil; cihazda uçtan uca doğrulandı |
| T07 Kontroller ekranı | bitti | `feat(T07)` | 293 test yeşil; K-22 sıralama düzeltmesi dahil |
| T08 Madde detayı | bitti | `feat(T08)` | 327 test yeşil; cihazda kayıt uçtan uca |
| T09 Km giriş | bitti | `feat(T09)` | 341 test yeşil |
| T10 Geçmiş | bitti | `feat(T10)` | 357 test yeşil; K-23 ve şema v2 dahil |
| T11 Ayarlar | bitti | `feat(T11)` | 425 test yeşil; cihazda doğrulandı |
| T12 Receiver, motor, bildirim | bitti | `feat(T12)` | 436 Dart + 58 Kotlin testi; **kontrol noktası: gerçek araba protokolü bekliyor** |
| T13 Pending events ve Bluetooth durumu | bitti | `feat(T13)` | 458 Dart + 58 Kotlin testi; cihazda doğrulandı |
| T14 DailyCheckWorker | bitti | `feat(T14)` | 458 Dart + 72 Kotlin testi; cihazda doğrulandı |
| T15 Snapshot senkronu ve yaşam döngüsü | bitti | `feat(T15)` | 477 Dart + 72 Kotlin testi; cihazda doğrulandı |
| T16 Hata/boş durumlar, metin turu | bitti | `feat(T16)` | 494 Dart + 72 Kotlin testi; cihazda doğrulandı |
| T17 Cihaz testi düzeltmeleri | atlandı | | gerçek araba protokolünün sonuçlarına dayanıyor; sonuçlar gelince açılacak |
| T18 Release | bitti | `feat(T18)` | 501 Dart + 72 Kotlin testi; release APK cihaza kuruldu ve çalışıyor |

## Cihaz testi

### T05 köprü kontrolü — 2026-09-03, SM-A556E / Android 16
Protokol 06 §3'te yok; T05 kabul kriterlerinden yazıldı. Etkileşimler `adb` ile
sürüldü, sonuçlar hem ekrandan hem `dumpsys`/`shared_prefs`'ten doğrulandı.

| # | Adım | Sonuç |
|---|---|---|
| 1 | Ortam | `getSdkInt 36`, `getManufacturer samsung` ✓ |
| 2 | İzinsiz `getBondedDevices` | `NO_PERMISSION` ✓ |
| 3 | `requestBluetoothPermission` | `true` → `hasBluetoothPermission true`; `dumpsys: granted=true USER_SET` ✓ |
| 4 | İzinli `getBondedDevices` | 6 cihaz, Uconnect listede, adres `dumpsys`'teki Carkit ile aynı ✓ |
| 5 | `requestNotificationPermission` | `true`; `dumpsys: granted=true USER_SET` ✓ (API 33+ gerçek akış) |
| 6 | `writeSnapshot` → `readSnapshot` | Aynı string. `shared_prefs/carkeep_engine.xml` doğrudan okundu: `snapshot_json` tam, Türkçe karakterler ve `"dueKm":null` bozulmamış, `car_address` snapshot'tan doğru ayıklanmış ✓ |
| 7 | `force-stop` + yeniden açılış | `readSnapshot` 335 karakter — kalıcı ✓ |
| 8 | `getBluetoothState` | `connected=false since=null lastTrip=null` ✓ (receiver T12'de) |
| 9 | `drainPendingEvents` boşken | `[]` → 0 olay ✓ |
| 10 | `openBatteryOptimizationSettings` | `com.android.settings/...RequestIgnoreBatteryOptimizations` doğrudan diyaloğu açıldı ✓ (denetim md. 20: 07 §6 yolu doğru) |
| 11 | Muafiyet verildikten sonra | `isIgnoringBatteryOptimizations true`; `dumpsys deviceidle whitelist` → `user,com.beratarpa.carkeep` ✓ |
| 12 | `openAppSettings` / `openNotificationSettings` | `InstalledAppDetails` ve `AppNotificationSettingsActivity` açıldı, geri dönüşte `MainActivity` ✓ |
| 13 | `scheduleDailyWorker` | Log: `daily check scheduled in 34 min` (18:25 + 34 = **19:00**, hedef saat doğru). `dumpsys jobscheduler`: `#DailyCheckWorker#` `RUNNABLE`, `RUN_ANY_IN_BACKGROUND allowed` ✓ |
| + | `onNewIntent` → `onLaunchAction` | Uygulama açıkken `--es carkeep_action overdue` → Dart'a `overdue` ulaştı ✓ |
| + | Soğuk başlatma | `force-stop` sonrası aynı intent → `getLaunchAction: overdue` ✓ |

### T12 motor kontrolü (debug simülasyonu) — 2026-09-03, SM-A556E / Android 16
Gerçek araba protokolünden önce, Ayarlar → Geliştirici üzerinden. Test için
"Silecek suyu" geçici gecikmiş yapıldı (1 Tem 2026), sonra düzeltme kaydı Geçmiş'ten
silinerek eski hâline döndürüldü.

| # | Adım | Sonuç |
|---|---|---|
| 1 | Kopmayı simüle et (2 dk) | `Skip(short_trip)`, bildirim yok; tanı satırı "3 Eyl 23:04, 2 dk, sürüş sayılmadı" ✓ |
| 2 | Kopmayı simüle et (25 dk) | Heads-up ≤1 sn. `dumpsys`: `channel=reminders importance=4 category=reminder flags=ONLY_ALERT_ONCE\|AUTO_CANCEL actions=2`, başlık "1 kontrol gecikti", metin "Silecek suyu", simge kendi drawable'ımız ✓ |
| 3 | Aynı gün ikinci 25 dk | `Skip(once_per_day)`, bildirim yok; tanı "25 dk sürüş, bugün zaten hatırlatıldı" (06 §3 adım 4 metni) ✓ |
| 4 | Bildirime dokunma (uygulama Ayarlar'da açık) | **İlk denemede sekme değişmedi** → `onLaunchAction` dinleyicisi eklendi; sonra Kontroller'e geçip Gecikmiş vurgulandı ✓ |
| 5 | "Yarın" | `global_snooze_until_day=2026-09-04`, `last_notified_at=-1`, bildirim kapandı, pending `snooze` yazıldı ✓ |
| 6 | Ertelemeden sonra 25 dk | `Skip(snoozed)` ✓ |
| 7 | Tepside bildirim varken yeni bildirim | K-25 öncesi sessiz güncelleme olurdu; iptal-önce-bas ile heads-up tekrar çıktı ✓ |
| 8 | `pending_events_json` | Üç trip olayı doğru alanlarla (`counted`/`notified`/`note`/`overdueCount`) sırayla birikti ✓ |

### T12 gerçek araba protokolü (06 §3)
| Tarih | Adım | Sonuç | Kopma → bildirim (sn) | Not |
|---|---|---|---|---|

## Notlar
Ticket dışında fark edilen şeyler buraya; dokunulmaz, kaydedilir.

### T01
- **Manrope statik ağırlıklar üretildi.** Google Fonts artık Manrope'u yalnız değişken
  font (`Manrope[wght].ttf`) olarak dağıtıyor. Flutter'da `fontWeight` değişken fontun
  `wght` eksenini kendiliğinden sürmez (`FontVariation` gerekir), bu yüzden `fontTools`
  ile 400/500/600/700/800 statik örnekleri üretilip `assets/fonts` altına konuldu.
  Türkçe karakterler (çğışöüÇĞİŞÖÜ) beş ağırlıkta da doğrulandı.
- **`flutter_riverpod` 2.6.1 seçildi**, 3.4.2 mevcut. 02-mimari §9 `StateNotifier` ve
  `ref.keepAlive()` diyor; bunlar Riverpod 2 sözlüğü. Riverpod 3'e geçmek API değişikliği
  ve bir karar maddesi gerektirir; v1 için 2.6.1'de kalındı.
- **`sqlite3_flutter_libs 0.6.0+eol` / `sqlcipher_flutter_libs 0.7.0+eol`**: `drift_flutter`
  0.3.1'in (pub'daki en son sürüm) çektiği en güncel sürümler bunlar; `+eol` etiketi
  yayıncının işareti, bizim seçimimiz değil. Değiştirilecek bir şey yok, kayıt için.
- **`cupertino_icons` kaldırıldı**: `flutter create` şablonundan geliyordu, T01 bağımlılık
  listesinde yok, hiçbir yerde kullanılmıyor.
- **`androidx.core:core-ktx` 1.18.0'da tutuldu**, 1.19.0 mevcut. 1.19.0'ın AAR
  meta verisi `minCompileSdk=37` istiyor; `sdkmanager`'da en yüksek stable platform
  `android-36` ve AGP 9.1.0 için tavsiye edilen üst sınır da 36. İlk derleme bu yüzden
  başarısız oldu, 1.18.0 (son `minCompileSdk=36` sürümü) ile geçti.
  Android 37 stable çıkınca ikisi birlikte yükseltilebilir.
- `flutter doctor` "Visual Studio" kategorisinde uyarı veriyor (Windows masaüstü C++
  bileşenleri eksik). Yalnız Android hedeflendiği için (K-01) önemsiz.
- Debug APK 152 MB (tüm ABI'ler + debug sembolleri). Release ölçüsü T18'de not edilecek.

### Doküman denetimi (T01 öncesi, tüm kit dosyaları karşılıklı okundu)
Aşağıdakiler ticket dışı; hiçbiri kendi başına düzeltilmedi. Karar gerektirenler işaretli.

#### Kritik — davranışı bozar
1. **`Snapshot.parse` JSON `null` değerlerini yanlış okuyor** (07 §4). Android `org.json`'da
   `optString("snoozeUntilDay")` JSON `null` için boş string değil, `"null"` metni döner;
   `.ifEmpty { null }` bunu yakalamaz. Sonuç: `"null" > "2026-09-03"` olduğu için
   `isSnoozed` her madde için `true` döner → gecikmiş liste hep boş → **hiç bildirim gelmez**.
   Aynı hata `dueDay` ve `car.address` için de var (`dueKm` zaten `isNull()` ile doğru yazılmış).
   → T12'de `isNull(key)` ile yazılacak. İskelet kodu (07) bağlayıcı değil (07 giriş notu).
2. **01-spec §7.1'in hızlı geri bağlanma dalı ölü.** §7.1 `ACL_CONNECTED` için "`connected_at`
   **doluysa** ve grace içindeyse iptal et" diyor; ama aynı paragraf `ACL_DISCONNECTED`'ta
   `connected_at := null` yapıyor. Kopmadan sonra `connected_at` daima boş olduğu için koşul
   hiç sağlanmaz, K-06'nın iptali çalışmaz. 07 §4 kodu doğru (grace kontrolünü `connected_at`
   kontrolünden **önce** yapıyor). → K-06 > 01-spec olduğu için kod davranışı esas alınacak.
3. **Yedek (sürüşsüz) bildirim, grace penceresini açıyor** (01-spec §7.2 + 07 §5).
   `DailyCheckWorker` `last_notified_at = now` yazıyor. Kullanıcı 19:00 bildirimini alıp
   `graceMinutes` (2 dk) içinde arabaya binerse `ACL_CONNECTED` bunu "hızlı geri bağlanma"
   sanır: bildirimi iptal eder ve `last_notified_day`'i geri alır.
   → **T14'te kapandı, K-20.** Yedek bildirim `last_notified_at` yazmıyor.
4. **Bildirim izni yokken motor bildirim basılmış gibi davranıyor** (07 §5 + §4).
   `showOverdue` izin yoksa sessizce `return` ediyor, ama `onDisconnected` ardından
   `last_notified_day/at` yazıyor ve `trip.notified = true` diyor. İzin sonradan verilirse
   o gün bildirim gelmez. → T12'de `showOverdue` başarı döndürsün, state ona göre yazılsın.
5. **"Tarih/km düzelt" bir kayıt silinince sessizce yok oluyor** (01-spec §3.4 + §3.6).
   Düzeltme log üretmiyor; kayıt silme `last_done_*`'ı yalnız loglardan yeniden hesaplıyor.
   Kullanıcı trigeri düzeltir, sonra ilgisiz bir kaydı silerse düzeltme kaybolur.
   → **T10'da kapandı, K-23.** Düzeltme `kind='fix'` ile bir kayıt satırı yazıyor.

#### Boşluk — kod yazmadan önce bir değer seçmek gerekiyor
6. **Aralık metni kuralı yok** (01-spec §2.4). Sadece örnek listesi var. Şablonda geçen
   **180, 1460 ve 1825 gün** örneklerin dışında. → T01'de şu kural uygulandı:
   `365 → "yılda bir"`, `30 → "ayda bir"`, `d%365==0 → "n yılda bir"`, `d%30==0 → "n ayda bir"`,
   aksi halde `"d günde bir"`. Böylece 180 → "6 ayda bir", 1460 → "4 yılda bir",
   1825 → "5 yılda bir". Örneklerin hepsiyle uyumlu.
7. **Yaklaşan/Zamanında sıralama anahtarı tanımsız** (01-spec §2.5). Yalnız gecikmiş için
   formül var ("bağlayıcı oran en negatif"). Gün ve km maddeleri aynı listede karışık;
   ortak ölçü hiçbir yerde yok. 06 §1 "normalize km" diyor ama tanımlamıyor; mockup üçüncü
   bir cevap veriyor (`kmLeft/100`) ve o da §2.5'in gecikmiş kuralıyla çelişiyor.
   → **T07'de kapandı, K-17; T07 cihaz testinden sonra K-22 ile düzeltildi.** Gecikmişte
   bağlayıcı oran, Yaklaşan/Zamanında'da "kaç gün sonra".
8. **`seasonal` maddenin oranı hesaplanamıyor.** Bağlayıcı oran bölen ister; mevsimsel
   maddenin `intervalDays`i yok. → 7. maddeyle birlikte karar (öneri: bölen = 365).
9. **1460 gün preset listesinde yok** (01-spec §3.7). Şablonda `battery_age` ve `aux_belt`
   1460 gün. Preset dışı bir değerde −/+ ne yapar tanımsız.
   → **T11'de kapandı, K-19.** 1460 preset listesine eklendi; adımlayıcı preset dışı değerde
   o yöndeki en yakın durağa gidiyor, durak yoksa değeri değiştirmiyor.
10. **`unknown` maddenin ana ekran alt satırı tanımsız** (01-spec §3.2). "Son: …" metni
    son yapılış yokken ne yazacak? Mockup'ta bu durum hiç yok.
    → **T07'de kapandı, K-18.** `Son yapılış girilmedi`.
11. **`both` maddede "yaklaşan" eşiği hangi boyutun eşiği** (§2.3 md.3) yazmıyor.
    → Bağlayıcı boyutun eşiği kullanılacak (§2.2 ile tutarlı tek okuma).
12. **Kayıt sonrası tepsideki bildirim ne olacak** tanımsız. Kullanıcı gecikmiş maddeleri
    kaydedince bildirim ekranda kalıyor; Dart'ın bildirimi iptal edecek kanal metodu yok.
    → **T15'te kapandı, K-27.** Motorun gecikmiş sayısı >0'dan 0'a düşünce iptal edilir.
13. **Mevsimsel maddeyi erken yapmak vadeyi ilerletmiyor.** "Son yapılıştan sonraki ilk tarih"
    kuralı gereği 20 Eki'de kışlık lastik takılırsa vade hâlâ 1 Kas kalır ve madde
    "2 gün kaldı" demeye devam eder. → **Kapandı, K-29.** Son yapılış vadeye 14 gün veya
    daha yakınsa o tarih yapılmış sayılıyor. 06 §1 satır 24'ün beklentisi değişti.
14. **`verified` / `sourceNote` hiçbir yere gitmiyor.** Seed'de zorunlu, T03'te doğrulanıyor,
    ama DB şemasında sütunu yok ve hiçbir ekranda görünmüyor. README kullanıcıya ◐/❌
    maddeleri kılavuzdan doğrulamasını söylüyor, ama uygulama hangi maddenin ◐ olduğunu
    göstermiyor. → **T16'da kapandı, K-28.** Sütunlar T02'de eklenmişti; madde detayında
    "Kılavuzdan doğrula: …" satırı olarak gösteriliyor.
15. **`custom` grubunun Türkçe başlığı yok.** Şema `group_key`'de `custom` bekliyor, seed'in
    `groups` sözlüğünde yok; madde ekleme ekranında grup alanı da tanımlı değil.
16. **Kural varsayılanları eksik**: "Sadece gecikmiş varsa" ve "Günde en fazla bir" için
    varsayılan yazmıyor. → İkisi de `true` alındı (mockup ve §7 örnekleriyle tutarlı).
17. **Tanı satırı metinleri eksik** (§3.7). Üç varyant tanımlı, motor yedi farklı `note`
    üretiyor (`short_trip`, `no_snapshot`, `snoozed`, `no_overdue`, `once_per_day`,
    `reconnect`, `ok`). 06 §3 adım 4 spec'te olmayan bir metin bekliyor ("Bugün zaten
    hatırlatıldı"). Ayrıca kaynağı §3.7'de Kotlin prefs, T13'te Drift `trips` tablosu.
    → **T12'de kapandı, K-24.** Sekiz nota sekiz metin; kaynak T13'te `trips`'e geçecek.
18. **`fallback` pending event'i hangi tabloya yazılacak belli değil.** `trips.note`
    listesinde `fallback` var ama event `connected_at`/`duration_min`/`counted` gibi
    NOT NULL sütunları dolduramıyor.
    → **T13'te kapandı, K-26.** `trips`'e yazılır, tanı satırından elenir.
19. **`trips.note` izin verilen değer listesi `no_snapshot`'ı içermiyor** (02-mimari §3).
    → **T12'de kapandı, K-24.** Sözlük sekiz değer: `no_snapshot` ve `no_permission` eklendi.
    02-mimari §3'ün satırı düzeltilmedi (kit dokümanı); K-24 onu geçersiz kılıyor.

#### Çelişki — öncelik kuralı çözmüyor
20. **`openBatteryOptimizationSettings` iki farklı Intent.** 02 §6:
    `ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS`, yedek `ACTION_APPLICATION_DETAILS_SETTINGS`.
    07 §6 kodu: `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` (paket URI'li doğrudan diyalog),
    yedek `ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS`. → 07 alınacak; K-01 (Play Store dışı)
    doğrudan diyaloğu açıkça destekliyor ve 07 §2 bunu tekrar ediyor.
21. **`getBluetoothState().lastTrip` tipi**: 02 §6 nesne diyor, 07 §6 kodu ham JSON string
    döndürüyor. → String alınıp Dart'ta parse edilecek (kod bağlayıcı olan taraf).
22. **06 §2 R1–R3 testleri JVM'de Robolectric'siz yazılamaz.** Test ettikleri `onConnected`
    `Context`, `SharedPreferences` ve `NotificationManager` kullanıyor; 07 §9 yalnız
    `evaluateDisconnect` ve `Snapshot.parse`'ın saf kalacağını söylüyor.
    → **T12'de kapandı.** `evaluateConnect(state, graceMinutes, now, previousTripConnectedAt)
    → ConnectDecision` saf; R1–R3 ve grace sınır durumları JVM testinde. Yan etkiler
    `onConnected`'ta kaldı.
23. **Şablon önceliği ters yazılmış.** 03-kontrol-listesi "çelişki olursa JSON düzeltilir,
    doküman değil" diyor (doküman kazanır); CLAUDE.md "Kontrol şablonu **yalnız**
    `checklist_seed.json`" diyor (JSON kazanır). Bugün içerik eşleşiyor, tek fark 24. madde.
24. **İki madde adı farklı**: doküman "Antifriz değişimi" / JSON "Antifriz (soğutma sıvısı)
    değişimi"; doküman "V kayışı değişimi" / JSON "V kayışı (aksesuar kayışı) değişimi".
    → Uygulamada JSON'daki adlar kullanılacak.
25. **CLAUDE.md'nin "mockup ile bilinen tek fark K-06" ifadesi doğru değil.** En az yedi fark
    daha var: kurulum 4 adım (spec 6), km "yaklaşan" eşiği 1500 (spec 1000), preset listeleri,
    sıralama anahtarı, "Bilinmiyor" bölümü yok, `both` maddede adımlayıcı davranışı,
    ayarlarda kural satırları. Hepsinde spec kazanıyor, davranışa etkisi yok; kayıt için.

#### Ticket sırası
26. **Snapshot'ı yazan mekanizma T15'te, ama T11 ve T12 ona dayanıyor.** T11 kabul kriteri
    "`readSnapshot` ile doğrulanır", T12 debug simülasyonu yazılmış snapshot istiyor.
    → `snapshotSyncProvider`'ın asgari hâli T11'de kurulacak, T15 onu tamamlayacak.
27. **T05 tek başına derlenmez.** MainActivity kanal işleyicisi `Snapshot.parse` (T12),
    `Notifications.cancel` (T12) ve `DailyCheckWorker.schedule` (T14) çağırıyor.
    → T05'te bu üçü için asgari iskelet sınıflar konacak, T12/T14 dolduracak.
28. **T07 kabul kriteri T11 bileşenine dayanıyor** ("Araba seçilmedi" şeridi → cihaz seçici).
    → T07'de şerit ayarlara yönlendirir, seçici T11'de.
29. **`lib/data/repositories/*` (5 dosya) ve `lib/providers.dart` hiçbir ticket kapsamında
    adı geçmiyor**, ama 02-mimari §2'de var ve her ekran bunlara dayanıyor.
    → İlk ihtiyaç duyulan ticket'ta (T06) üretilecek.
30. ~~T02'nin in-memory Drift testleri için host'ta native sqlite3 gerekiyor.~~
    **Çözüldü, iş yok.** Deneyle doğrulandı: `sqlite3.openInMemory()` bu Windows 11
    makinesinde `flutter test` altında çalışıyor (sistemin `winsqlite3.dll`'i bulunuyor).
    Ek bağımlılık gerekmiyor. Başka bir makinede kurulursa yeniden bakılmalı.
31. **T12'nin Kotlin JVM testleri için ne komut ne bağımlılık var.** `org.json` JVM'de
    yok (Android'e gömülü); `testImplementation("org.json:json:…")` gerekiyor ve CLAUDE.md
    komut listesinde Kotlin testi çalıştıran komut yok.
32. **07 §8 bildirim kanalının kapalı olmasını T16'ya havale ediyor**, ama T16 kapsamında
    bu iş yok ve durumu ölçecek kanal metodu tanımlı değil.
    → **T16'da kapandı.** Kanal metodu T05'te (`areNotificationsEnabled`), uyarı şeridi
    burada eklendi.
33. **T17 `Build.MANUFACTURER`'a göre OEM metni istiyor**, ama bu bilgiyi Dart'a taşıyan
    kanal metodu 02 §6'da yok.

#### Küçük, kayıt için
- `DayKey.daysBetween` negatif farkta yanlış: tam sayı bölmesi sıfıra kırpıldığı için
  −1 gün yerine 0 döner. Bugünkü çağrı yerlerinde fark hep pozitif, tetiklenmiyor.
- 06 §2'de C maddesi "yaklaşan" diye anılıyor ama `dueDay 2026-09-10` / `today 2026-09-03`
  için `daysLeft 7` > eşik 3, yani `ok`. Test sonucunu etkilemiyor (snapshot durum taşımıyor).
- `onlyOverdue=false` ve gecikmiş yokken `BigTextStyle` boş string ile kuruluyor.
- Tek `pendingPermission` alanı ve tek `REQ_PERM` kodu var; kurulum 3. adımda iki izin
  arka arkaya istenirse birinci `Result` kaybolur.
- §7.1 adım 3'ün "araç adresi eşleşmiyor → dur" yarısı `evaluateDisconnect`'te yok
  (receiver filtresinde var, ama `debugSimulate` receiver'ı atlıyor).
- Hızlı geri bağlanma "son trip kaydını düzeltir" diyor; kayıt Dart tarafından zaten
  drain edilmişse düzeltilemez, pending event'te DB satırıyla eşleşecek kimlik yok.
- 07 §6 notu `clearEngine`'i "02 §6 tablosuna ek metot" diye tanıtıyor, oysa tabloda var.
- `Snapshot.kt` 07 §4'te ayrı dosya, 02 §2 klasör listesinde yok.
- T16'nın metin turu kriteri (`grep` Türkçe özel karakter) "Km gir", "Bugün" gibi özel
  karakter içermeyen gömülü metinleri yakalamaz.
- `Ayarlar` adımlayıcısının ortasındaki kısa aralık metni (mockup: `15.000 km / 1 yıl`)
  spec'te tanımlı değil.
- Basınçta ondalık basamak sayısı, `number` ölçümünün `label` kullanımı ve kaydedilmiş
  değerinin metin biçimi, mevsimselde 2'den fazla tarih ayracı, "Tarih/km düzelt"te km üst
  sınırı, mevsimsel maddenin "Son: …" satırı ve adımlayıcısı: hepsi tanımsız, seçim yapıldı.
- Mockup'ta hiç karşılığı olmayan ekranlar: kurulum 3. ve 5. adımı, dört uyarı şeridi,
  Ayarlar'ın çoğu satırı, madde detayının "Servise git" / önceki kayıtlar / hedef basınç
  blokları, "Tarih/km düzelt" diyaloğu, Geçmiş kayıt detayı ve silme onayı, "Bilinmiyor"
  bölümü. Bunlar §10 token'ları ve mevcut satır düzeniyle üretilecek.
- 01-spec §10 Material 3 için gereken birincil (seed) rengi vermiyor; `ColorScheme` §10
  token'larından elle kuruldu (`primary = ink`).

### T02
- **Şemaya iki sütun eklendi**: `check_items.source_note` ve `check_items.verified`.
  02-mimari §3'te yoklar. Sebep: seed bu iki alanı taşıyor, T03 doğruluyor ve README
  kullanıcıya ◐/❌ maddeleri kılavuzdan doğrulamasını söylüyor; ama uygulamanın hangi
  maddenin ◐ olduğunu gösterebilmesi için değerin saklanması gerek (denetim md. 14).
  `schemaVersion 1`'de eklemek bedava, sonradan eklemek migration demek. **Şu an hiçbir
  ekranda gösterilmiyor**; gösterilip gösterilmeyeceği hâlâ açık karar (T08).
- **`LogDao.deleteLog` spec'e birebir yazıldı**: son yapılış yalnız kalan loglardan
  yeniden hesaplanıyor. Denetim md. 5'teki veri kaybı (elle girilen "Tarih/km düzelt"
  değerinin silinmesi) bu hâliyle duruyor; T10'da karara bağlanacak. Test edildi ve
  davranış belgelendi, sürpriz olmayacak.
- `LogDao.deleteLog` ertelemeyi **temizlemiyor** (yalnız `addLog` temizliyor). Spec
  §3.3 ertelemenin kayıtla temizlendiğini söylüyor, silme için bir şey demiyor.
- Testte `package:drift/drift.dart`'tan `isNull`/`isNotNull` gizlendi; matcher'daki
  aynı adlı sabitlerle çakışıyorlar.

### T03
- **Şablon toast metni henüz yok.** `TemplateUpgradeResult.addedCount` üretiliyor ama
  01-spec §5'teki "Şablona 2 yeni madde eklendi, Ayarlar'dan aç" metni `strings_tr`'ye
  T06/T15'te (toast'ı gösterecek yerde) eklenecek.
- **`SeedLoader.load()` henüz çağrılmıyor.** Açılış sırası (02-mimari §10) T15'te
  kuruluyor; şu an yalnız `SeedLoader.parse` test ediliyor ve testler asset dosyasını
  diskten okuyor (`rootBundle` widget testi olmadan kurulamıyor).
- **`data/repositories/item_repo.dart` T03'te üretildi.** Denetim md. 29: repository
  katmanı hiçbir ticket'ın kapsamında adı geçmiyor ama 02-mimari §2'de var; şablon
  kurulumu ve yükseltmesi için ilk ihtiyaç burada doğdu.
- `TemplateMerge.plan` yalnız `template_key`'e bakar; DB'deki aralık/ad/enabled
  hiç okunmaz. K-07'nin "kullanıcı değişiklikleri asla ezilmez" garantisi bu yüzden
  yapısal, gözden kaçmaya açık bir kontrol değil.

### T04
- **06 §1 tablosunun 28 satırı da ayrı test olarak yazıldı ve ilk denemede geçti.**
  Beklenen değerlerin hiçbirinde düzeltme gerekmedi; tablo tutarlı.
- **`both` maddede son yapılışın yalnız bir yarısı doluysa `unknown`** (denetim md.
  "both-yarim-son-yapilis"). Spec bu durumu tanımlamıyor. Gerekçe: `both`un iki vadesi
  var, biri hesaplanamıyorsa bağlayıcı boyut da seçilemez. Pratikte ulaşılamaz: "Tarih/km
  düzelt" diyaloğu `both` maddede km'yi zorunlu tutuyor (§3.4). İki test yazıldı.
- **`seasonal` + son yapılış null durumunda `startsFromInstall` yok sayılıyor.**
  §2.1 mevsimsel için koşulsuz `installDay - 1` diyor, `days` türündeki gibi bir
  `startsFromInstall` dalı yok. Literal okuma uygulandı; şablondaki tek mevsimsel madde
  (`winter_tires`) zaten `startsFromInstall=true`, yani fark gözlenemez.
- **`both` maddede "yaklaşan" eşiği bağlayıcı boyutun eşiği.** §2.3 md. 3 eşikleri
  boyuta göre veriyor, §2.2 bağlayıcı boyutu seçiyor; tek tutarlı okuma bu.
- **`lib/domain/item_grouping.dart` eklendi** (02-mimari §2'de yok). K-17'nin sıralama
  ve bölümleme kuralı; T07 widget'ı bunu çağıracak, iş mantığı widget'a girmesin diye
  domain'de. 11 test.
- `SnapshotBuilder` null alanları JSON'a **açıkça** `null` yazıyor (02-mimari §5 örneği
  böyle). Kotlin tarafı bunları `isNull(key)` ile okumak zorunda — denetim md. 1.
  Bunu doğrulayan bir test var (`"dueKm":null` metni aranıyor).

### T05
- **Kanal tablosuna 5 metot eklendi** (02-mimari §6'da yoklar), hepsi denetim
  bulgularının karşılığı:
  `getManufacturer` (md. 33, T17'nin OEM metni için), `areNotificationsEnabled` ve
  `openNotificationSettings` (md. 32, 07 §8 bildirim kanalı kapalıysa uyarı şeridi),
  `cancelNotification` (md. 12, kayıt sonrası tepsideki bildirimi kapatmak için —
  **metot var ama hiçbir yerden çağrılmıyor**, çağrılıp çağrılmayacağı hâlâ açık karar).
- **`Snapshot.kt`, `Notifications.kt`, `DailyCheckWorker.kt` T05'te asgari hâlleriyle
  yazıldı** (denetim md. 27): T05'in kendi kanal metotları bunlara bağımlı
  (`writeSnapshot` → `Snapshot.parseCarAddress`, `clearEngine` → `Notifications.cancel`,
  `scheduleDailyWorker` → `DailyCheckWorker.schedule`). `showOverdue` T12'de,
  `DailyCheckWorker.runOnce` T14'te doldurulacak.
- **Denetim md. 1 düzeltildi ve teste bağlandı.** `Snapshot.parse` artık her nullable
  alanı `isNull(key)` ile okuyor. `SnapshotTest.JSON null degerleri gercek null olarak
  okunuyor` ve `snoozeUntilDay null iken madde ertelenmis sayilmiyor` testleri bu hatanın
  geri gelmesini engelliyor.
- **`DayKey.daysBetween` negatif fark hatası düzeltildi** (`Math.floorDiv`); test var.
- **Kotlin JVM testleri kuruldu** (denetim md. 31): `testImplementation("org.json:json:20260814")`
  ve `kotlin("test")`. Komut: `cd android && ./gradlew :app:testDebugUnitTest`.
  Bu komut CLAUDE.md'nin komut listesinde yok; eklenmesi iyi olur.
  Şu an 22 test (DayKey 9, Snapshot 13), hepsi yeşil.
- **`lib/dev/bridge_check_screen.dart` geçici.** T05'in kabul kriterlerinin hepsi fiziksel
  cihazda doğrulanıyor ama gerçek ekranlar T06'da geliyor; test edilebilsin diye köprünün
  her metodunu çağıran bir ekran kondu. **T06'nın ilk işi bu dosyayı ve `app.dart`'taki
  yönlendirmeyi silmek.** İçindeki Türkçe literaller bilinçli (kullanıcı ekranı değil).
- `openBatteryOptimizationSettings` 07 §6'daki sırayı uyguluyor (doğrudan diyalog önce),
  02-mimari §6'daki sırayı değil — denetim md. 20, K-01 doğrudan diyaloğu destekliyor.
- `MainActivity` üst üste izin isteğinde önceki `Result`ı `false` ile kapatıyor
  (denetim "tek-pendingPermission-slotu"); kurulum 3. adımda iki izin arka arkaya isteniyor.
- **Cihaz testinde bulundu: `isBluetoothEnabled` eklendi.** Adaptör kapalıyken
  `getBondedDevices` hata değil **boş liste** dönüyor. Bu haliyle kurulum sihirbazının
  4. adımı (01-spec §3.1) "Eşleşmiş cihaz yok. Telefonu önce arabayla eşleştir." derdi —
  araba eşleşmiş olduğu halde yanlış yönlendirme. Yeni kanal metodu bu iki durumu
  ayırmayı mümkün kılıyor; **ayrı metin T06'da yazılacak** (`strings_tr`).
  Testte gerçekten yaşandı: Bluetooth kapalıyken 0 cihaz, açıkken 6 cihaz.

### T06
- **`lib/dev/bridge_check_screen.dart` silindi** (T05'te geçici konmuştu); `app.dart`
  artık `vehicles` boşsa kurulum, doluysa ana ekran gösteriyor.
- **Drift + `flutter_test` tuzağı, bir saat kaybettirdi, çözümü not ediyorum.**
  Drift bir sorgu akışı iptal edilince `StreamQueryStore.markAsClosed` içinde
  **sıfır süreli bir `Timer`** kurar. Widget testinde `ProviderScope` test sonunda
  dispose olduğunda bu zamanlayıcı asılı kalıyor; `flutter_test` "A Timer is still
  pending even after the widget tree was disposed" diyor **ve koşucu kilitleniyor**
  (10 dk timeout, çıktı yok). Çözüm: her widget testinin sonunda ağacı söküp
  **süre vererek** bir frame çevirmek:
  ```dart
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 10));
  ```
  `tester.pump()` süresiz çağrıldığında sahte saati ilerletmediği için sıfır süreli
  zamanlayıcıyı tetiklemez — süre vermek şart. `test/features/setup_widget_test.dart`
  içindeki `disposeTree` yardımcısı bu; sonraki widget testleri de kullanmalı.
- **Süresiz animasyon (`CircularProgressIndicator`) `pumpAndSettle`'ı sonsuza kilitler.**
  Cihaz listesi yükleniyor durumunda spinner vardı, kaldırıldı. Kod tabanında hiç
  `CircularProgressIndicator` yok; ekleyen olursa widget testleri asılır.
- **SnackBar'ın 4 sn'lik zamanlayıcısı** da test sonunda asılı kalıyor; uyarı
  doğrulayan testler `tester.pump(const Duration(seconds: 5))` ile süresini doldurmalı.
- **`lib/features/home/home_screen.dart` geçici yer tutucu.** Gerçek Kontroller ekranı
  T07'de; şu an yalnız araç adı, km ve bölüm sayıları var. T06'nın "Başla sonrası ana
  ekrana geçilir" kriteri için gerekliydi.
- **`lib/core/widgets/tr_date_field.dart` eklendi** (02-mimari §2'de yok), K-21 gereği.
  Ayrıştırma (`parseTrDateParts`) saf tutuldu, widget olmadan test ediliyor.
- **`lib/data/repositories/item_list_repo.dart` ve `settings_repo.dart`, `vehicle_repo.dart`
  eklendi** — denetim md. 29 (repository katmanı ticket'sızdı). `providers.dart` da
  02-mimari §9'a göre kuruldu.
- `main.dart` açılış sırasının 3. (drain) ve 4. (launch action) adımları hâlâ yok;
  02-mimari §10 T13/T15'te tamamlanacak.
- **`SetupController.finish()` `finished` bayrağıyla korunuyor**: ikinci çağrı ikinci
  araç yazmıyor (tek araç, K-01). Testi var.

### T07
- **K-17'yi cihazda gördükten sonra düzelttik (K-22).** Kararı sunarken oranın
  etkisini ters anlatmıştım: `kalan / aralık` oranında aynı gün kalan için küçük
  aralık **büyük** oran verir, yani sık madde arkaya düşer. Cihazda ana ekranda
  "Kışlık / yazlık lastik değişimi — 1 Kas" (59 gün), "Motor yağı seviyesi — 17 Eyl"
  (14 gün) satırının üstüne çıktı. K-22 ile Yaklaşan ve Zamanında artık
  `proximityKey` (kaç gün sonra) ile sıralanıyor; Gecikmiş spec'in emrettiği oranda
  kaldı. Düzeltme sonrası cihazda sıra: 17 Eyl → 3 Eki → 1 Kas → 2 Ara.
- **Testler gerçek bir hata yakaladı**: T06'da `PermissionsNotifier`'ın otomatik
  yenilemesini dispose yarışı yüzünden kaldırmıştım; ana ekranda hiçbir şey
  tazelemediği için uyarı şeritleri izinler verilmiş olsa da görünüyordu.
  `HomeScreen.initState` artık izinleri ve Bluetooth durumunu tazeliyor
  (`resume` bağlantısı T15'te).
- **Widget testlerinde `ListView` tembelliği**: 29 açık maddeyle alttaki bölümler
  ağaca hiç girmiyor ve `find` bulamıyor. Testlerde `keepOnly` yardımcısıyla
  yalnız ilgili maddeler açık bırakılıyor. Bu bir kod hatası değil, test kurgusu.
- **`lib/features/history/history_screen.dart` ve `settings/settings_screen.dart`
  geçici yer tutucu** (T10 ve T11). Alt gezinme T07 kapsamında olduğu için üçü de
  gerekliydi; `AppShell` `lib/app.dart` içinde (02-mimari §2'de ayrı dosya yok,
  kök yönlendirme zaten app.dart'ın işi).
- **Bildirim kanalı kapalıysa uyarı şeridi hâlâ yok.** 07 §8 bunu istiyor, 01-spec
  §3.2 dört şerit sayıyor ve kanal durumunu saymıyor (denetim md. 32). Köprüde
  `areNotificationsEnabled` hazır, `PermissionState` taşıyor; şerit T16'da eklenecek.
- Satıra dokunma (madde detayı, T08) ve "Km gir" (T09) şu an boş; bağlanacakları
  ticket'lar sırada.

### T08
- **Kayan nokta tuzağı, testin yakaladığı gerçek hata**: `2,3 - 2,0` çift duyarlıkta
  0,29999999999999982 çıkıyor, `>= 0,3` yanlış sonuç veriyordu ve 0,3 barlık sapma
  vurgulanmıyordu. `tireDeviates` artık onda birlik adımlarda karşılaştırıyor.
- **Cihazda görülen iki kusur düzeltildi**: alt sayfanın alt butonları sistem gezinme
  çubuğunun arkasında kalıyordu (`MediaQuery.viewPaddingOf` kadar boşluk eklendi);
  tarih alanındaki "Gün" kutusu dardı, metin kesiliyordu (flex ve dolgu ayarlandı).
- **`number` ölçümünün saklanan biçimi seçildi**: `6 mm`, ondalıklıysa `6,5 mm`
  (denetim "number-olcum-deger-metni"; spec tanımlamıyordu).
- **Denetim md. 5 hâlâ açık**: "Tarih/km düzelt" log üretmiyor, bir kayıt silinince
  `last_done_*` yalnız loglardan yeniden hesaplanıyor ve elle girilen düzeltme
  kayboluyor. T10'da (Geçmiş, silme) karara bağlanacak.
- **Denetim md. 12 hâlâ açık**: kayıt sonrası tepsideki bildirim iptal edilmiyor.
  Köprüde `cancelNotification` hazır ama çağrılmıyor; T15'te snapshot senkronuyla
  birlikte bağlanması mantıklı.
- Widget testlerinde alt sayfanın listesi de tembel; `scrollSheetTo` yardımcısı
  ölçüm bloğuna ve uyarı satırına kaydırıyor.
- Düzeltme diyaloğunun "ileri tarih" testi ay açılır listesine dokunmadan yazıldı:
  madde hazır bir tarihle açılıp yalnız günü ileri çekiliyor. Açılır listeyi
  test ortamında açmak kararsız çalışıyordu.

### T09
- **Cihazda bulunan kusur**: alan güncel km ile dolu açılıyor ama metin seçili
  gelmediği için yazmaya başlayınca sonuna ekliyordu (`118420` + `119950` →
  `1184201`). Artık açılışta tüm metin seçili; testi de var.
- **"Km gir" iki farklı yerde aynı metin**: ana ekrandaki bağlantı (01-spec §3.2)
  ve boş giriş uyarısı (§3.5). Spec ikisini de böyle yazıyor; widget testinde
  uyarı `SnackBar` içinde aranıyor.
- Km küçültme burada reddediliyor; geriye alma yalnız Ayarlar → Araç'tan
  (§3.7, onay diyaloğuyla) — T11'de gelecek.

### T10
- **Denetim md. 5 kapandı (K-23).** "Tarih/km düzelt" artık `kind='fix'` işaretli bir
  kayıt satırı yazıyor. Böylece son yapılış tek doğruluk kaynağı olan loglardan
  türemeye devam ediyor ve bir kayıt silindiğinde elle girilen değer kaybolmuyor.
  §3.4'ün "log satırı oluşturulmaz" cümlesinden bilinçli sapma; testi var.
- **Şema 1 → 2**: `check_logs.kind` eklendi, `check_logs.km` nullable oldu (gün bazlı
  bir maddenin düzeltmesinde km yoktur, uydurulmuyor).
- **Migration cihazda patladı, testler yakalayamadı.** Bütün DB testleri
  `NativeDatabase.memory()` ile sıfırdan kurduğu için hep `onCreate` yolunu izliyor,
  `onUpgrade` hiç çalışmıyordu. `TableMigration`'a `newColumns`/`columnTransformer`
  verilmeyince drift eski tablodan `kind` sütununu seçmeye çalışıp
  `no such column: kind` ile açılışta çöktü. `test/data/migration_test.dart` artık
  gerçek bir v1 şeması kurup dosya üzerinden yükseltiyor; **yeni her şema
  değişikliğinde bu dosyaya bir vaka eklenmeli.**
- Geçmiş satırının alt metni `değer, km. not`; düzeltme satırlarında `düzeltme`
  etiketi eklenir.

### T11
- **Snapshot senkronu kuruldu (denetim md. 26).** `snapshotSyncProvider` durum veya
  kural değişince 300 ms debounce ile `writeSnapshot` çağırıyor. `CarKeepApp` onu
  `watch` ediyor; böylece `main.dart` kablolaması olmadan da (widget testleri)
  ayakta. Kalan tetikleyiciler ve `resume` bağlantısı T15'te. Cihazda
  `shared_prefs/carkeep_engine.xml` içinde doğrulandı.
- **Cihaz listesi yükleme mantığı ortaklandı.** Kurulum 4. adımı ve Ayarlar'daki
  seçici aynı hata durumlarını (izin yok / adaptör kapalı / boş) göstermek zorunda;
  `data/platform/device_list.dart` içine taşındı, `DeviceListState` oraya taşındı.
- **Adımlayıcı preset dışı değerde yön korur.** K-19 "en yakın preset'e atlar"
  diyor; ama preset aralığının *dışındaki* bir değerde bu kural yön değiştirtiyor
  (3 günde − basınca 7'ye çıkardı). Karar: o yönde durak yoksa değer değişmez.
  Testi var (`interval_stepper_test.dart`).
- **`both` maddede −/+ yalnız km'yi değiştirir** (01-spec §3.7). Gün için satıra
  dokunup düzenleme sayfasından değiştiriliyor. Cihazda "Triger seti" (120.000 km)
  üst uçta olduğu için `+` sönük görünüyor — beklenen.
- **Madde formunun doğrulaması `domain/item_form.dart`'ta** (widget'ta iş mantığı
  yok). Aralık sınırları: gün 1–3650, km 100–200.000; presetlerin dışına elle
  çıkılabiliyor ama sınırsız değil.
- **Ayarlar satırında başlık ve değer 50/50 esnek.** Sabit 150 px değer sütunu
  cihazda uzun cihaz adını ("Uconnect NM000000000N00000") üç satıra bölüyordu.
- **`sqlite3` dev bağımlılık olarak eklendi.** Zaten drift üzerinden geliyordu;
  `migration_test.dart` doğrudan import ettiği için `depend_on_referenced_packages`
  uyarısı çıkıyordu. Yeni bir paket ağaca girmedi, 04-kararlar'a madde açılmadı.
- **Geliştirici bölümü satırları henüz iş yapmıyor** (ticket kapsamı: "T12'de
  bağlanır"). `kDebugMode` altında görünüyorlar ama `onTap` null; T12'de bağlanacak.
- Şablon maddesinde ölçüm tipi kilitli ve "Sil" yok; kullanıcı maddesi tam
  düzenlenebiliyor ve onayla siliniyor (kayıtları FK cascade ile gidiyor).

### T12
- **Denetim md. 4 kapandı, iki yarısıyla.** `showOverdue` artık `Boolean` dönüyor ve durum
  (`last_notified_*`, `trip.notified`) yalnız bildirim gerçekten basıldıysa yazılıyor.
  İkinci yarısı bağımsız denetimde çıktı: çalışma zamanı izni verili olsa da **kanal
  kapalıysa** `notify` sessizce düşüyor ve hata atmıyordu; `showOverdue` `true` dönüp o günü
  `once_per_day` ile yakıyordu. `areNotificationsEnabled` kontrolü eklendi (K-25).
- **K-25: bildirim basılmadan önce iptal ediliyor.** Sabit id 1001 + `setOnlyAlertOnce`
  birlikte, tepside duran eski bildirim varken yenisini "güncelleme" yapıyor ve Android
  heads-up'ı, sesi, titreşimi bastırıyor. Kullanıcı dünkü bildirimi silmediyse bugünkü
  hatırlatma sessizce düşerdi — ürünün tek vaadi bu. Cihazda doğrulandı.
- **K-24: not sözlüğü sekiz değere çıktı** (`no_snapshot` denetim md. 19, `no_permission`
  yeni) ve tanı satırı sekizini de karşılıyor (denetim md. 17). 06 §3 adım 4'ün beklediği
  "bugün zaten hatırlatıldı" metni cihazda göründü.
- **Denetim md. 22 kapandı.** `onConnected`'ın kararı saf `evaluateConnect`'e ayrıldı; 06 §2
  R1–R3 artık Robolectric'siz JVM testi. Aynı şekilde araç filtresi `addressMatches` olarak
  saflaştırıldı.
- **`onLaunchAction` dinleyicisi yoktu.** Kotlin uygulama açıkken bildirime dokunulduğunda
  kanaldan çağırıyordu ama Dart tarafında dinleyen kimse yoktu: cihazda bildirime dokununca
  uygulama öne geliyor, ama sekme değişmiyordu (T12 kabul kriteri). `CarKeepApp` artık
  dinliyor; vurgu anahtarı `launchActionSeqProvider` ile sayaçlı, böylece ikinci dokunuşta
  animasyon tekrar oynuyor.
- **Tarih alanında iki hata (T11'den, cihaz testinde çıktı).** (1) Yıl yalnız *ipucuydu*:
  kutu "2026" yazdığı için dolu görünüyor, alan boş olduğundan gün+ay girmek "Tarih gir"
  hatası veriyordu — hangi alanın eksik olduğu anlaşılmıyordu. Yıl artık gerçek değerle
  açılıyor. (2) Ay açılır kutusu dar diyalogda "Tem"i "Te" diye kırpıyordu.
- **`buildFeatures { buildConfig = true }`** eklendi; AGP 8+ `BuildConfig.DEBUG`i açıkça
  istemeden üretmiyor, `debugSimulate` buna dayanıyor.
- **Bağımsız denetim** (3 boyut + 3 karşı-denetçi, 13 aday bulgu → 5 doğrulandı). Kalan
  üç doğrulanmış bulgu bu notlarla kapandı; iki tanesi (K-24/K-25 kayıtları) belge eksiğiydi.
- Cihazda doğrulandı (SM-A556E, Android 16): 2 dk → `short_trip`, bildirim yok; 25 dk →
  heads-up ≤1 sn; ikinci 25 dk → `once_per_day`; bildirime dokunma → Kontroller'de vurgu;
  "Yarın" → `global_snooze_until_day` yazıldı, bildirim kapandı, sonraki simülasyon
  `snoozed`. Test için "Silecek suyu" geçici olarak gecikmiş yapıldı, sonra düzeltme kaydı
  Geçmiş'ten silinip eski hâline döndürüldü.
- **Açık kalan**: "Aç" eylem düğmesi bildirimi tepsiden düşürmüyor (gövdeye dokunmak
  `setAutoCancel` ile düşürüyor). K-25'in iptal-önce-bas düzeltmesi sonucu zararsız;
  T15'te `cancelNotification` bağlanınca birlikte ele alınacak (denetim md. 12).
- **Açık kalan**: uygulama simgesi hâlâ Flutter varsayılanı (`ic_launcher`); bildirimin
  durum çubuğu simgesi kendi vektörümüz. Hiçbir ticket kapsamında değil, T18'de bakılmalı.

### T13
- **Tanı satırının kaynağı prefs'ten `trips` tablosuna geçti** (01-spec §3.7). Kotlin'in
  `last_trip_json`'u yalnız motorun kendi işi; ekran drain edilmiş veriyi gösteriyor.
- **K-26**: yedek bildirim (`fallback`) `trips`'e yazılıyor ama tanı satırından eleniyor —
  "Son kopma:" diye bir kopma uydurmasın (denetim md. 18 kapandı).
- **`note IS NULL` satırları sessizce eleniyordu.** `fallback` filtresi `note = 'fallback'`
  karşılaştırmasıyla yazılmıştı; SQL'de `NULL = 'fallback'` → NULL, `NOT NULL` → NULL, yani
  notu olmayan her sürüş tanı satırından düşüyordu. Test yakaladı; `note IS NULL OR ...`
  oldu.
- **`bluetoothStateProvider` `providers.dart`'a taşındı.** 02-mimari §9 onu çekirdek
  sağlayıcılar arasında sayıyor; `features/home` altında kalınca yaşam döngüsü dosyası onu
  okumak için features'a bağımlı olacaktı.
- **`onNewIntent` artık eylemi tüketiyor.** Aksi halde bildirime dokunulduğunda önce
  `onLaunchAction`, hemen ardından `resume`'daki `getLaunchAction` aynı eylemi ikinci kez
  okuyordu. Kanal henüz bağlı değilse extra bırakılıyor, `getLaunchAction` alıyor.
- **T12'nin "uygulama kapalıyken bildirimden açılma" kriteri aslında burada tamamlandı**:
  `getLaunchAction` açılış sırasının 4. adımı (02-mimari §10) ve `main.dart`'ta değildi.
  T12'de yalnız uygulama açıkken çalışan yol test edilmişti.
- `main.dart` artık `ProviderContainer` kuruyor: açılışta 3. (drain) ve 4. (launch action)
  adımlar `runApp`'ten önce çalışıyor.
- Cihazda doğrulandı: 2 dk simülasyon → `pending_events_json` doldu; arka plana alıp geri
  dönünce dizi `[]` oldu ve tanı satırı "Son kopma: 4 Eyl 01:22, 2 dk, sürüş sayılmadı"
  yazdı; "Bağlanmayı simüle et" sonrası chip yeşil "bağlı, sürüşte".
- **Açık kalan**: `todayProvider` `resume`'da tazelenmiyor (gece yarısı geçişi) — T15.

### T14
- **Karar yine saf**: `ReminderEngine.evaluateFallback(snapshot, state, today, lastTripDay)`
  01-spec §7.2'nin koşullarını sırayla uyguluyor, `DailyCheckWorker` yalnız yan etkileri
  yapıyor. 14 JVM testi (eşik dahil/hariç, km maddesi elenmesi, 3 gün sessizlik, sürüşsüz
  gün sayısı).
- **K-20 uygulandı**: yedek bildirim `last_notified_day` yazıyor, `last_notified_at`e
  dokunmuyor. Cihazda prefs'te `last_notified_at` anahtarı hiç oluşmadı — doğrulandı.
- **K-25 burada da geçerli**: `showOverdue` `false` dönerse durum yazılmıyor.
- **Yedek bildirimin "basmadım" gerekçeleri `trips`'e yazılmıyor** (`fallback_off`,
  `recently_notified`); yalnız `adb logcat -s CarKeep` çıktısına düşüyorlar. K-24 sözlüğüne
  girmiyorlar çünkü hiçbir satıra yazılmıyorlar.
- **Geliştirici satırı artık kanala gidiyor** ve ardından drain ediyor; "Kopmayı simüle et"
  de öyle. Tanı satırı T13'ten beri `trips`'ten okuduğu için drain olmadan güncellenmiyordu.
- **06 §4'ün jobscheduler komutu eksik.** Android 14+ iş ad alanı (namespace) istiyor;
  `adb shell cmd jobscheduler run -f com.beratarpa.carkeep 1` "Could not find job" diyor.
  Çalışan hâli: `adb shell cmd jobscheduler run -f -n androidx.work.systemjobscheduler com.beratarpa.carkeep 1`
- Cihazda doğrulandı: açılışta `daily check scheduled in 1033 min` (01:47 + 1033 dk = 19:00);
  `dumpsys jobscheduler` → `#DailyCheckWorker#` `RUNNABLE`, `RUN_ANY_IN_BACKGROUND allowed`,
  `TIME=+17h12m`; `cmd jobscheduler run` ile tetiklendi → `fallback skipped: no_overdue` ve
  kendini yeniden planladı; 65 gün gecikmiş madde varken "Yedek işi şimdi çalıştır" →
  bildirim "1 kontrol gecikti / **Bir süredir sürüş yok.** Silecek suyu"; ikinci çalıştırma
  → `fallback skipped: recently_notified`; `fallback` satırı `trips`'e yazıldı ama tanı
  satırına girmedi (K-26). Test verisi geri alındı.

### T15
- **`vehicleProvider` da bir snapshot tetikleyicisi oldu.** Cihaz değişikliği durum listesini
  değiştirmiyor; yalnız `statusesProvider`'a bakan senkron, snapshot'ın `car` bloğunu
  güncellemeyebilirdi ve motor eski cihazı dinlemeye devam ederdi. 01-spec §6'nın on iki
  tetikleyicisinin her biri için test var.
- **K-27**: motorun gecikmiş saydığı madde sayısı >0'dan 0'a düşünce `cancelNotification`
  çağrılıyor (denetim md. 12 kapandı). Ölçüt ekranın Gecikmiş bölümü değil `engineOverdue`:
  ertelenmiş madde ekranda gecikmiş görünmeye devam eder (K-13) ama bildirime girmez.
  Yalnız **geçişte** iptal ediliyor; açılışta sayı zaten 0 ise dokunulmuyor, aksi halde az
  önce basılmış bir bildirimi silebilirdik.
- **Gece yarısı**: `resume` önce `todayProvider`'ı tazeliyor, sonra drain/launch action/
  izin/Bluetooth, en sonda snapshot. Sıra önemli — sonraki her hesap doğru güne göre.
- Cihazda doğrulandı: 35 gün gecikmiş madde + 25 dk simülasyon → bildirim; maddeyi "Yaptım"
  diye kaydedince `dumpsys notification` çıktısında CarKeep kaydı kalmadı, durum çubuğu
  temiz. Test verisi (düzeltme + Yaptım kayıtları) Geçmiş'ten silinerek geri alındı.

### T16
- **Türkçe literal kontrolü teste dönüştü** (`test/core/turkish_literals_test.dart`). Kabul
  kriteri `grep` diyordu; grep bir kez çalışıp geçer, test her koşuda tutar. Yorum ayıklayıcı
  dizge içindeki `//`yi (URL) korur, kendi doğruluğunu da test eder.
- **01-spec §9'un iki maddesi hiç uygulanmamıştı**:
  - *Kalıcı izin reddi*. `permDeniedPermanently` ve `openSettings` metinleri yazılmış ama
    hiçbir yerde kullanılmıyordu. Android'de "bir daha sorma"yı doğrudan okuyan API yok;
    ölçüt "soruldu + verilmedi + `shouldShowRequestPermissionRationale` false". "Soruldu mu"
    bilgisi Dart'ta (`settings.asked_*`) tutuluyor, yoksa ilk açılışta da kalıcı ret görünürdü.
    İzin isteme artık tek yerden (`PermissionsNotifier`), işareti o yazıyor.
  - *DB açılamadığında "Verileri sıfırla"*. Tam ekran hata vardı, buton yoktu. Kanal
    `deleteDatabase` ile veri dizinindeki `carkeep.sqlite*` dosyalarını siliyor; onay
    isteniyor, sonra "Uygulamayı kapatıp tekrar aç" yazıyor. Şablon bozuksa buton çıkmıyor —
    geliştirici hatası, veriyi silmek çözmez.
- **Bildirim kanalı kapalı şeridi** eklendi (07 §8 → denetim md. 32 kapandı). İzin verili ama
  kanal kapalıysa ayrı şerit; dokununca bildirim ayarları açılır.
- **K-28**: şablon aralığı doğrulanmamış maddelerde (`verified != true`) kaynak notu madde
  detayında "Kılavuzdan doğrula: …" olarak gösteriliyor (denetim md. 14 kapandı). 11 maddenin
  notu vardı ve hiçbiri hiçbir ekrana çıkmıyordu; README ise kullanıcıya bunları kılavuzdan
  doğrulamasını söylüyordu.
- **Taşma testleri iki kez yalan söyledi, ikisi de düzeltildi.**
  1. Test yüzeyi 800 dp genişti, telefon 411 dp. Cihazda taşan Bluetooth chip'i testte
     geçiyordu. Artık `tester.view` gerçek telefon ölçüsüne kuruluyor.
  2. Widget testi uygulama fontunu yüklemiyor; metinler yedek fontla ölçülüyordu ve
     genişlikler yanlış çıkıyordu (yanlış alarm da veriyordu). `test/test_fonts.dart`
     Manrope'un beş kesimini yüklüyor.
  Bu ikisinden sonra test gerçek hatayı yakalıyor: 1.3 ölçeğinde chip 26 px taşıyor.
- **Gerçek hata**: uzun cihaz adıyla ("Uconnect NM000000000N00000") Bluetooth chip'i 1.3
  yazı ölçeğinde ekrandan taşıyordu. `Flexible` + ellipsis. Cihazda 1.3'e alınıp
  doğrulandı, sonra ölçek 1.0'a döndürüldü.
- Simge düğmelerinin hepsinin `tooltip`u var (ekran okuyucu etiketi); dokunma alanlarının
  hepsi ≥48 dp. İkisi de test edildi.

### T18
- **Uygulama ikonu uyarlanabilir (adaptive) ikon.** `minSdk 26` olduğu için PNG mipmap'lere
  gerek yok; `mipmap-anydpi-v26/ic_launcher.xml` her cihazda kullanılıyor. Arka plan
  01-spec §10'un `green`i etrafında hafif eğim (#2E9E5B → #13603A) — uygulamanın "zamanında"
  rengi. Ön plan beyaz kontrol kutusu ve içinde onay: uygulamanın yaptığı iş bu. Aynı çizim
  temalı ikon (Android 13+) olarak da kullanılıyor, tek renk olduğu için sorun çıkarmıyor.
  Flutter'ın varsayılan logosu hem çekmecede hem bildirimin büyük simgesinde görünüyordu
  (T12 notu), ikisi de düzeldi. Eski PNG mipmap'ler dosyada duruyor ama API 26+'da hiç
  kullanılmıyor.
  **Dört tasarım denendi**: (1) arabanın üstüne binen kocaman onay, (2) araba silueti +
  köşede onay rozeti, (3) açık halka + onay, (4) kontrol kutusu + onay. İlk ikisi
  "clip-art araba" olduğu için, üçüncüsü yeterince ayırt edici olmadığı için elendi.
  Dördüncüde işaret küçültülüp kenar boşluğu verildi; ilk hâli maskeye yapışıyordu.
- **İmzalama**: `~/carkeep-upload-keystore.jks` (repo dışı), `android/key.properties` ile
  gösteriliyor, ikisi de `.gitignore`'da. Anahtar bulunamazsa release derlemesi debug
  imzasına düşüyor — temiz klonda derleme kırılmasın diye.
- **R8 açık** (`isMinifyEnabled` + `isShrinkResources`). Manifest'te adıyla yazılı bileşenler
  zaten korunuyor ama `proguard-rules.pro`'da açıkça tutuluyorlar: biri yeniden adlandırılırsa
  bildirim motoru sessizce ölür ve bunu ancak arabada fark ederiz.
- **Doğrulama, APK'nın kendi içinden**: `apkanalyzer dex packages` çıktısında
  `MainActivity`, `BtReceiver`, `NotifActionReceiver`, `DailyCheckWorker` özgün adlarıyla
  duruyor; `aapt2 dump xmltree` manifest kayıtlarını doğruluyor. Kalan sınıflar (motor,
  bildirim metinleri) beklendiği gibi karartıldı.
- **Boyut**: `app-release.apk` 56,4 MB (üç ABI birden), `app-arm64-v8a-release.apk` 19,7 MB,
  `app-armeabi-v7a-release.apk` 17,2 MB, `app-x86_64-release.apk` 21,0 MB.
- **Release cihaza kuruldu** (kullanıcı onayıyla). Release farklı anahtarla imzalı olduğu
  için debug'ın üstüne kurulamıyor; debug kaldırıldı, veri silindi. Öncesinde yedek alındı
  (`~/carkeep-veri-yedegi-son/carkeep.sqlite`), ama release `run-as`a kapalı olduğu için geri
  yüklenemiyor — kurulum sihirbazı aynı değerlerle elden dolduruldu (Fiat Egea 1.6 MultiJet
  2019, 150.386 km, Uconnect NM000000000N00000), iki izin `pm grant` ile, pil muafiyeti
  `deviceidle whitelist +` ile geri verildi.
- **Release doğrulaması, cihazda**: `dumpsys package` → `BtReceiver` her iki ACL eylemine
  kayıtlı (R8 sınıf adını korumuş, 06 §4 komutu); soğuk açılış `am start -W` → **TotalTime
  657 ms**; açılışta `daily check scheduled in 836 min` (05:03 + 836 = 19:00).
- **Kurulum sırasında dışarıdan verilen izin ekranda hemen görünmüyor.** `SetupState` kendi
  izin kopyasını tutuyor; kullanıcı sihirbazın ortasında Android ayarlarından izni verirse
  satır "Verilmedi" kalıyor, "İzin ver"e basınca (sistem diyaloğu açılmadan) tazeleniyor.
  Normal akışta görünmez; kayıt için.

### K-29 sonrası bağımsız denetim
3 boyut (tarih aritmetiği, aşağı akış, doküman tutarlılığı) + bir karşı-denetçi; 10 aday
bulgunun 5'i doğrulandı, 5'i elendi. Hepsi kapatıldı:

- **Gerçek hata (major).** K-29'un ilk hâli yalnız eşiğe bakıyordu. Son yapılış bir mevsimsel
  tarihin **üstündeyse** `nextSeasonalDate` o tarihi zaten tüketmiş oluyor; K-29 üstüne bir
  daha atlayınca tek yapılış iki ayrı tarihi yutuyordu. `[1 Kas, 10 Kas]` ve son yapılış
  1 Kas → vade 2026-11-10 yerine 2027-11-01 çıkıyor, 10 Kas işi hiç görünmüyordu. Böyle bir
  takvim erişilebilir: madde düzenleme sayfası mevsimsel tarih eklemeye izin veriyor.
  Düzeltme: iş **en yakın** tarihe aittir; sıradaki tarih geçmiş tarihten daha yakın değilse
  atlama yapılmıyor (`previousSeasonalDate`).
- **İki testim boşa geçiyordu.** "tarihin kendisinde" ve "tarihten sonra" vakaları şablonun
  151 gün aralıklı tarihleriyle K-29 dalına hiç girmiyordu; ikisi de #27/#28'in kopyasıydı ve
  biri var olmayan bir korumayı test ettiğini iddia ediyordu — hatayı gizleyen tam olarak o
  yorumdu. Yakın tarihli takvimle yeniden yazıldı; mutasyon testiyle iki yönde de doğrulandı
  (eski koşulla yeni testler patlıyor, K-29 tamamen kapalıyken özellik testleri patlıyor).
- **`docs/06-test-plani.md` hiç düzenlenmemişti.** K-29 "satır 24 değişti" diyordu ama tabloya
  dokunulmamıştı; CLAUDE.md o tabloyu normatif sayıyor (her satır bir test). Satır 24
  güncellendi, K-29 vakaları için 29–36 satırları eklendi, testler bu numaralarla eşleştirildi.
- **`docs/01-spec.md` §2.1** hâlâ koşulsuz "sonraki ilk tarih" diyordu; sapma notu eklendi.

### K-30 / K-31 (ticket dışı, kullanıcı isteği)
- **K-31 şablon maddesi silme.** K-07 silmeyi yasaklıyordu çünkü şablon yükseltmesi silineni
  geri ekliyordu (`TemplateMerge` "DB'de yok = yeni madde" sayıyor). Silinen `templateKey`
  artık `settings.deleted_template_keys` içinde; yükseltme birleştirmeden önce onları
  seed'den düşüyor. Testi mutasyonla doğrulandı: filtre kaldırılınca test kırmızı.
- Aynı gerekçeyle konmuş **ölçüm tipi kilidi** de kalktı (01-spec §3.7 güncellendi): madde
  tamamen silinip elle yeniden eklenebildiği için kilit yalnız sürtünme ekliyordu.
- **K-30 hareket doğrulaması.** İlk Play Services bağımlılığı; sürüm APK'sına maliyeti
  ölçüldü: arm64 20.618.620 → 20.883.177 bayt (**+265 KB**), R8 kullanılmayan her şeyi
  atıyor. `mapping.txt` `ActivityTransitionRequest/Result/Event` ve
  `ActivityRecognitionClient`'ın korunduğunu gösteriyor (`DetectedActivity` yok, çünkü
  yalnız sabit `IN_VEHICLE` kullanılıyor ve derleme sırasında gömülüyor).
- Testler ilk turda **üretim hatası** buldu: yeni kanal metotları eksik olduğunda
  `PermissionsNotifier.refresh()` tümüyle düşüyor ve Bluetooth/bildirim şeritleri
  kayboluyordu. Hareket okumaları artık en sonda ve ayrı `try` içinde.
- Cihazda hiç denenmedi. Adımlar `06 §3b` (12–19).

### Cihaz testi — 4 Eyl 2026, K-30/K-31 (Galaxy A55, SM-A556E, release APK)
Yapılanlar ve sonuçlar. Gerçek araba protokolü (§3) hâlâ çalıştırılmadı.

| Adım | Sonuç |
|---|---|
| Kurulum (aynı imza, üstüne) | Veri korundu: Egea, 150.386 km, Uconnect, 16 madde. Soğuk açılış 952 ms. |
| Receiver kaydı | `BtReceiver` (iki ACL action) ve `MotionReceiver` manifest'te kayıtlı. |
| Play Hizmetleri | Var; satır aktif, yardım metni normal hâlinde. |
| Hareket izni **reddedildi** | Anahtar kapalı kaldı, "Hareket izni verilmedi" uyarısı çıktı, izin `granted=false`. |
| Hareket izni **verildi** | `motion updates registered` — Play Services aboneliği gerçek cihazda kabul etti. Anahtar açık. |
| Soğuk açılış (düzeltme öncesi) | Abonelik **kurulmadı** (kayıt yok); arka plan→ön plan çevriminde kuruldu. K-34'ün ikinci yarısı buradan çıktı. |
| Soğuk açılış (düzeltme sonrası) | `motion updates registered` — açılışta kuruluyor. |
| İzin `pm revoke` ile geri alındı | `motion permission revoked: updates marked inactive`; uygulama açılınca **anahtar kendiliğinden kapandı**. K-33'ün iki yarısı da doğrulandı. |
| Sürüm derlemesi | arm64 19,9 MB; `mapping.txt` gerekli `ActivityTransition*` sınıflarının korunduğunu gösteriyor. |

Cihazda bulunan ve düzeltilen üç hata: **K-33** (izin geri alınınca bayrak bayat kalıyor),
**K-34** (yeniden başlatma aboneliği düşürüyor + soğuk açılışta kural okunamıyor).
Bağımsız inceleme (4 mercek, 9 ajan) aynı üçünü bağımsız olarak işaretledi; ayrıca
şu düzeltmeler ondan geldi: not sözlüğü testi yansımaya çevrildi (elle liste
`no_motion`'ı kaçırmıştı, sapmayı yakalayamıyordu), `MOTION_LEAD_MINUTES`'tan türetilen
totolojik test gerçek sınıra bağlandı, ölçüm tipi değişince eski biçimli `last_value`
siliniyor, `_MotionRow` `await` sonrası `ref` okumuyor.

**Yapılmadı:** gerçek yeniden başlatma denemesi (kullanıcının telefonu kullanımdaydı;
mantık JVM testli ve yükseltme yolunda aynı dal cihazda tetiklendi), şablon maddesi
silmenin cihazda denenmesi (kullanıcının gerçek verisini kalıcı olarak değiştirirdi).

## Bilinen sorunlar
Kapanmamış maddeler; hiçbiri v1'i engellemiyor.

- **Gerçek araba protokolü (06 §3) çalıştırılmadı.** Motor debug simülasyonuyla uçtan uca
  doğrulandı (T12–T15 cihaz notları), ama gerçek `ACL_DISCONNECTED` yayınıyla, gerçek Doze
  koşullarında ve arka arkaya üç günde hiç denenmedi. T17 bu sonuçlara göre açılacak.
- **Release APK cihaza kurulmadı** (yukarıda). Kurulunca 06 §3 adım 8 (yeniden başlatma
  sonrası receiver) ve başlangıç süresi de ölçülmeli.
- **Bildirimdeki "Aç" düğmesi bildirimi tepsiden düşürmüyor**; gövdeye dokunmak düşürüyor
  (`setAutoCancel` yalnız içerik niyetinde çalışıyor). K-25'in iptal-önce-bas düzeltmesi
  sonucu zararsız kıldı.
- **`onlyOverdue=false` modunda** ("Kontroller zamanında" bildirimi) K-27 gecikmiş sayısı
  sıfır olduğu için uygulamayı açınca bildirimi iptal ediyor. Mod zaten motorun çalıştığını
  görmek için; kayıt için not.
- **Hızlı geri bağlanma düzeltmesi drain'den sonra ulaşamıyor.** Kotlin son trip olayını
  yerinde düzeltiyor; Dart o olayı çoktan `trips`'e yazdıysa satır eski hâliyle kalıyor.
  Pencere birkaç saniye (kopma ile geri bağlanma arasında uygulamayı açmak gerekir) ve
  01-spec §7.3 bu sınıf kaybı v1 için kabul ediyor.
- **`DayKey.daysBetween` negatif farkta doğru ama hiç çağrılmıyor** — kayıt için.
- **Yedek bildirimdeki "kaç gündür sürmedin" sayısı `counted`'a bakmıyor.** `DailyCheckWorker.lastTripDay`
  son trip'in `disconnectedAt`'ini okuyor; `short_trip` ve K-30 `no_motion` trip'leri de "son sürüş"
  sayılıyor. Kararı etkilemiyor (yalnız bildirim metnindeki sayı), K-12'den beri böyle. Bağımsız
  incelemede işaretlendi; düşük.
- **Aynı anda iki izin isteği** `MainActivity.pendingPermission` tek yuva olduğu için ilk çağrıyı
  `false` ile kapatıyor. K-30 öncesinden beri böyle; pratikte iki diyalog aynı anda açılmıyor.
- Eski PNG mipmap'ler (Flutter logosu) APK'da duruyor, API 26+'da kullanılmıyor.
