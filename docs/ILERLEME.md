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
| Ticket | Durum | Commit | Not |
|---|---|---|---|
| T01 Proje iskeleti | bitti | (bu commit) | ortam kurulumu dahil; cihazda `flutter run` beklemede |
| T02 Drift şeması ve DAO'lar | bekliyor | | |
| T03 Seed ve şablon birleştirme | bekliyor | | |
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

## Bilinen sorunlar
