# CarKeep — Claude Code proje anayasası

Bu dosya her oturumda okunur. Kısa tutulmuştur; ayrıntı `docs/` altındadır. Çelişki olursa öncelik sırası: `docs/04-kararlar.md` > `docs/01-spec.md` > `docs/02-mimari.md` > bu dosya > kendi varsayımın. Varsayım yapmak yerine sor.

## Proje nedir
Tek araç için rutin bakım kontrol hatırlatıcısı. Android, Flutter. Sunucu yok. Asıl özellik: telefon arabanın Bluetooth'undan koptuğu anda ("arabadan indin") gecikmiş kontrolleri bildirmesi. Ürün tanımı: `docs/00-vizyon.md`.

## Dil kuralları
- Kod, dosya adları, tanımlayıcılar, commit mesajları: İngilizce.
- Kullanıcıya görünen her metin: Türkçe, tek dosyada (`lib/core/strings_tr.dart`). Widget içine string gömme.
- Dokümanlar ve `docs/ILERLEME.md`: Türkçe.
- Bana yazarken: Türkçe, kısa, dolgu yok. Hata yaptıysan "yaptım, düzeltiyorum" de, gerekçe üretme.

## Yığın (değiştirme, gerekçeler 04-kararlar.md'de)
- Flutter stable + Dart 3, yalnız Android (`--platforms android`), `minSdk 26`, `compileSdk/targetSdk` = kurulu en yüksek stable.
- Durum: `flutter_riverpod` (Notifier/AsyncNotifier). Riverpod için codegen yok.
- Veri: `drift` + `drift_flutter` (SQLite). Codegen yalnız Drift için (`build_runner`).
- Bildirim, Bluetooth dinleme, WorkManager: **native Kotlin**, plugin yok. Dart ile tek `MethodChannel`: `com.beratarpa.carkeep/platform`.
- Bağımlılık eklemek istersen önce `docs/04-kararlar.md`'ye bir madde yaz ve bana sor.
- Uygulama adı "CarKeep", paket `com.beratarpa.carkeep`, Flutter proje adı `carkeep`.

## Tek doğruluk kaynağı
- Aralık/durum hesabı **yalnız** `lib/domain/status_calculator.dart` içinde. Kotlin tarafı hesap yapmaz, Dart'ın yazdığı snapshot'taki `dueDay`/`dueKm` değerlerini bugünle/km ile karşılaştırır.
- Kontrol şablonu **yalnız** `assets/seed/checklist_seed.json` (kaynağı `seed/checklist_seed.json`). Aralık uydurma, madde ekleme/çıkarma yapma; eksik görürsen sor.
- Bildirim kuralları (`sadece gecikmiş`, `günde bir`, `min sürüş`, `geri bağlanma toleransı`, `sürüşsüz gün fallback`) `docs/01-spec.md` §7'de tanımlı; Kotlin `ReminderEngine` bunu birebir uygular.

## Komutlar
```
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run            # fiziksel cihaz; emülatörde Bluetooth yok
flutter build apk --release
```

## Çalışma düzeni
1. `docs/05-is-listesi.md` sırasıyla, ticket ticket. Ticket'ı bölme, birleştirme.
2. Her ticket: kabul kriterlerini tek tek doğrula → `flutter analyze` temiz → `flutter test` yeşil → tek commit (`feat(T07): ...`) → `docs/ILERLEME.md` satırını güncelle.
3. `T05` ve `T12` sonunda dur; fiziksel cihaz testi için bana ne yapmam gerektiğini adım adım yaz (bkz. `docs/06-test-plani.md`). Onayım gelmeden sonraki ticket'a geçme.
4. Kararlardan sapmak gerekirse önce sor; sapma onaylanırsa `04-kararlar.md`'ye ekle.
5. `preview/carkeep-onizleme.html` referans arayüzdür: ekran düzeni, metinler, renkler, davranış oradan. Dosyayı değiştirme. Mockup ile spec çelişirse spec kazanır (bilinen tek fark: "2 dk bekleme" yerine "hızlı geri bağlanmada bildirimi iptal", bkz. 04-kararlar.md K-06).

## Kod kuralları
- Widget'larda iş mantığı yok; hesap `domain/`, veri `data/`, ekranlar `features/<ekran>/`.
- Model sınıfları immutable (`final` alanlar, `copyWith`). Enum'lar için `switch` exhaustive.
- Tarih: yalnız yerel takvim günü hesabı (`DateTime` → `DateUtils.dateOnly`). UTC'ye çevirme. Gün anahtarı formatı `yyyy-MM-dd`.
- Km: `int`. Basınç: `double`, virgülle gösterilir ("2,3 bar"), noktayla parse edilir.
- Türkçe biçimlendirme `lib/core/format_tr.dart` (ay kısaltmaları, binlik ayırıcı nokta). `intl` kullanma.
- Kotlin: coroutine yok, RxJava yok. `BroadcastReceiver` içinde 5 sn'yi geçen iş yok. Loglar `Log.d("CarKeep", ...)`.
- Her domain fonksiyonu için test. `status_calculator` için `docs/06-test-plani.md` §1 tablosundaki her satır bir test.
- Lint: `flutter_lints` varsayılanı + `analysis_options.yaml`'da `prefer_single_quotes`, `always_declare_return_types`.

## Yapma
- Android Auto, OBD, konum/GPS, bulut, hesap, iOS, çoklu araç, harcama takibi (hepsi kapsam dışı, 00-vizyon.md).
- Bluetooth için plugin (`flutter_blue_plus`, `flutter_bluetooth_serial` vb.).
- `flutter_local_notifications`: v1'de Dart bildirim basmaz, gerek yok.
- `intl`, `get_it`, `bloc`, `hive`, `shared_preferences` (prefs Kotlin tarafında, kendi dosyamız).
- Ticket dışında "iyileştirme". Fark ettiğin şeyi `docs/ILERLEME.md` "Notlar" bölümüne yaz, geç.
