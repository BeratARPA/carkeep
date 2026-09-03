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
- Test cihazı (marka, model, Android sürümü): **henüz bağlanmadı** — T05 kontrol noktasında doldurulacak.

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
| T04 StatusCalculator ve SnapshotBuilder | bekliyor | | |
| T05 Platform köprüsü | bekliyor | | kontrol noktası |
| T06 Kurulum sihirbazı | bekliyor | | |
| T07 Kontroller ekranı | bekliyor | | |
| T08 Madde detayı | bekliyor | | |
| T09 Km giriş | bekliyor | | |
| T10 Geçmiş | bekliyor | | |
| T11 Ayarlar | bekliyor | | |
| T12 Receiver, motor, bildirim | bekliyor | | kontrol noktası |
| T13 Pending events ve Bluetooth durumu | bekliyor | | |
| T14 DailyCheckWorker | bekliyor | | |
| T15 Snapshot senkronu ve yaşam döngüsü | bekliyor | | |
| T16 Hata/boş durumlar, metin turu | bekliyor | | |
| T17 Cihaz testi düzeltmeleri | bekliyor | | |
| T18 Release | bekliyor | | kontrol noktası |

## Cihaz testi (06 §3)
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
   sanır: bildirimi iptal eder ve `last_notified_day`'i geri alır. → **Karar gerekiyor**
   (öneri: yedek bildirim `last_notified_at` yazmasın, yalnız `last_notified_day` yazsın).
4. **Bildirim izni yokken motor bildirim basılmış gibi davranıyor** (07 §5 + §4).
   `showOverdue` izin yoksa sessizce `return` ediyor, ama `onDisconnected` ardından
   `last_notified_day/at` yazıyor ve `trip.notified = true` diyor. İzin sonradan verilirse
   o gün bildirim gelmez. → T12'de `showOverdue` başarı döndürsün, state ona göre yazılsın.
5. **"Tarih/km düzelt" bir kayıt silinince sessizce yok oluyor** (01-spec §3.4 + §3.6).
   Düzeltme log üretmiyor; kayıt silme `last_done_*`'ı yalnız loglardan yeniden hesaplıyor.
   Kullanıcı trigeri düzeltir, sonra ilgisiz bir kaydı silerse düzeltme kaybolur.
   → **Karar gerekiyor** (öneri: düzeltme de bir "düzeltme" satırı yazsın ya da
   `last_done_*` yeniden hesabı yalnız silinen log en son log ise yapılsın).

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
   → **Karar gerekiyor** (öneri: her üç bölümde de tek anahtar = bağlayıcı oran
   `kalan / aralık`, artan sıralama; gecikmiş için spec'in kuralına birebir uyar).
8. **`seasonal` maddenin oranı hesaplanamıyor.** Bağlayıcı oran bölen ister; mevsimsel
   maddenin `intervalDays`i yok. → 7. maddeyle birlikte karar (öneri: bölen = 365).
9. **1460 gün preset listesinde yok** (01-spec §3.7). Şablonda `battery_age` ve `aux_belt`
   1460 gün. Preset dışı bir değerde −/+ ne yapar tanımsız. → **Karar gerekiyor**
   (öneri: preset listesine 1460 eklensin; ayrıca adımlayıcı preset dışı değerden en yakın
   preset'e atlasın).
10. **`unknown` maddenin ana ekran alt satırı tanımsız** (01-spec §3.2). "Son: …" metni
    son yapılış yokken ne yazacak? Mockup'ta bu durum hiç yok. → **Karar gerekiyor**
    (öneri: `Son yapılış girilmedi`).
11. **`both` maddede "yaklaşan" eşiği hangi boyutun eşiği** (§2.3 md.3) yazmıyor.
    → Bağlayıcı boyutun eşiği kullanılacak (§2.2 ile tutarlı tek okuma).
12. **Kayıt sonrası tepsideki bildirim ne olacak** tanımsız. Kullanıcı gecikmiş maddeleri
    kaydedince bildirim ekranda kalıyor; Dart'ın bildirimi iptal edecek kanal metodu yok.
    → **Karar gerekiyor** (öneri: `cancelNotification` metodu eklensin, gecikmiş sayısı
    sıfırlanınca çağrılsın).
13. **Mevsimsel maddeyi erken yapmak vadeyi ilerletmiyor.** "Son yapılıştan sonraki ilk tarih"
    kuralı gereği 20 Eki'de kışlık lastik takılırsa vade hâlâ 1 Kas kalır ve madde
    "2 gün kaldı" demeye devam eder. → **Karar gerekiyor** (öneri: son yapılış tarihi
    yaklaşan mevsimsel tarihe `soonSeasonalDays` içindeyse o tarih yapılmış sayılsın).
14. **`verified` / `sourceNote` hiçbir yere gitmiyor.** Seed'de zorunlu, T03'te doğrulanıyor,
    ama DB şemasında sütunu yok ve hiçbir ekranda görünmüyor. README kullanıcıya ◐/❌
    maddeleri kılavuzdan doğrulamasını söylüyor, ama uygulama hangi maddenin ◐ olduğunu
    göstermiyor. → **Karar gerekiyor** (öneri: `source_note` sütunu + madde detayında not satırı).
15. **`custom` grubunun Türkçe başlığı yok.** Şema `group_key`'de `custom` bekliyor, seed'in
    `groups` sözlüğünde yok; madde ekleme ekranında grup alanı da tanımlı değil.
16. **Kural varsayılanları eksik**: "Sadece gecikmiş varsa" ve "Günde en fazla bir" için
    varsayılan yazmıyor. → İkisi de `true` alındı (mockup ve §7 örnekleriyle tutarlı).
17. **Tanı satırı metinleri eksik** (§3.7). Üç varyant tanımlı, motor yedi farklı `note`
    üretiyor (`short_trip`, `no_snapshot`, `snoozed`, `no_overdue`, `once_per_day`,
    `reconnect`, `ok`). 06 §3 adım 4 spec'te olmayan bir metin bekliyor ("Bugün zaten
    hatırlatıldı"). Ayrıca kaynağı §3.7'de Kotlin prefs, T13'te Drift `trips` tablosu.
18. **`fallback` pending event'i hangi tabloya yazılacak belli değil.** `trips.note`
    listesinde `fallback` var ama event `connected_at`/`duration_min`/`counted` gibi
    NOT NULL sütunları dolduramıyor.
19. **`trips.note` izin verilen değer listesi `no_snapshot`'ı içermiyor** (02-mimari §3).

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
    → **Karar gerekiyor** (öneri: `onConnected` mantığı da saf bir `evaluateConnect(...)
    → ConnectDecision` fonksiyonuna ayrılsın, yan etkiler ayrı kalsın).
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

## Bilinen sorunlar
