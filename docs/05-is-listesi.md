# 05 — İş listesi (ticket'lar)

Sıra bağlayıcıdır; her ticket bir öncekinin çıktısına dayanır. Her ticket için: kapsam, dosyalar, kabul kriterleri (hepsi ✓ olmadan bitmiş sayılmaz), test. Bitince `docs/ILERLEME.md` güncellenir, tek commit atılır: `feat(T03): seed loader and template merge`.

Kontrol noktaları (dur, bana yaz): **T05 sonu** (kanal + izinler fiziksel cihazda), **T12 sonu** (gerçek kopma testi), **T18 sonu** (APK).

---

## T01 — Proje iskeleti
Kapsam: `flutter create carkeep --org com.beratarpa --platforms android` (mevcut klasörde, kit dosyaları korunur); `pubspec.yaml` bağımlılıkları (`flutter_riverpod`, `drift`, `drift_flutter`, `path_provider`, `path`; dev: `drift_dev`, `build_runner`, `flutter_lints`); `analysis_options.yaml`; klasör iskeleti (02-mimari §2); `lib/core/theme.dart` (01-spec §10 token'ları, Manrope fontları `assets/fonts`), `strings_tr.dart` (ilk metinler), `format_tr.dart`, `date_utils.dart`, `constants.dart` (eşikler: `soonDays=3`, `soonKm=1000`, `soonSeasonalDays=14`, preset listeleri); `android/app/build.gradle(.kts)` `minSdk 26`, Kotlin, `work-runtime-ktx`; `.gitignore`; `git init` + ilk commit.
Kabul:
- [ ] `flutter analyze` sıfır uyarı; `flutter run` fiziksel cihazda boş "CarKeep" ekranını açıyor.
- [ ] `format_tr` testleri: `118420 → "118.420"`, `2.3 → "2,3"`, `DateTime(2026,9,16) → "16 Eyl"`, farklı yıl → `"16 Eyl 2027"`.
- [ ] `date_utils`: `dayKey(DateTime(2026,9,3,23,59)) == "2026-09-03"`, `daysBetween` takvim günü sayıyor (saat farkı etkilemiyor).
- [ ] `docs/ILERLEME.md`'ye Flutter/Dart/AGP/Kotlin sürümleri yazıldı.

## T02 — Drift şeması ve DAO'lar
Kapsam: 02-mimari §3 tabloları; `AppDatabase` (`schemaVersion 1`, `PRAGMA foreign_keys`); DAO'lar: `VehicleDao` (get/insert/update), `ItemDao` (watchAll(vehicleId), insertAll, update, delete, setEnabled, setSchedule, setLastDone, setSnooze), `LogDao` (add — transaction içinde item.last_* günceller; delete — item.last_* bir önceki loga göre yeniden hesaplar; watchAll; lastN(itemId)), `TripDao` (insert, last), `SettingsDao` (get/set/watch; tipli yardımcılar `getRules()/setRules()`).
Kabul:
- [ ] `build_runner` temiz üretiyor.
- [ ] In-memory DB testleri: log ekle → item `last_done_day/km/value` güncellendi; son logu sil → bir önceki loga döndü; tek logu sil → null; `snooze_until_day` log eklemede temizleniyor.
- [ ] `ItemDao.watchAll` `sort_order` sırasında yayınlıyor.

## T03 — Seed yükleyici ve şablon birleştirme
Kapsam: `seed/checklist_seed.json` → `assets/seed/` (pubspec asset); `SeedLoader.load()` → `List<SeedItem>` (doğrulama: benzersiz id, geçerli schedule/measure, verified≠true ise sourceNote var); `TemplateMerge.plan(seedItems, dbItems) → {toInsert, unchangedCount}` (K-07); kurulumda `insertAll` (sort_order = seed sırası, `enabled = enabledByDefault`); açılışta sürüm karşılaştırma ve ekleme (yeni maddeler kapalı, toast metni).
Kabul:
- [ ] Seed 34 madde yükleniyor; bozuk JSON testi anlamlı hata fırlatıyor.
- [ ] `TemplateMerge` testleri: boş DB → 34 insert; aynı sürüm → 0; DB'de kullanıcı aralığı değişmiş madde → dokunulmuyor; seed'de olmayan DB maddesi → kalıyor; yeni seed maddesi → `enabled=false` ile ekleniyor.

## T04 — StatusCalculator ve SnapshotBuilder
Kapsam: 01-spec §2 birebir; `ItemStatus` metinleri `format_tr` ile; sıralama anahtarı; `SnapshotBuilder` (02-mimari §5; `unknown` ve `enabled=false` hariç; `generatedAt` ISO 8601 yerel offset ile).
Kabul:
- [ ] `docs/06-test-plani.md` §1 tablosundaki **her satır** ayrı test, hepsi yeşil.
- [ ] `both` bağlayıcı boyut testi: km oranı küçükken km metni, gün oranı küçükken gün metni; eşitlikte km.
- [ ] Seasonal: 3 Eyl'de son yapılış 5 Nis → vade 1 Kas, `daysLeft 59`, `ok`; 20 Eki → `soon`; 2 Kas ve yapılmamış → `overdue 1 gün`.
- [ ] Snapshot JSON şemaya uygun (test `jsonDecode` ile alanları doğrular), `unknown` madde yok, kapalı madde yok.

## T05 — Platform köprüsü (Kotlin + Dart)
Kapsam: `MainActivity.kt` MethodChannel; 02-mimari §6 metotları (`debug*` hariç); `EnginePrefs.kt`; `DayKey.kt`; izin isteği akışı (`ActivityCompat.requestPermissions`, `onRequestPermissionsResult` → pending `Result`); `onNewIntent` → `onLaunchAction`; Dart `PlatformBridge` sınıfı (tipli sarmalayıcı, `PlatformException` → Dart hataları); manifest izinleri (07 §2, receiver hariç).
Kabul:
- [ ] Fiziksel cihazda `getBondedDevices` Uconnect'i listeliyor (izin sonrası); izin yokken `NO_PERMISSION`.
- [ ] `writeSnapshot` → `readSnapshot` aynı string; uygulama kapatılıp açılınca kalıcı.
- [ ] `hasNotificationPermission` API 33+ gerçek durumu, altında `true`.
- [ ] `isIgnoringBatteryOptimizations` doğru; `openBatteryOptimizationSettings` sistem ekranını açıyor.
- [ ] `drainPendingEvents` boşken `"[]"`.
- [ ] **Kontrol noktası**: bana adım adım cihaz testi yazıldı, onay bekleniyor.

## T06 — Kurulum sihirbazı
Kapsam: 01-spec §3.1 altı adım; `SetupController` (Notifier, adım durumu, doğrulama); izin adımı `PlatformBridge`; cihaz listesi; son servis adımı (tarih seçici + km); kontrol listesi adımı; "Başla" → transaction: vehicle insert, items insert (seed), `appliesLastService` maddelerin `last_done*`, `settings.install_day/template_version`, rules varsayılanları; `scheduleDailyWorker`; ana ekrana geçiş; toast.
Kabul:
- [ ] Zorunlu alanlar boşken "İleri" uyarı veriyor, ilerlemiyor.
- [ ] İzin reddedilse de kurulum tamamlanıyor; ana ekranda ilgili uyarı şeridi çıkıyor.
- [ ] Son servis girildiğinde `oil_change` ve `pollen_filter` `ok/soon` hesaplanıyor; girilmediğinde `unknown`.
- [ ] Kurulum sonrası uygulama kapatılıp açılınca doğrudan ana ekran.
- [ ] Widget testi: 6 adım akışı, "Başla" sonrası DB'de 1 araç + 34 madde.

## T07 — Kontroller ekranı
Kapsam: 01-spec §3.2; `HomeController`; bölümler, sıralama, satır widget'ı, km başlığı, Bluetooth chip'i (`bluetoothStateProvider`), uyarı şeritleri (`permissionsProvider`, araç seçilmemiş, pil), boş durum, vurgu animasyonu (`launchActionProvider`), alt gezinme (3 sekme, `IndexedStack`).
Kabul:
- [ ] Widget testi: verilen madde listesinde bölüm sayıları ve sıralama doğru; boş bölüm gizli; hepsi zamanında → boş durum metni.
- [ ] Kapalı madde görünmüyor.
- [ ] Uyarı şeridi dokununca ilgili aksiyon (izin iste / cihaz seç / pil ayarı).
- [ ] Gecikmiş satırda sol kırmızı çizgi; sağ metin renkleri durumla eşleşiyor.

## T08 — Madde detayı, Yaptım, ölçüm, erteleme, tarih/km düzelt
Kapsam: 01-spec §3.3–3.4; `ItemDetailSheet` (DraggableScrollableSheet veya `showModalBottomSheet` + scroll), ölçüm blokları (level/tires/number/none), hedef basınç sapma vurgusu, not, önceki 3 kayıt, "Yaptım olarak kaydet", "Yarın hatırlat", "Tarih/km düzelt" diyaloğu; `unknown` maddede düzeltme öne çıkarılmış.
Kabul:
- [ ] Zorunlu ölçüm eksikken kaydetmiyor, doğru toast.
- [ ] Kayıt sonrası: log satırı, `last_*`, toast `Kaydedildi. Sonraki: …`, sheet kapanıyor, ana ekran güncel.
- [ ] `tires` değeri `"2,3 / 2,3 / 2,3 / 2,2 bar"` biçiminde saklanıyor; `2.3` girişi kabul, `2,3` girişi de kabul.
- [ ] Erteleme: durum "Yarın", ertesi gün tekrar `overdue`.
- [ ] Düzeltme: log oluşturmuyor, `last_*` değişiyor, `unknown` → hesaplanıyor.
- [ ] Widget testleri: level zorunlu, tires dört alan, düzeltme diyaloğu ileri tarih seçtirmiyor.

## T09 — Km giriş
Kapsam: 01-spec §3.5; `KmEntrySheet`; doğrulama; `vehicles.current_km`; toast.
Kabul:
- [ ] Küçük değer reddediliyor (metin doğru), eşit değer kabul, büyük değer kaydediliyor.
- [ ] Km değişince km bazlı maddelerin durumu anında güncelleniyor (Riverpod akışı).

## T10 — Geçmiş
Kapsam: 01-spec §3.6; gün gruplu liste; detay + Sil (onay); silme sonrası `last_*` yeniden hesap (T02 DAO).
Kabul:
- [ ] Gruplama ve sıralama doğru; boş durum metni.
- [ ] Silme sonrası ilgili madde durumu değişiyor; onay iptalinde hiçbir şey olmuyor.

## T11 — Ayarlar
Kapsam: 01-spec §3.7 tüm bölümler; araç düzenleme (km geri alma onayı, hedef basınçlar); cihaz seçici alt sayfası (Bluetooth izni yoksa izin akışı; tanı satırı `last_trip`); kurallar (switch'ler, adımlayıcılar, fallback seçici); kontrol listesi (aralık adımlayıcı presetler, aç/kapat, madde düzenleme sayfası, madde ekle, kullanıcı maddesi sil); uygulama bölümü (izin durumları + düzelt, şablon sürümü, verileri sıfırla, debug bölümü — T12'de bağlanır).
Kabul:
- [ ] Her kural değişikliği `settings`'e yazılıyor ve snapshot'a yansıyor (T12 öncesi `readSnapshot` ile doğrulanır).
- [ ] Aralık adımlayıcı presetlerde geziyor, uçlarda duruyor; `both` maddede +/− yalnız km.
- [ ] Şablon maddesi silinemiyor, ölçüm tipi değiştirilemiyor; kullanıcı maddesi tam düzenlenebilir ve silinebilir (kayıtları da siliniyor, onaylı).
- [ ] "Verileri sıfırla" DB'yi boşaltıp kuruluma dönüyor, prefs snapshot'ı siliniyor.

## T12 — BtReceiver, ReminderEngine, Notifications, NotifActionReceiver
Kapsam: 07-android-notlar §3–5 iskeletleri; manifest receiver kayıtları; `ReminderEngine.evaluate/apply` (01-spec §7.1 birebir, hızlı geri bağlanma iptali K-06); `Notifications` (kanal, içerik, eylemler, PendingIntent'ler `FLAG_IMMUTABLE`); `NotifActionReceiver` "Yarın"; pending events yazımı; `debugSimulate` (yalnız debug); Ayarlar → Geliştirici bölümü bağlanır.
Kabul:
- [ ] Kotlin birim testi (`test/` JVM, Robolectric'siz): `evaluate` için 01-spec §7.1 adımlarının her biri (kısa sürüş, araç eşleşmiyor, snooze, gecikmiş yok, günde bir, normal) ve K-06 geri bağlanma senaryosu.
- [ ] Debug menüden "Kopmayı simüle et (25 dk)" → gecikmiş varsa heads-up bildirim ≤ 1 sn; "2 dk" → bildirim yok, tanı satırı "sürüş sayılmadı".
- [ ] Aynı gün ikinci simülasyon → bildirim yok, `once_per_day`.
- [ ] Bildirime dokunma: uygulama kapalıyken açılıp Kontroller'de vurgu; açıkken sekme değişip vurgu.
- [ ] "Yarın": bildirim kapanıyor, o gün simülasyon bildirim üretmiyor, ertesi gün üretiyor.
- [ ] **Kontrol noktası**: gerçek araba testi protokolü (06 §3) bana yazıldı; sonuçları gelmeden T13'e geçilmiyor.

## T13 — Pending events akışı ve Bluetooth durumu
Kapsam: `drainPendingEvents` → `trips` insert / `settings.global_snooze_until_day`; açılış ve `resume`'da; `bluetoothStateProvider`; Ayarlar tanı satırı DB'den; ana ekran chip'i.
Kabul:
- [ ] Simüle edilen sürüşler `trips` tablosunda; drain sonrası prefs dizisi boş; ikinci drain tekrar eklemiyor.
- [ ] Chip bağlıyken "bağlı, sürüşte" (simüle bağlan → resume).

## T14 — DailyCheckWorker (sürüşsüz yedek)
Kapsam: 07 §5; kendini yeniden planlama; 01-spec §7.2 koşulları; `scheduleDailyWorker` açılışta REPLACE; `debugRunDailyWorker`.
Kabul:
- [ ] Debug çalıştırma: 7+ gün gecikmiş madde ve 3 gün bildirim yok → yedek bildirim; koşul sağlanmıyorsa sessiz; pending `fallback` kaydı.
- [ ] `adb shell dumpsys jobscheduler` çıktısında iş planlı; `adb shell cmd jobscheduler run` ile tetiklenebiliyor (06 §4 komutu).

## T15 — Snapshot senkronu ve yaşam döngüsü
Kapsam: `snapshotSyncProvider` (debounce 300 ms, tüm tetikleyiciler 01-spec §6); `AppLifecycleListener` (resume: drain, launch action, izinler, Bluetooth durumu, snapshot); `main.dart` açılış sırası 02-mimari §10 tamamlanır.
Kabul:
- [ ] Her tetikleyici sonrası `readSnapshot` beklenen içeriği veriyor (widget/integration testi: kayıt → snapshot'ta `dueDay` ilerledi).
- [ ] Gece yarısı geçişi: `todayProvider` resume'da yenileniyor (test: override ile).

## T16 — Hata ve boş durumlar, metin turu
Kapsam: 01-spec §9; tüm metinlerin `strings_tr.dart`'ta olduğu doğrulaması (grep ile widget'larda Türkçe literal yok); erişilebilirlik: `Semantics` etiketleri, minimum 48 dp dokunma alanı; büyük yazı tipi ölçeği 1.3'te taşma yok.
Kabul:
- [ ] `grep -rn "[çğışöüÇĞİŞÖÜ]" lib/features lib/app.dart` yalnız yorumlarda çıkıyor.
- [ ] Seed bozuk / DB açılamıyor senaryoları tam ekran hata gösteriyor (test: sahte loader).
- [ ] `flutter test` ve `flutter analyze` temiz.

## T17 — Cihaz testi düzeltmeleri
Kapsam: 06 §3 protokolünün sonuçlarına göre düzeltmeler; OEM pil ayarı metinleri (`Build.MANUFACTURER`'a göre 07 §7); Doze testi (`adb shell dumpsys deviceidle force-idle`) sonrası receiver'ın çalıştığının doğrulanması.
Kabul:
- [ ] Gerçek arabada 3 ardışık günde: kopmadan sonra ≤ 30 sn bildirim (gecikmiş varken), günde bir, kısa bağlantıda yok.
- [ ] Yeniden başlatma sonrası (uygulama açılmadan) receiver çalışıyor.
- [ ] Bulunan her hata için test eklendi.

## T18 — Release
Kapsam: uygulama ikonu (mipmap PNG'leri, basit anahtar/onay işareti), `versionCode/versionName`, imzalama (`key.properties`, `upload-keystore.jks` repo dışı, `.gitignore`), R8 keep kuralları, `flutter build apk --release`, APK boyutu ve başlangıç süresi notu, `README.md` "Kurulum" bölümü (APK yükleme, izinler, pil ayarı).
Kabul:
- [ ] Release APK fiziksel cihazda kurulup çalışıyor; receiver release'te de çalışıyor (R8 sınıf adlarını korumuş).
- [ ] `docs/ILERLEME.md` tamamlandı işaretli, bilinen sorunlar listesi var.
- [ ] **Kontrol noktası**: APK yolu ve kurulum adımları bana yazıldı.

---

## Sonraki sürüm adayları (ticket değil, kayıt)
GPS ile km tahmini (K-11), OBD akü voltajı/arıza kodu, yedekleme (JSON dışa/içe aktarma), çoklu araç, karanlık tema, ev ekranı widget'ı, Wear OS bildirimi.
