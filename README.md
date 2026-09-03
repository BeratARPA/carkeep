# CarKeep — Claude Code başlangıç kiti

Tek araç için rutin bakım hatırlatıcısı (Flutter, Android). Arabanın Bluetooth'undan kopunca gecikmiş kontrolleri bildirir. Bu klasör kodu değil, kodu yazacak olan Claude Code'un ihtiyaç duyduğu her şeyi içerir.

## İçerik
```
CLAUDE.md                 Claude Code'un her oturumda okuduğu proje anayasası
PROMPT.txt                Claude Code'a yapıştırılacak tek prompt
docs/00-vizyon.md         amaç, hedef, kapsam
docs/01-spec.md           ekranlar, akışlar, durum hesabı, bildirim kuralları
docs/02-mimari.md         katmanlar, DB şeması, platform kanalı, snapshot şeması
docs/03-kontrol-listesi.md 34 maddelik şablon: aralık, neden, nasıl, doğrulama durumu
docs/04-kararlar.md       ADR'ler (çelişkide en yüksek öncelik)
docs/05-is-listesi.md     18 ticket, kabul kriterleri, kontrol noktaları
docs/06-test-plani.md     birim test tablosu, motor testleri, gerçek araba protokolü, adb
docs/07-android-notlar.md manifest, Kotlin iskeletleri, OEM/Doze notları
docs/ILERLEME.md          Claude Code'un doldurduğu ilerleme günlüğü
seed/checklist_seed.json  şablonun makine okunur hali (assets/seed altına kopyalanır)
preview/carkeep-onizleme.html tıklanabilir referans arayüz (tarayıcıda açılır)
```

## Kullanım
1. Boş bir klasör aç (ör. `~/projects/carkeep`) ve zip'i içine çıkar; kit dosyaları klasörün kökünde olsun (`CLAUDE.md` kökte).
2. Ön koşullar: Flutter SDK (stable), Android SDK + JDK 17, USB hata ayıklama açık **fiziksel** bir Android telefon (emülatörde Bluetooth yok), telefonun arabayla (Uconnect) eşleşmiş olması.
3. Klasörde terminal: `claude` — Claude Code açılınca `PROMPT.txt` içeriğini yapıştır.
4. Claude Code önce dokümanları okur, özet ve varsa çelişki listesi yazar, sonra T01'den başlar.
5. Üç kontrol noktasında durur ve senden fiziksel cihaz testi ister:
   - **T05**: izinler ve eşleşmiş cihaz listesi telefonda görünüyor mu.
   - **T12**: gerçek arabada kopma → bildirim (protokol `docs/06-test-plani.md` §3). Sonuçları Claude Code'a yaz.
   - **T18**: release APK.
6. Sonuçları ve gördüğün hataları Claude Code'a düz metin yaz; düzeltmeler T17'de toplanır.

## Bilinmesi gerekenler
- Mockup'taki "2 dk geri bağlanma bekleniyor" davranışı uygulamada "hemen bildir, 2 dk içinde geri bağlanırsa iptal et" olarak uygulanır (`docs/04-kararlar.md` K-06). Kullanıcı açısından sonuç aynı.
- Şablondaki aralıkların bir kısmı üreticiye göre değişebilir; `docs/03-kontrol-listesi.md` tablosunda ◐ ve ❌ işaretli maddeleri kullanım kılavuzundan doğrulayıp Ayarlar'dan düzelt. ❌ olanlar kapalı gelir.
- Servis geçmişi bilinmeyen maddeler (triger, fren hidroliği vb.) "Bilinmiyor"da bekler; detay sayfasından "Tarih/km düzelt" ile son yapılış girilince hesaba girer.
- Uygulamayı "Durmaya zorla" yaparsan Android receiver'ı kapatır; bir kez açman yeter.
- Telefon markasına göre pil kısıtlaması ayarı gerekebilir (`docs/07-android-notlar.md` §7).

## Kapsam dışı (v1)
Android Auto ekranı, OBD, GPS ile km, çoklu araç, bulut, iOS, harcama takibi, Play Store.
