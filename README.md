# CarKeep

Tek araç için rutin bakım kontrol hatırlatıcısı. Android, Flutter + native Kotlin, sunucu yok.

Asıl özellik şu: **telefon arabanın Bluetooth'undan koptuğu anda** — yani sen arabadan indiğinde
— gecikmiş kontroller varsa bildirim gelir. Hatırlatma, işi yapabileceğin tek yerde, arabanın
yanındayken önüne çıkar. Uygulamayı açmanı beklemez; hatta uygulama kapalıyken de çalışır.

<p align="center">
  <em>Fiat Egea 1.6 MultiJet (2019) için hazırlanmış 34 maddelik şablonla gelir,<br>
  ama motor araçtan bağımsızdır: maddeler eklenebilir, silinebilir, aralıkları değiştirilebilir.</em>
</p>

## Nasıl çalışır

```
araba Bluetooth'u koptu
        │
        ▼
BtReceiver (manifest receiver, Flutter motoru uyandırılmaz)
        │
        ▼
ReminderEngine ── snapshot'taki dueDay/dueKm'yi bugünle ve km ile karşılaştırır
        │          (hesap yapmaz; aralık matematiği yalnız Dart'ta)
        ├── sürüş 5 dk'dan kısa mı?            → sus
        ├── araç hareketi görüldü mü? (K-30)   → görülmediyse sus
        ├── gecikmiş var mı, bugün bildirdim mi?
        ▼
bildirim: "3 kontrol gecikti"
```

İki tek yönlü kanal var, başka paylaşım yok:

| | Yön | İçerik |
|---|---|---|
| **snapshot** | Dart → Kotlin | araç, km, kurallar ve her maddenin `dueDay`/`dueKm`'si |
| **pending events** | Kotlin → Dart | olan biten sürüşler, ertelemeler, yedek bildirimler |

Kotlin tarafı asla aralık hesabı yapmaz (K-04). Bütün durum hesabı
[`lib/domain/status_calculator.dart`](lib/domain/status_calculator.dart) içinde, tek yerde.

Sürüş olmayan dönemler için yedek yol da var: günde bir çalışan `DailyCheckWorker`, bir madde
7 günden fazla gecikmişse arabaya hiç binmesen de hatırlatır (K-12).

## Yığın

- Flutter stable (3.47) + Dart 3, yalnız Android, `minSdk 26`, `targetSdk 36`
- Durum: `flutter_riverpod` (Notifier/AsyncNotifier), Riverpod için codegen yok (K-08)
- Veri: `drift` + `drift_flutter` (SQLite), codegen yalnız Drift için
- Bildirim, Bluetooth dinleme, WorkManager: **native Kotlin**, plugin yok. Dart ile tek
  `MethodChannel`: `com.beratarpa.carkeep/platform` (K-05)
- Hareket doğrulaması için `play-services-location` (K-30) — tek AOSP dışı bağımlılık, varsayılan kapalı
- Türkçe metinler tek dosyada (`lib/core/strings_tr.dart`), `intl` yok (K-09)

## Kurulum (APK)

Play Store gerekmez.

1. **APK'yı telefona kopyala.** Bugünkü telefonların hemen hepsi arm64:
   `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (~20 MB).
   Emin değilsen `app-release.apk` her cihazda çalışır.
2. **Yükle.** Dosya yöneticisinden APK'ya dokun ve "bu kaynaktan yüklemeye izin ver" de.
   USB ile: `adb install app-arm64-v8a-release.apk`.
3. **Kurulum sihirbazını bitir** (6 adım): marka/model, güncel km, izinler, arabanın Bluetooth
   cihazı, son servis (isteğe bağlı), kontrol listesi.
4. **İzinler** — sihirbazın 3. adımında sorulur, sonradan Ayarlar → Uygulama'dan da verilebilir:
   - **Bluetooth** (zorunlu): kopmayı duymak için. Bu izin yoksa motor hiç çalışmaz.
   - **Bildirim** (zorunlu): hatırlatmayı göstermek için.
   - **Pil optimizasyonu** (önerilir): "Kısıtlanmamış" olmalı, yoksa telefon uygulamayı uyutup
     kopmayı kaçırabilir. Samsung'da ayrıca "Kullanılmayan uygulamaları uyku moduna al" kapalı olmalı.
     Diğer markalar: [`docs/07-android-notlar.md`](docs/07-android-notlar.md) §7.
5. **Doğrula.** Arabaya bin, en az 6 dk sür, kontağı kapat. Gecikmiş bir madde varsa 30 saniye
   içinde bildirim gelmeli.

Uygulamayı **"Durmaya zorla"** yaparsan Android receiver'ı kapatır; bir kez açman yeter.

## Geliştirme

```bash
flutter pub get                                             # android/local.properties'i de üretir
dart run build_runner build --delete-conflicting-outputs    # yalnız Drift
flutter analyze
flutter test                                                # 516 test
cd android && ./gradlew :app:testDebugUnitTest              # 88 JVM testi
flutter run                                                 # fiziksel cihaz; emülatörde Bluetooth yok
flutter build apk --release --split-per-abi
```

Üretilen Drift dosyaları (`*.g.dart`) depoda: temiz bir klonda `build_runner` çalıştırmadan
`flutter test` yeşil geçer. Şemayı değiştirirsen tekrar üretmen gerekir.

İmzalama anahtarı repo dışında: `android/key.properties` yolunu gösterir ve `.gitignore`'dadır.
Anahtar yoksa release derlemesi debug imzasıyla çıkar, yine çalışır.

## Kod düzeni

```
lib/
  core/          sabitler, Türkçe metinler, Türkçe biçimlendirme, tema
  domain/        durum hesabı, snapshot üretimi, modeller — saf Dart, hepsi testli
  data/          drift şeması ve DAO'lar, repository'ler, platform köprüsü, seed
  features/      ekranlar (kurulum, kontroller, madde detayı, geçmiş, ayarlar)
  providers.dart  Riverpod sağlayıcıları; lifecycle.dart  açılış/resume sırası
android/app/src/main/kotlin/com/beratarpa/carkeep/
  BtReceiver      ACL bağlan/kop; 5 sn'yi geçmez, Flutter motorunu uyandırmaz
  ReminderEngine  bildirim kararı — saf fonksiyonlar, JVM'den doğrudan test edilir
  MotionTracker   Activity Recognition aboneliği (K-30/K-33/K-34)
  DailyCheckWorker sürüşsüz dönem yedeği
  Snapshot        Dart'ın yazdığı JSON'un okunması
```

## Dokümanlar

Karar geçmişi ve şartname `docs/` altında; çelişki olursa öncelik sırası
`04-kararlar.md` > `01-spec.md` > `02-mimari.md`.

| Dosya | İçerik |
|---|---|
| [`00-vizyon.md`](docs/00-vizyon.md) | amaç, hedef, kapsam |
| [`01-spec.md`](docs/01-spec.md) | ekranlar, akışlar, durum hesabı, bildirim kuralları |
| [`02-mimari.md`](docs/02-mimari.md) | katmanlar, DB şeması, platform kanalı, snapshot şeması |
| [`03-kontrol-listesi.md`](docs/03-kontrol-listesi.md) | 34 maddelik şablon: aralık, neden, nasıl, doğrulama durumu |
| [`04-kararlar.md`](docs/04-kararlar.md) | 34 karar kaydı (ADR); gerekçeleriyle |
| [`05-is-listesi.md`](docs/05-is-listesi.md) | 18 ticket ve kabul kriterleri |
| [`06-test-plani.md`](docs/06-test-plani.md) | birim test tablosu, motor testleri, gerçek araba protokolü, adb komutları |
| [`07-android-notlar.md`](docs/07-android-notlar.md) | manifest, Kotlin notları, OEM/Doze davranışı |
| [`ILERLEME.md`](docs/ILERLEME.md) | ilerleme günlüğü, cihaz testi sonuçları, bilinen sorunlar |

## Durum

18 ticket'ın 17'si bitti (T17 gerçek araba testinin sonuçlarını bekliyor). 516 Dart + 88 Kotlin
testi yeşil, `flutter analyze` temiz, imzalı release APK telefonda çalışıyor.

Cihazda uçtan uca çalıştırılan zincir: durum hesabı → snapshot → Kotlin motoru → bildirim
kanalı → tepsi → bildirime dokunma → uygulamanın doğru sekmede açılması.

**Henüz denenmemiş olan:** gerçek `ACL_DISCONNECTED` ile kopma yolu ve hareket doğrulaması —
ikisi de arabada görülecek. Ayrıntı ve bilinen sorunlar
[`docs/ILERLEME.md`](docs/ILERLEME.md) sonunda.

## Kapsam dışı

Android Auto ekranı, OBD, GPS ile km, konum/geofence (K-32), çoklu araç, bulut, hesap, iOS,
harcama takibi, Play Store.

---

Şablondaki aralıkların bir kısmı üreticiye göre değişir.
[`docs/03-kontrol-listesi.md`](docs/03-kontrol-listesi.md) tablosunda ◐ ve ❌ işaretli maddeleri
kullanım kılavuzundan doğrula; uygulama bunu madde detayında da hatırlatır (K-28). ❌ olanlar
kapalı gelir.
