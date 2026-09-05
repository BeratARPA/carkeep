# 04 — Kararlar (ADR)

Çelişkide en yüksek öncelikli doküman. Her karar: bağlam → karar → gerekçe → sonuç. Yeni karar eklemek için önce sor; onaylanınca buraya numarayla eklenir. Kararı geri almak da yeni bir karardır (eskisi silinmez, "iptal, bkz. K-xx" yazılır).

## K-01 Yalnız Android, Flutter, tek araç, sunucu yok
- Bağlam: Kişisel kullanım, tek telefon, tek araba. Kullanıcı Flutter/Riverpod biliyor (EasyTask).
- Karar: Flutter + Android; iOS, web, çoklu araç, bulut yok.
- Gerekçe: Tetikleyici (Bluetooth ACL broadcast) Android'e özgü; iOS'ta arka planda eşdeğeri yok. Sunucu, hesap ve senkron v1'in derdini çözmüyor, maliyet ekliyor.
- Sonuç: `flutter create --platforms android`. Veri yerel SQLite.

## K-02 Tetikleyici: arabanın Bluetooth'undan kopma
- Bağlam: Bildirimin "arabadan indiğin anda" gelmesi ürünün özü. Alternatifler: Android Auto, OBD, GPS geofence, sabit saat.
- Karar: `BluetoothDevice.ACTION_ACL_DISCONNECTED` (seçili cihaz) tetikler; `ACTION_ACL_CONNECTED` sürüş başlangıcını işaretler.
- Gerekçe: Android Auto kablolu bile olsa aramalar için arabanın Bluetooth'una bağlanır → tek sinyal iki senaryoyu kapsar. ACL broadcast'leri Android 8+ implicit broadcast kısıtından muaf; manifest receiver uygulama ölüyken çalışır. OBD donanım + veri değeri düşük (00-vizyon). GPS pil ve izin maliyeti; sabit saat ürün amacına aykırı.
- Sonuç: Kotlin `BtReceiver`. Android Auto ve OBD kapsam dışı.

## K-03 Bildirim ve kural motoru native Kotlin'de, Flutter motoru uyandırılmaz
- Bağlam: Receiver 10 sn içinde bitmeli; Flutter engine soğuk başlatma 1–3 sn ve bellek; Doze altında güvenilmez.
- Karar: Kural motoru (`ReminderEngine`), bildirim, WorkManager yalnız Kotlin. Dart yalnız "snapshot" üretir.
- Gerekçe: Bildirimin hızı ve güvenilirliği ürün başarı ölçütü (≤ 30 sn). Engine başlatmadan sadece prefs okuyup bildirim basmak ~50 ms.
- Sonuç: Dart ↔ Kotlin arasında iki tek yönlü kanal: snapshot (Dart→Kotlin), pending events (Kotlin→Dart). İş mantığı ikiye bölünmesin diye Kotlin **hesap yapmaz**, sadece `dueDay < today` / `dueKm < km` karşılaştırır.

## K-04 Aralık/durum hesabı tek yerde: Dart `StatusCalculator`
- Karar: Vade hesabı (gün, km, both, seasonal) yalnız Dart'ta. Snapshot vade değerlerini taşır.
- Gerekçe: Aynı kuralın iki dilde yazılması sapma üretir. Karşılaştırma triviyal, hesap değil.
- Sonuç: Kotlin'de tarih aritmetiği yok; sadece `yyyy-MM-dd` string karşılaştırması ve int karşılaştırması.

## K-05 Kendi MethodChannel'ımız, Bluetooth/bildirim plugin'i yok
- Bağlam: `flutter_blue_plus` BLE odaklı, bonded classic cihaz listesi ve ACL broadcast garantisi yok; `flutter_bluetooth_serial` bakımsız; `flutter_local_notifications` Dart'tan basar (K-03'e aykırı).
- Karar: Tek `MethodChannel` (`com.beratarpa.carkeep/platform`), ~10 metot, Kotlin'de elle.
- Gerekçe: İhtiyaç 3 şey: bonded liste, izin, prefs. Plugin bağımlılığı sürüm kırılması ve gereksiz izin getirir.
- Sonuç: `shared_preferences` de yok; prefs dosyası Kotlin'in (`carkeep_engine`), Dart kendi ayarlarını Drift `settings` tablosunda tutar.

## K-06 Kopmada beklemek yerine: hemen bildir, hızlı geri bağlanmada iptal et
- Bağlam: Mockup "2 dk geri bağlanma bekleniyor" gösteriyordu. Receiver'da beklemek yasak; `AlarmManager` exact alarm Android 12+'da izin ister, 14+'ta varsayılan kapalı; WorkManager gecikmesi dakikalarca kayabilir; receiver'dan foreground service başlatma Android 12+'da kısıtlı.
- Karar: `ACL_DISCONNECTED` gelir gelmez kurallar uygulanır ve bildirim basılır. `graceMinutes` (varsayılan 2) içinde aynı cihaz `ACL_CONNECTED` olursa bildirim iptal edilir, `last_notified_day` eski değerine döner, sürüş devam ediyor sayılır.
- Gerekçe: Kullanıcı açısından sonuç aynı (sahte kopmada bildirim kalmaz), teknik olarak sıfır zamanlayıcı.
- Sonuç: 01-spec §7.1. Mockup'la bilinen tek fark budur.

## K-07 Şablon JSON asset'i, kurulumda DB'ye kopyalanır, sürümlü
- Karar: `assets/seed/checklist_seed.json` `version` taşır; kurulumda satırlar `check_items`'a kopyalanır; yükseltmede yalnız yeni maddeler eklenir, kullanıcı değişikliği ezilmez.
- Gerekçe: Kullanıcı aralıkları düzenler; şablonu her açılışta yeniden okumak bu düzenlemeleri kaybettirir. DB'de kopya = kullanıcının verisi.
- Sonuç: `TemplateMerge` domain fonksiyonu + test.
- **K-31 ile gevşetildi**: şablon maddesi silinebiliyor; silinen anahtarlar yükseltmede seed'den düşülüyor.

## K-08 Riverpod codegen yok; Drift codegen var
- Karar: `flutter_riverpod` ile `Notifier`/`AsyncNotifier`/`StreamProvider` elle; `riverpod_generator` yok. Drift için `build_runner` zorunlu.
- Gerekçe: Codegen'i tek kaynağa (Drift) sınırlamak build kırılma yüzeyini küçültür.
- Sonuç: `dart run build_runner build` yalnız `*.g.dart` (Drift) üretir.

## K-09 Türkçe metinler tek dosyada, l10n framework yok
- Karar: `lib/core/strings_tr.dart` sabitleri. `intl`/ARB yok.
- Gerekçe: Tek dil. Framework maliyeti sıfır fayda.
- Sonuç: Çoklu dil gerekirse ARB'ye geçiş ayrı karar.

## K-10 Tarihler yerel takvim günü, `yyyy-MM-dd` anahtar
- Karar: Vade ve karşılaştırmalar takvim günü bazında; saat yok; UTC dönüşümü yok.
- Gerekçe: "2 haftada bir" saatle ilgisiz; gün anahtarı iki dilde de sıralanabilir string.
- Sonuç: `DateUtils.dateOnly`, `DayKey` (Kotlin `SimpleDateFormat("yyyy-MM-dd", Locale.US)`, yerel saat dilimi).

## K-11 Km yalnız kullanıcıdan; GPS tahmini yok
- Karar: Km girişi elle (yakıt alırken). Km bazlı maddeler "yaklaşan" eşiği 1.000 km ile toleranslı.
- Gerekçe: GPS = arka plan konum izni + foreground service + pil; v1 için fazla. Km maddeleri aylarca vadeli, birkaç yüz km sapma önemsiz.
- Sonuç: v2 adayı (00-vizyon).

## K-12 Sürüşsüz dönem yedeği: kendini yeniden planlayan WorkManager işi
- Karar: `DailyCheckWorker`, hedef 19:00, koşul: gecikme ≥ `fallbackAfterDays` (varsayılan 7) ve son 3 gün bildirim yok.
- Gerekçe: Araba kullanılmıyorsa ACL olayı yok; kullanıcı unutulmuş sanmasın. Exact alarm izni istemeden "yaklaşık akşam" yeterli.
- Sonuç: Yalnız gün bazlı maddeler (km maddeleri sürüşsüz artmaz).

## K-13 Bildirim eylemleri: "Aç" ve "Yarın"; bildirimden "Yaptım" yok
- Karar: Bildirimden kayıt oluşturulmaz.
- Gerekçe: Ölçüm değeri girmeden "yaptım" demek verinin değerini düşürür; ayrıca native tarafın DB'ye yazması K-03/K-04'e aykırı.
- Sonuç: "Yarın" = o gün için global erteleme (yalnız bildirim bastırır, ekranda gecikmiş görünmeye devam eder).

## K-14 Sürüm ve paket
- Karar: Uygulama adı "CarKeep", `applicationId com.beratarpa.carkeep`, proje adı `carkeep`, `minSdk 26`, `versionCode` her release'te +1.
- Gerekçe: Bildirim kanalları API 26+; daha eski cihaz yok.
- Sonuç: T01 ve T18.

## K-15 Bilinmeyen servis geçmişi "Bilinmiyor" olarak bekler, uydurulmaz
- Karar: Son yapılışı bilinmeyen km/both maddeleri `unknown`; snapshot'a girmez; bildirim üretmez. Fiziksel gün bazlı maddeler kurulum gününden başlar.
- Gerekçe: Yanlış vade → yanlış bildirim → güven kaybı. Triger için "bilmiyorum" doğru cevaptır; kullanıcı girene kadar liste bekler.
- Sonuç: Detay sayfasında "Tarih/km düzelt" öne çıkar.

## K-16 Kapsam dışı sabit listesi
Android Auto, OBD-II, GPS, çoklu araç, bulut/hesap, iOS, yakıt/harcama, servis randevusu, Play Store yayını, karanlık tema, çoklu dil. Bunlardan biri gündeme gelirse yeni karar + yeni sürüm; v1 ticket'larına eklenmez.

---

Aşağıdakiler T01 sonundaki doküman denetiminde bulunan boşluklar/hatalar için alınmış,
onaylanmış kararlardır. Ayrıntılı bulgu listesi `docs/ILERLEME.md` → Notlar → "Doküman denetimi".

## K-17 Sıralama anahtarı: her bölümde bağlayıcı oran
> **Kısmen iptal, bkz. K-22.** Gecikmiş bölümü için geçerli; Yaklaşan ve
> Zamanında bölümleri K-22'ye göre sıralanır.

- Bağlam: 01-spec §2.5 yalnız Gecikmiş için formül veriyor ("bağlayıcı oran en negatif"). Yaklaşan ve Zamanında için sadece "en yakın önce" yazıyor; gün ve km maddeleri aynı listede karışık ve ortak ölçü tanımsız. 06-test-planı §1 "normalize km" diyor ama tanımlamıyor. Mockup üçüncü bir cevap veriyor (`kmLeft/100`) ve o da §2.5'in gecikmiş kuralıyla çelişiyor.
- Karar: Dört bölümün hepsinde tek sıralama anahtarı `sortKey = bağlayıcı kalan / bağlayıcı aralık`, artan. `days` için `daysLeft / intervalDays`, `km` için `kmLeft / intervalKm`, `both` için §2.2'nin seçtiği bağlayıcı boyutun oranı, `seasonal` için `daysLeft / 365`. `unknown` bölümü şablon sırasında kalır (§2.5).
- Gerekçe: Gecikmiş için spec'in yazdığı kuralın birebir kendisi; aynı anahtarı diğer bölümlere uzatmak ikinci bir sıralama mantığı yazmayı önler ve gün/km maddelerini karşılaştırılabilir kılar. Mockup burada spec ile çeliştiği için kullanılamaz (CLAUDE.md: spec kazanır).
- Sonuç: `ItemStatus.sortKey` double. Ertelenmiş maddenin `sortKey`'i ertelemeden etkilenmez (negatif kalır), yani Yaklaşan bölümünün başında görünür.

## K-18 "Bilinmiyor" maddenin liste alt satırı
- Bağlam: 01-spec §3.2 satır alt metnini `Son: 12 Ağu, Orta` olarak tanımlıyor ama son yapılışı olmayan maddede ne yazacağını söylemiyor; mockup'ta bu durum hiç yok.
- Karar: Alt satır `Son yapılış girilmedi`.
- Gerekçe: Satır yüksekliği diğerleriyle aynı kalır ve kullanıcıya ne yapması gerektiğini söyler; sağdaki durum metni zaten `Tarih gir`.
- Sonuç: `strings_tr.dart` → `S.lastDoneMissing`.

## K-19 Gün preset listesine 1460 eklendi
- Bağlam: Şablonda `battery_age` (akü yaşı) ve `aux_belt` (V kayışı) `days: 1460`; 01-spec §3.7 gün preseti `7,14,30,60,90,180,365,730,1825`. Şablon değeri preset üzerinde durmuyor, −/+ davranışı tanımsız.
- Karar: Gün preseti `7,14,30,60,90,180,365,730,1460,1825` olur. Şablondaki aralık değerleri **değişmez** (03-kontrol-listesi kuralı korunur); yalnız adımlayıcının durakları genişler. Adımlayıcı preset dışı bir değerde durursa en yakın preset'e atlar.
- Gerekçe: Kullanıcı 4 yılı bir kez değiştirdikten sonra geri dönemiyor olmamalı.
- Sonuç: `constants.dart` → `kIntervalDaysPresets`.

## K-20 Yedek bildirim `last_notified_at` yazmaz
- Bağlam: `DailyCheckWorker` (01-spec §7.2) bildirimi bastıktan sonra `last_notified_at = now` yazıyor. K-06'nın hızlı geri bağlanma dalı bu alanı okuyor: kullanıcı 19:00 yedek bildirimini alıp `graceMinutes` içinde arabaya binerse `ACL_CONNECTED` bunu sahte kopma sanıp bildirimi iptal ediyor ve `last_notified_day`'i geri alıyor.
- Karar: Yedek bildirim yalnız `last_notified_day` (ve `prev_last_notified_day`) yazar; `last_notified_at`'e dokunmaz. Bu alan yalnız gerçek kopma bildirimlerinde set edilir.
- Gerekçe: `last_notified_at`'in tek işi K-06'nın grace penceresini ölçmek; yedek bildirimin bir kopmayla ilgisi yok, dolayısıyla pencere açmamalı. "Günde en fazla bir" kuralı `last_notified_day` üzerinden çalıştığı için bozulmaz.
- Sonuç: 01-spec §7.2 ve 07 §5 `runOnce` buna göre uygulanır (T14).

## K-21 Tarih girişi kendi bileşenimiz, `flutter_localizations` yok
- Bağlam: Kurulum 5. adımı ve "Tarih/km düzelt" (01-spec §3.4) geçmiş bir tarih ister. Flutter'ın `showDatePicker`'ı Türkçe görünmek için `flutter_localizations` ister; o da `intl`'i dolaylı bağımlılık olarak getirir (K-09 `intl` kullanmıyor).
- Karar: `lib/core/widgets/tr_date_field.dart` — gün / ay / yıl üçlüsü, ay açılır listede `format_tr` kısaltmalarıyla (Oca…Ara). Bugünden ileri tarih seçilemez. `showDatePicker` ve `flutter_localizations` kullanılmaz.
- Gerekçe: Girilen tarihler tipik olarak aylar veya yıllar öncesi (triger 5 yıl, muayene 2 yıl, poliçe 1 yıl); takvimde geriye kaydırmaktan hızlı. Yeni bağımlılık yok, her metin `strings_tr`'de kalır.
- Sonuç: T06 adım 5 ve T08 düzeltme diyaloğu bu bileşeni kullanır.

## K-22 Yaklaşan ve Zamanında: gerçekten "en yakın önce"
- Bağlam: K-17 üç bölümde de `kalan / aralık` oranını kullanıyordu. Kararı sunarken oranın etkisini **ters** anlatmıştım ("aynı gün kalanda sık olan öne geçer"); gerçekte küçük aralık *büyük* oran verir, yani sık madde arkaya düşer. Cihazda görüldü: kurulumun ardından ana ekranda "Kışlık / yazlık lastik değişimi — 1 Kas" (59 gün, oran 0,162), "Motor yağı seviyesi — 17 Eyl" (14 gün, oran 1,0) satırının üstünde çıktı. 01-spec §2.5 bu iki bölüm için "en yakın önce" diyor; oran bunu vermiyor.
- Karar: İki anahtar.
  - **Gecikmiş**: değişmedi — `ItemStatus.sortKey` = bağlayıcı kalan / bağlayıcı aralık, artan. §2.5'in emrettiği kural bu.
  - **Yaklaşan ve Zamanında**: `ItemStatus.proximityKey` = kaç gün sonra, artan. Gün bağlayıcıysa `daysLeft`; km bağlayıcıysa `kmLeft / kAssumedKmPerDay` (50 km/gün) ile güne çevrilir.
  - **Bilinmiyor**: şablon sırası (değişmedi).
- Gerekçe: Kullanıcı bu iki bölümde "sırada ne var" diye bakar; ölçüt takvimdeki yakınlıktır, döngünün ne kadarının geçtiği değil. Gecikmişte ise "en çok gecikmiş" doğru ölçüt ve spec bunu yazıyor.
- `kAssumedKmPerDay = 50` yalnız sıralamada kullanılır; hiçbir vade hesabına girmez (K-11: km yalnız kullanıcıdan). Gerçek ortalama bilinmediği için sabit; yanlış olsa bile yalnız iki km maddesinin görsel sırasını etkiler.
- Sonuç: `ItemStatus.proximityKey`, `item_grouping.compareByProximity`, `constants.kAssumedKmPerDay`.

## K-23 "Tarih/km düzelt" de kayıt satırı yazar
- Bağlam: 01-spec §3.4 düzeltmenin **log oluşturmadığını** söylüyor; §3.6 ise kayıt silmenin `last_done_*`'ı **yalnız kalan loglardan** yeniden hesapladığını. İkisi birlikte veri kaybediyor: kullanıcı trigerin son yapılışını elle girer, sonra aynı maddede bir kaydı siler, elle girdiği değer sessizce yok olur ve madde "Bilinmiyor"a döner (denetim md. 5).
- Karar: Düzeltme de bir `check_logs` satırı yazar, ama `kind = 'fix'` ile işaretlenir; Geçmiş ekranında "düzeltme" olarak görünür. "Yaptım" kayıtları `kind = 'done'`.
- Gerekçe: Silme mantığı hiç değişmeden her zaman doğru çalışır (tek doğruluk kaynağı loglar). Kullanıcı girdiği bilgiyi Geçmiş'te görür ve geri alabilir; bugün göremiyor. §3.4'ün "log satırı oluşturulmaz" cümlesinden bilinçli sapma.
- Sonuç: `check_logs.kind` sütunu eklendi ve `check_logs.km` **nullable** yapıldı (gün bazlı bir maddenin düzeltmesinde km yoktur; uydurmak yerine boş bırakılır). `schemaVersion` 1 → 2, `MigrationStrategy.onUpgrade` ile `TableMigration`.

## K-24 Sürüş kaydı notları sekiz değere çıktı, tanı satırı hepsini karşılıyor
- Bağlam: 02-mimari §3 `trips.note` için yedi değer sayıyor (`short_trip|no_overdue|once_per_day|snoozed|reconnect|fallback|ok`); motorun ürettiği `no_snapshot` listede yok (denetim md. 19). 01-spec §3.7 tanı satırı için üç örnek veriyor, ama motor yedi farklı `note` üretiyor ve 06 §3 adım 4 spec'te olmayan bir metin bekliyor: "Bugün zaten hatırlatıldı" (denetim md. 17).
- Karar:
  - `trips.note` sözlüğü **sekiz** değer: yedi belgeli değere `no_snapshot` (denetim md. 19) ve `no_permission` eklenir. `no_permission` yeni: bildirim izni yokken ya da kanal kapalıyken bildirim basılamadığını, dolayısıyla durumun yazılmadığını gösterir (denetim md. 4).
  - Tanı satırının son parçası `note`'a bakar; `note` yoksa `counted`/`notified` bayraklarına düşer. Metinler: `ok` → "bildirim gönderildi", `short_trip` → "sürüş sayılmadı", `once_per_day` → "bugün zaten hatırlatıldı", `no_overdue` → "gecikmiş yoktu", `snoozed` → "ertelenmişti", `reconnect` → "geri bağlandı, sürüş sürüyor", `no_snapshot` → "veri hazır değildi", `no_permission` → "bildirim izni yok".
- Gerekçe: §3.7'nin üç satırı örnek, tam liste değil; 06 §3 adım 4 zaten dördüncüsünü isteyerek bunu doğruluyor. Kullanıcı "neden bildirim gelmedi" sorusunun cevabını tek satırda görmeli, yoksa tanı satırının işi kalmaz.
- Sonuç: Kotlin `ReminderEngine.NOTE_*`, Dart `constants.kTripNote*`, `format_tr.lastTripReason`, `strings_tr.lastTrip*`.

## K-25 Bildirim basılmadan önce iptal edilir; kanal kapalıysa "basıldı" sayılmaz
- Bağlam: 01-spec §3.8 hem sabit id 1001 ("yenisi eskisini değiştirir") hem `setOnlyAlertOnce(true)` istiyor. İkisi birlikte, tepside duran eski bildirim varken yeni bildirimi **güncelleme** yapar: Android sesi, titreşimi ve heads-up'ı bastırır. Kullanıcı dünkü bildirimi silmediyse bugün arabadan indiğinde hatırlatma sessizce tepsiye düşer — ürünün tek vaadi olan "iniş anında heads-up" kaybolur (06 §3 adım 11). Ayrıca `notify` kanal kapalıyken sessizce düşüyor ve hata atmıyor; `showOverdue` yine `true` dönüyordu, motor da basılmamış bildirimi basılmış sayıp `once_per_day` ile o günü yakıyordu (denetim md. 4'ün ikinci yarısı, 07 §8).
- Karar: `showOverdue` (a) `areNotificationsEnabled` (uygulama + kanal) kontrolünden geçmeden basmaz ve `false` döner, (b) `notify`'dan hemen önce aynı id'yi `cancel` eder.
- Gerekçe: §3.8'in iki isteği de korunuyor (id sabit, güncelleme sessiz); yalnız gerçekten yeni bir hatırlatma olayında bildirim sıfırdan basıldığı için uyarı çalışıyor. Kanal kontrolü olmadan §7.1 adım 8'in "bildirimi bas" adımı yalan söylüyor.
- Sonuç: `Notifications.showOverdue`; not `no_permission` (K-24).

## K-26 Yedek bildirim `trips`'e yazılır ama sürüş sayılmaz
- Bağlam: `fallback` pending event'i (K-12) `connected_at`/`duration_min`/`counted` gibi NOT NULL sütunları dolduramıyor; 02-mimari §3 `trips.note` listesinde `fallback` var ama olayın hangi tabloya gideceği yazmıyor (denetim md. 18). Ayrıca yedek bildirim tanı satırına düşerse "Son kopma: …" diye bir kopma uydurmuş olur.
- Karar: Yedek bildirim `trips`'e yazılır: `connected_at = null`, `duration_min = 0`, `counted = false`, `notified = true`, `note = 'fallback'`. Ayarlar tanı satırını besleyen sorgu (`TripDao.lastTrip/watchLastTrip`) `fallback` satırlarını **eler**.
- Gerekçe: `note` listesinde `fallback` olması olayın bu tabloya ait olduğunu söylüyor; sürüş olmadığı için `counted=false`, bildirim basıldığı için `notified=true` tek tutarlı okuma. Tanı satırı "son kopma"yı anlatır, yedek bildirim kopma değildir.
- Sonuç: `TripRepo.applyPendingEvents`, `TripDao._lastTripQuery`, `Trip.isFallback`.

## K-27 Gecikmiş kalmayınca tepsideki bildirim iptal edilir
- Bağlam: Kullanıcı bildirimi görüp arabanın yanında maddeleri kaydediyor; bildirim tepside duruyor ve artık yalan söylüyor. 01-spec bunu tanımlamıyor, Dart'ın bildirimi iptal edecek kanal metodu da çağrılmıyordu (denetim md. 12).
- Karar: Snapshot her yazıldığında motorun "gecikmiş" saydığı madde sayısı hesaplanır (açık + gecikmiş + ertelenmemiş, 01-spec §7.1 adım 5). Sayı **>0'dan 0'a düştüğünde** `cancelNotification` çağrılır. Açılışta sayı zaten 0 ise hiçbir şey yapılmaz.
- Gerekçe: Yalnız geçişte iptal etmek, az önce basılmış bir bildirimi silme riskini ortadan kaldırıyor. Ölçüt ekranın Gecikmiş bölümü değil motorun listesi: ertelenmiş madde ekranda gecikmiş görünmeye devam eder (K-13) ama bildirime girmez, dolayısıyla erteleme de bildirimi anlamsız kılar.
- Sonuç: `SnapshotSync._cancelIfNothingOverdue`, `item_grouping.engineOverdue`.

## K-28 Doğrulanmamış şablon aralıkları madde detayında söylenir
- Bağlam: Şablonda 11 maddenin `verified` değeri `partial`/`false` ve her birinin ne doğrulanacağını anlatan bir `sourceNote`'u var. README kullanıcıya "◐ ve ❌ işaretli maddeleri kılavuzdan doğrula" diyor, ama uygulama hangisinin hangisi olduğunu göstermiyordu; iki alan da DB'de duruyor, hiçbir ekrana çıkmıyordu (denetim md. 14).
- Karar: Madde detayında, `verified != 'true'` ve `sourceNote` doluysa amber bir satır: `Kılavuzdan doğrula: <not>`. Uyarı (`warn`) satırının hemen altında; ölçüm bloğundan önce.
- Gerekçe: Not zaten yazılmış ve tam olarak kullanıcının ihtiyaç duyduğu şeyi söylüyor ("Yaygın öneri 30.000 km; kılavuzu doğrula"). Aralığı değiştirecek yer Ayarlar; kararı verecek bilgi ise maddeyi açtığı yerde olmalı.
- Sonuç: `CheckItem.needsVerification`, `item_detail_sheet._VerifyRow`, `strings_tr.detailVerifyPrefix`.

## K-29 Mevsimsel işi tarihinden birkaç gün önce yapmak vadeyi ilerletir
- Bağlam: 01-spec §2.1 mevsimsel vadeyi "son yapılıştan sonraki ilk tarih" diye tanımlıyor. Kışlık lastik 20 Eki'de takılırsa vade 1 Kas'ta kalıyor ve madde "12 gün kaldı" demeye devam ediyor; kullanıcı yaptığı işe tekrar çağrılıyor (denetim md. 13). Mevsimsel işler doğası gereği tarihinden önce yapılır — kimse ilk kar yağana kadar beklemez.
- Karar: Yapılan iş **en yakın** mevsimsel tarihe aittir. Sıradaki tarih hem `kSoonSeasonalDays` (14 gün) içindeyse **hem de geçmiş tarihten daha yakınsa**, o tarih yapılmış sayılır ve vade bir sonrakine geçer. Yalnız gerçek son yapılışta; kurulum günü yedeğinde uygulanmaz (25 Eki'de kurulan uygulama 1 Kas'ı atlamış saymamalı).
- "Daha yakın" karşılaştırması sonradan eklendi (bağımsız denetim bulgusu). İlk hâlde yalnız eşiğe bakılıyordu; tarihler birbirine yakınsa — kullanıcı Ayarlar'dan mevsimsel tarih ekleyebiliyor, ör. `[1 Kas, 10 Kas]` — 1 Kas'ta yapılan tek bir iş 10 Kas'ı da yutuyor ve o iş hiç gösterilmiyordu. `nextSeasonalDate` zaten üstünde bulunulan tarihi tükettiği için ikinci atlama fazlaydı.
- Gerekçe: Eşik zaten "yaklaşan" eşiği — madde 14 gün kala kullanıcıya gösterilmeye başlıyor. Gösterilmeye başladıktan sonra yapılan iş, gösterilen iştir. 14 günden önce yapılmışsa muhtemelen başka bir sebeple yapılmıştır ve bir sonraki mevsim değişimi hâlâ duruyordur.
- Sonuç: `StatusCalculator._seasonal`, `previousSeasonalDate`. **06 §1 satır 24 değişti**: son yapılış 2025-10-20 için vade artık 2025-11-01 (−306 gün) değil **2026-04-01** (−155 gün). Eski cevap kullanıcıya zaten yaptığı kasım değişimini gösteriyordu; yeni cevap gerçekten kaçırdığı nisan değişimini gösteriyor. Diğer mevsimsel satırlar (23, 25, 26, 27, 28) değişmedi. 06 §1'e 29–36 satırları, 01-spec §2.1'e sapma notu eklendi.

## K-31 Şablon maddesi de silinebilir; silinen anahtar kalıcı olarak hatırlanır
- Bağlam: K-07 şablon maddesini silmeyi yasaklıyor, yalnız kapatmaya (`enabled=false`) izin veriyordu; gerekçesi şablon yükseltmesinin silineni geri eklemesiydi. `TemplateMerge` "DB'de olmayan anahtar = yeni madde" diye çalışıyor, silinen anahtar da DB'de yok. 01-spec §3.7 aynı gerekçeyle şablon maddesinde ölçüm tipini de kilitliyordu. Kullanıcı isteği: "insanlar silebilir düzenleyebilir ekleyebilir olsun".
- Karar: Her madde silinebilir. Şablon maddesi silinince `templateKey` `settings.deleted_template_keys` içine (JSON dizi) yazılır; `upgradeTemplateIfNeeded` birleştirmeden önce bu anahtarları seed'den düşürür. Ölçüm tipi kilidi kalktı. Onay metni şablon maddesinde farklı: silmenin kalıcı olduğunu söylüyor.
- Gerekçe: Kapatmak yetmiyordu — kapalı madde Ayarlar listesinde durmaya devam ediyor. Silmeyi mümkün kılan tek şey "geri gelmesin" garantisiydi; onu tek bir ayar satırı veriyor. Ölçüm kilidi, madde tamamen silinip elle yeniden eklenebildiği için yalnız sürtünme ekliyordu. Anahtar listesi "verileri sıfırla"da DB ile birlikte gidiyor; sıfırlama zaten şablonu baştan kuruyor.
- Sonuç: `SettingKeys.deletedTemplateKeys`, `SettingsRepo.deletedTemplateKeys/markTemplateKeyDeleted`, `ItemListRepo.deleteItem`, `ItemRepo.upgradeTemplateIfNeeded`, `strings_tr.itemEditDeleteTemplateConfirm`. **K-07 gevşetildi**, 01-spec §3.7'deki ölçüm kilidi kalktı.

## K-30 Hareket doğrulaması (Activity Recognition), varsayılan kapalı
- Bağlam: "Arabada mıyım?" sorusunun tek cevabı, eşleşmiş cihazın ACL bağlan/kop olayı. Gerçek yanlış alarm: arabaya girip telefonu bağlayıp bir şey alıp inmek, ya da garajda kontak açmak. `minTripMinutes` bunu ancak süreyle eliyor; motor gerçekten çalıştı mı bilmiyoruz. Kullanıcı isteği: "activity recognition ekle".
- Karar: `Rules.requireMotion` eklendi. Açıkken, kopmada Activity Recognition'ın `IN_VEHICLE` geçişini sürüş penceresinde görmüş olması şart; görmemişse `note="no_motion"`, `counted=false`, bildirim yok. Pencere bağlantı anından **10 dk önce** başlar (`MOTION_LEAD_MINUTES`): arabaya binmek, geçişin algılanması ve Bluetooth eşleşmesi aynı anda olmuyor.
- **Yeni bağımlılık**: `com.google.android.gms:play-services-location`. AOSP'de karşılığı yok; activity transition API yalnız Play Hizmetleri'nde. Sürüm APK'sına maliyeti +265 KB (R8 kullanılmayanı atıyor). 07-android-notlar §1'in "başka bağımlılık yok" maddesi bununla değişti.
- **İki bağımsız emniyet kilidi**, çünkü yanlış kurulmuş bir kural uygulamanın asıl özelliğini sessizce öldürür: (1) Dart kuralı yalnız `setMotionUpdates` **true** dönerse açıyor — izin verilmediyse kural hiç yazılmıyor; (2) Kotlin `motionUpdatesActive` bayrağı false ise `evaluateDisconnect` kontrolü atlıyor. Yani izin sonradan geri alınırsa bildirimler durmaz, doğrulama devre dışı kalır.
- Abonelik yeniden başlatmada ve "force stop"ta düşebiliyor; her `resume`'da kural açıksa yeniden kuruluyor (`ensureMotion`).
- Gerekçe: Varsayılan kapalı, çünkü hareket algılanmayan gerçek bir sürüş = kaçırılmış bildirim, yanlış alarmdan pahalı. Açmak kullanıcının bilinçli tercihi; Ayarlar'daki yardım metni bedeli açıkça söylüyor.
- Sonuç: `MotionTracker`, `MotionReceiver`, `ReminderEngine.Motion`, `NOTE_NO_MOTION`, `EnginePrefs.lastInVehicleAt/motionUpdatesActive`, `Rules.requireMotion`, `PermissionsNotifier.enableMotion/disableMotion/ensureMotion`, `_MotionRow`. Tanı satırı sözlüğü K-24'te sekizden **dokuza** çıktı.

## K-32 GPS geofence ertelendi
- Bağlam: K-30 konuşulurken gündeme geldi ("belki gps geofence'de düşünebiliriz").
- Karar: Yapılmadı. `00-vizyon.md` konum/GPS'i kapsam dışı sayıyor; geofence sürekli konum izni ister, pil tüketir ve "ev/iş yakınında değilse sürüştür" gibi bir tahmin üretir. Activity Recognition aynı soruyu konum izni istemeden cevaplıyor.
- Yeniden açılma koşulu: K-30 gerçek arabada denendikten sonra hâlâ yanlış alarm kalıyorsa.

## K-33 Hareket doğrulaması izni karar anında sorulur
- Bağlam: K-30 iki emniyet kilidi tanımlamıştı, ama ikisi de "abonelik hiç kurulamadı" hâlini kapsıyordu. Cihaz testinde üçüncü bir yol çıktı: kullanıcı `ACTIVITY_RECOGNITION` iznini **sonradan** sistem ayarlarından geri alırsa Play Hizmetleri geçiş göndermeyi keser, `motion_updates_active` bayrağı ise `true` kalır. Bayrağı yalnız `MotionTracker.start/stop` değiştiriyor, ikisi de uygulamanın çalışmasını gerektiriyor; motor uygulama ölüyken çalıştığı için (K-03) bunu hiç öğrenemezdi. Sonuç: her sürüş `no_motion` sayılır, bildirim **sessizce ve süresiz** kesilirdi — K-30'un "asla olmamalı" dediği sınıf.
- Karar: Motor karar anında bayrağa değil `MotionTracker.isActive(ctx)`'e bakıyor: bayrak **ve** `checkSelfPermission`. İzin gitmişse bayrak orada düzeltiliyor (tek prefs yazımı, receiver için sorun değil). Ayrıca `resume`'da kural açık ama izin yoksa kural kapatılıyor: motor doğrulamayı atlıyorken açık kalan anahtar yalan söylerdi.
- Gerekçe: İzin kontrolü yerel ve ucuz; bayrağa güvenmenin bedeli uygulamanın asıl işini kaybetmek. `06 §3b` adım 16 tam bunu iddia ediyordu ve düzeltmeden önce **başarısız olurdu**.
- Sonuç: `MotionTracker.isActive`, `ReminderEngine.onDisconnected`, `MainActivity.isMotionActive`, `PermissionsNotifier.ensureMotion` (artık `bool` dönüyor), `AppLifecycle._syncMotionRule`.

## K-34 Yeniden başlatma aboneliği düşürür; motor bunu bilir
- Bağlam: K-33 düzeltildikten sonra aynı sınıftan ikinci bir kapı kaldı. Play Hizmetleri geçiş aboneliklerini **cihaz yeniden başlayınca** düşürüyor, ama `motion_updates_active` prefs'te `true` kalıyor ve izin de duruyor — yani K-33'ün izin kontrolü bunu yakalayamıyor. `06 §3` adım 8 tam bu durumu tarif ediyor: "telefonu yeniden başlat, uygulamayı **açma**, sür, kop". Kural açıkken bildirim sessizce kesilirdi.
- Ayrıca `AppLifecycleListener(onResume:)` **soğuk açılışta tetiklenmiyor**; abonelik yalnız `resume`'da kuruluyordu. Yeniden başlatmadan sonra uygulamayı açıp arka plana atmayan kullanıcıda abonelik hiç kurulmuyordu.
- Karar: (1) Kayıt başarılı olunca açılış damgası (`currentTimeMillis - elapsedRealtime`) yazılıyor; `MotionTracker.isActive` damga tutmuyorsa bayrağı düşürüyor, motor da doğrulamayı atlayıp **bildiriyor**. Tolerans 60 sn (NTP oynaması); yeniden başlatma damgayi en az dakikalarca ileri atar. (2) `syncMotionRule` artık `main.dart` açılışında da çağrılıyor.
- Gerekçe: Her belirsizlikte "doğrulamayı atla, bildir" tarafına düşülüyor. Bedeli: yeniden başlatmadan sonra uygulama bir kez açılana kadar hareket doğrulaması çalışmaz (yanlış alarm eler değil), ama bildirim asla kaybolmaz. Tersi kabul edilemez.
- Reddedilen seçenek: `RECEIVE_BOOT_COMPLETED` + boot receiver ile yeniden kaydolmak. Doğru çözüm bu ama yeni izin ve yeni bileşen demek; ilk açılışta kendini onaran hâl aynı sonucu veriyor ve yüzeyi büyütmüyor. Hareket doğrulaması uygulamanın çekirdeği değil, yanlış alarm filtresi.
- `syncMotionRule` kuralı `rulesProvider.valueOrNull` ile okuyordu; soğuk açılışta Drift akışı henüz yayın yapmadığı için `null` görüyor ve **hiç abonelik kurmuyordu**. Cihaz kaydı bunu kanıtladı (açılışta `motion updates registered` yok, arka plan→ön plan çevriminde var); bağımsız inceleme aynı satırı ayrıca işaretledi. Artık `rulesProvider.future` bekleniyor.
- Sonuç: `ReminderEngine.sameBoot` + `BOOT_TOLERANCE_MS` (saf, JVM testli), `EnginePrefs.motionRegisteredBootAt`, `MotionTracker.isActive/bootAt`, `AppLifecycle.syncMotionRule`, `main.dart`.

## K-35 Hareket doğrulamasının çalışıp çalışmadığı Ayarlar'da görünür
- Bağlam: İlk gerçek araba sürüşünden sonra "çalıştığını nasıl anlarım?" sorusu cevapsız kaldı. Tanı satırı `gecikmiş yoktu` diyordu; bağımsız inceleme bunun hareket doğrulamasının **geçtiğini kanıtlamadığını** gösterdi. Kapı `requireMotion && active && !seenInTrip()` üçlü bir VE; `no_overdue`'ya varmak bu birleşimin yanlış olduğunu söyler, hangi teriminden yanlış olduğunu değil. Dört ayrı durum aynı notu üretiyor: doğrulama geçti / abonelik bayrağı false / boot damgası tutmadı / snapshot'ta kural henüz false. K-30'un "her belirsizlikte bildir" tasarımı gereği hepsi güvenli tarafta, ama **hiçbiri dışarıdan ayırt edilemiyordu**.
- Karar: Kural açıkken anahtarın altında durum satırı: aboneliğin gerçekten kurulu olup olmadığı ve motorun gördüğü **son araç hareketinin zamanı**. Yeni kanal metodu `getMotionState` → `{active, lastInVehicleAt}`; `active`, karar anındaki gerçek durum (`MotionTracker.isActive`, yani bayrak + izin + boot damgası).
- Gerekçe: Sessizce doğrulamayı atlayan bir filtre, çalıştığını sanan bir kullanıcıdan daha kötüsü yok. "Abonelik düşmüş; doğrulama şu an atlanıyor, bildirimler yine geliyor" satırı hem durumu hem sonucunu söylüyor. Son hareket zamanı da "bu telefonda Activity Recognition gerçekten üretiyor mu" sorusunu kalıcı olarak cevaplıyor — kod okuyarak değil, bakarak.
- Yan düzeltme: "Sadece gecikmiş varsa" yardım metni "Kapatırsan yaklaşanlar da bildirilir" diyordu; motor yaklaşanları **hiç listelemiyor** (01-spec §7.1: liste boşsa "Kontroller zamanında"). Metin davranışa uyduruldu.
- Sonuç: `MainActivity.getMotionState`, `PlatformBridge.getMotionState`, `PermissionState.motionLastAt`, `_motionStatus`, `strings_tr.motionStatus*`.
