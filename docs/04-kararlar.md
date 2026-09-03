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
