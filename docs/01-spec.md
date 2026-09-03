# 01 — Ürün ve davranış spec'i

Referans arayüz: `preview/carkeep-onizleme.html` (ekran düzeni, satır yapısı, metinler, renkler). Bu doküman davranışı tanımlar; mockup'ta olmayan her şey burada.

## 1. Kavramlar
| Terim | Tanım |
|---|---|
| Madde (item) | Kontrol edilecek tek şey. Şablondan gelir veya kullanıcı ekler. `docs/03-kontrol-listesi.md`. |
| Takvim (schedule) | Maddenin ne zaman "geldiğini" belirleyen kural. 4 tür: `days`, `km`, `both`, `seasonal`. |
| Son yapılış (last done) | Maddenin en son kaydedildiği tarih ve km. Null olabilir. |
| Vade (due) | Son yapılış + aralık. `dueDay` (takvim günü) ve/veya `dueKm`. |
| Durum (state) | `overdue` (gecikmiş), `soon` (yaklaşan), `ok` (zamanında), `unknown` (bilinmiyor). |
| Kayıt (log) | "Yaptım" ile oluşan satır: tarih, km, ölçüm değeri, not. |
| Sürüş (trip) | Arabanın Bluetooth'una bağlanma → kopma arası. |
| Snapshot | Dart'ın her veri değişiminde Kotlin'e yazdığı JSON: maddelerin vade değerleri + kurallar. Bildirim motoru yalnız bunu okur. |
| Motor (ReminderEngine) | Kotlin. Kopmada snapshot'ı okur, kuralları uygular, bildirimi basar/iptal eder. |

## 2. Durum hesabı (tek doğruluk kaynağı: `lib/domain/status_calculator.dart`)

Girdi: madde (takvim, son yapılış, `snoozeUntilDay`, `startsFromInstall`), araç `currentKm`, `installDay`, `today`.

### 2.1 Vade
- `days`: `dueDay = lastDoneDay + intervalDays`. Son yapılış null ise: `startsFromInstall=true` → `lastDoneDay := installDay`; değilse durum `unknown`.
- `km`: `dueKm = lastDoneKm + intervalKm`. Son yapılış null → `unknown` (servis geçmişi bilinmeden hesap yok).
- `both`: ikisi de hesaplanır. Son yapılış null → `unknown`.
- `seasonal`: `dates = [{month,day}...]`. `dueDay` = son yapılıştan (null ise `installDay - 1`) **sonraki ilk** tarih. Yıl sınırını geçer.

### 2.2 Kalan
- `daysLeft = dueDay - today` (takvim günü farkı, saat yok).
- `kmLeft = dueKm - currentKm`.
- `both` için bağlayıcı boyut: `kmLeft / intervalKm` ile `daysLeft / intervalDays` oranlarından **küçük** olan. Eşitse km.

### 2.3 Durum
1. `unknown` yukarıdaki kurallarla.
2. Bağlayıcı kalan `< 0` → `overdue`. (`both`'ta herhangi biri negatifse `overdue`.)
3. Değilse `soon` eşiği: `days` için `daysLeft ≤ 3`; `km` için `kmLeft ≤ 1000`; `seasonal` için `daysLeft ≤ 14`.
4. Değilse `ok`.
5. `overdue` ve `snoozeUntilDay > today` → `soon`, metin "Yarın".

### 2.4 Metinler (`format_tr`)
| Durum | Boyut | Metin |
|---|---|---|
| overdue | gün | `7 gün gecikti` |
| overdue | km | `480 km geçti` |
| soon | gün, 0 | `Bugün` |
| soon | gün, 1–3 (seasonal 1–14) | `2 gün kaldı` |
| soon | km | `850 km kaldı` |
| soon | ertelenmiş | `Yarın` |
| ok | gün | `16 Eyl` (yıl farklıysa `16 Eyl 2027`) |
| ok | km | `1.480 km kaldı` |
| unknown | – | `Tarih gir` |

Uzun biçim (detay sayfası): `{metin}. {aralık}.` Aralık: `14 günde bir`, `Ayda bir`, `3 ayda bir`, `Yılda bir`, `2 yılda bir`, `15.000 km'de bir`, `15.000 km'de bir veya yılda bir`, `Her yıl 1 Kas ve 1 Nis`.

### 2.5 Sıralama (ana ekran)
- Gecikmiş: en çok gecikmiş önce (bağlayıcı oran en negatif).
- Yaklaşan: en yakın önce.
- Zamanında: en yakın önce.
- Bilinmiyor: şablon sırası.
Kapalı (`enabled=false`) maddeler ana ekranda görünmez, snapshot'a girmez.

## 3. Ekranlar

### 3.1 Kurulum sihirbazı (ilk açılış; `vehicles` boşsa)
Adımlar, üstte 6 çubuklu ilerleme. Alt: "Geri" (1. adımda "Örnekle geç" yok — gerçek uygulamada yok) ve "İleri"/"Başla".
1. **Aracın** — Marka, Model, Yıl (metin). Yardım: "Bir kere gir, bir daha sorulmaz." Zorunlu: marka.
2. **Kaç km'de?** — sayı. Yardım: "Gösterge km'si. Km'ye bağlı bakımlar bundan sayılır; sonra yakıt alırken güncellersin." Zorunlu.
3. **İzinler** — üç satır, her birinde durum ve buton:
   - Bluetooth (Android 12+ `BLUETOOTH_CONNECT`): "Arabanın Bluetooth'unu görmem ve kopmayı yakalamam için."
   - Bildirim (Android 13+ `POST_NOTIFICATIONS`): "Gecikmiş kontrolü söyleyebilmem için."
   - Pil optimizasyonu (isteğe bağlı): "Telefon uygulamayı uyutursa kopmayı kaçırabilirim." Buton sistem ayarını açar.
   Reddedilirse ilerlemeye izin ver; ana ekranda uyarı şeridi (bkz. 3.2).
4. **Arabanın Bluetooth'u hangisi?** — eşleşmiş cihaz listesi (ad + adres), tekli seçim. Yardım: "Telefon bu cihazdan koptuğunda arabadan indiğini anlar ve o anda hatırlatır. Android Auto kullanıyorsan da aynı cihaz." Liste boşsa: "Eşleşmiş cihaz yok. Telefonu önce arabayla eşleştir." + "Yenile". Bluetooth izni yoksa: izin butonu. "Sonra seçerim" ile geçilebilir (Ayarlar'dan seçilir).
5. **Son servis (isteğe bağlı)** — "Son yağ değişimi ne zaman ve kaç km'de yapıldı?" tarih + km. Girilirse `appliesLastService=true` maddelerin son yapılışı bu değere set edilir. Boş bırakılırsa bu maddeler `unknown` kalır.
6. **Kontrol listesi** — şablon maddeleri grup başlıklarıyla, her satırda aralık metni ve aç/kapat. Yardım: "Aralıklar hazır. İstemediğini kapat; sonra Ayarlar'dan değiştirebilirsin." "Başla".

"Başla" sonrası: araç kaydı, maddeler şablondan kopyalanır, `settings.install_day = today`, `settings.template_version`, snapshot yazılır, günlük yedek işi planlanır, ana ekrana geçilir, toast: "Hazır. Bir sonraki sürüşten sonra hatırlatırım."

### 3.2 Kontroller (ana ekran, alt sekme 1)
- Üst: araç adı (küçük), km (büyük, `118.420 km`) + "Km gir" bağlantısı, chip: `Uconnect bağlı değil` / `Uconnect bağlı, sürüşte` (Kotlin'in `connected_at` değerinden; uygulama açıkken `getBluetoothState` ile, her `resume`'da yenilenir).
- Uyarı şeritleri (varsa, üstte, kapatılamaz, ilgili ayarı açar): "Bluetooth izni yok, kopmayı yakalayamam." / "Bildirim izni yok." / "Araba seçilmedi." / "Pil optimizasyonu açık, bildirim gecikebilir." (sonuncusu kapatılabilir, tekrar gösterilmez).
- Bölümler: `Gecikmiş (n)` kırmızı, `Yaklaşan (n)` amber, `Zamanında (n)`, `Bilinmiyor (n)`. Boş bölüm gösterilmez. Gecikmiş ve yaklaşan ikisi de boşsa: "Her şey zamanında. Bir sonraki sürüşten sonra gecikmiş bir şey olursa haber veririm."
- Satır: ad, alt satır `Son: 12 Ağu, Orta` (km maddesi: `Son: 104.900 km, 12 Mar`), sağda durum metni. Gecikmiş satırda sol kırmızı çizgi. Dokunma → madde detayı.
- Bildirimden "Aç" ile gelindiyse Gecikmiş bölümü bir kez vurgulanır (arka plan kırmızıdan beyaza sönümlenir).

### 3.3 Madde detayı (alt sayfa)
- Başlık, durum satırı (uzun biçim, renkli).
- "Neden" paragrafı, "Nasıl bakılır" numaralı adımlar, varsa "Servise git" uyarı satırı (kırmızı ikonlu tek satır).
- Ölçüm bloğu (madde tipine göre):
  - `level`: seçenek çipleri (şablondan). Zorunlu.
  - `tires`: 4 sayı alanı (Ön sol, Ön sağ, Arka sol, Arka sağ), birim bar, hedef satırı: "Hedef: ön 2,3 / arka 2,3" (araçta tanımlıysa; değilse "Hedef değer sürücü kapısındaki etikette yazar."). Dördü de zorunlu. Hedeften 0,3 bar ve üzeri sapan alan amber vurgulanır (bilgi, engel değil).
  - `number`: tek sayı + birim (ör. mm). İsteğe bağlı.
  - `none`: blok yok.
- "Not (isteğe bağlı)" metin alanı.
- "Önceki kayıtlar": son 3 kayıt (`16 Ağu, 118.100 km, 2,3 / 2,3 / 2,3 / 2,2 bar. Arka sağ düşük`).
- Butonlar: **Yaptım olarak kaydet** (birincil), gecikmişse **Yarın hatırlat**, her zaman **Tarih/km düzelt** (metin bağlantısı → 3.4).
- Kaydet: doğrulama (zorunlu ölçüm eksikse toast "Önce seviyeyi seç" / "Dört lastiği de gir"), log satırı, maddenin son yapılışı = bugün + güncel km + değer, `snoozeUntilDay = null`, snapshot yenilenir, sayfa kapanır, toast: `Kaydedildi. Sonraki: 16 Eyl` / `Sonraki: 16 Eyl veya 133.420 km`.
- Yarın hatırlat: `snoozeUntilDay = today + 1`, toast "Yarın tekrar hatırlatırım", snapshot yenilenir.

### 3.4 Tarih/km düzelt (diyalog)
"Bu madde en son ne zaman yapıldı?" tarih seçici (bugünden ileri seçilemez) + km (km/both maddelerde zorunlu, diğerlerinde gizli). Kaydet → son yapılış güncellenir, **log satırı oluşturulmaz** (geriye dönük düzeltme), snapshot yenilenir. `unknown` maddeler için tek çıkış yolu budur; detay sayfası `unknown` durumda bu diyaloğu öne çıkarır ("Bu bilgi olmadan hesaplayamam").

### 3.5 Km gir (alt sayfa)
Sayı alanı (varsayılan güncel km), yardım: "Yakıt alırken gösterge km'sini gir. Km'ye bağlı bakımlar bununla hesaplanır." Kaydet: boş/geçersiz → "Km gir"; güncelden küçük → `Şu anki km 118.420. Daha küçük olamaz` (düzeltme Ayarlar → Araç'tan); geçerli → `settings/vehicles.current_km`, toast `Km güncellendi: 119.950`, snapshot yenilenir.

### 3.6 Geçmiş (alt sekme 2)
Kayıtlar tarihe göre gruplu (`3 Eyl 2026` başlığı), yeni üstte. Satır: madde adı, alt satır `değer, km. not`. Dokunma → salt okunur detay + "Sil" (onay diyaloğu: "Bu kayıt silinsin mi? Maddenin son yapılışı bir önceki kayda döner."). Silince madde `last_done*` bir önceki loga göre yeniden hesaplanır (log yoksa null). Boş: "Henüz kayıt yok. Bir kontrolü 'Yaptım' diye kaydettiğinde burada görünür."

### 3.7 Ayarlar (alt sekme 3)
Bölümler ve satırlar:
- **Araç**: marka/model/yıl düzenle; km düzelt (her değere izin, onay: "Km geriye alınıyor, emin misin?"); hedef lastik basıncı ön/arka (bar, isteğe bağlı).
- **Arabanın Bluetooth'u**: seçili cihaz (dokun → cihaz listesi alt sayfası); altında tanı satırı: `Son kopma: 3 Eyl 14:30, 25 dk sürüş, bildirim gönderildi` / `... 2 dk, sürüş sayılmadı` / `Henüz kopma görülmedi`.
- **Hatırlatma** (kurallar, §7): "Sadece gecikmiş varsa" (aç/kapat), "Günde en fazla bir" (aç/kapat), "En az sürüş süresi" (dk, 1–30, varsayılan 5), "Geri bağlanma toleransı" (dk, 0–5, varsayılan 2), "Sürüş yoksa yedek bildirim" (kapalı / 3 / 7 / 14 gün sonra, varsayılan 7).
- **Kontrol listesi**: her madde: ad, aralık metni; sağda aralık adımlayıcı (−/+ preset üzerinde: gün `7,14,30,60,90,180,365,730,1825`; km `5.000,10.000,15.000,20.000,30.000,60.000,80.000,120.000`; `both` maddede + ve − yalnız km'yi değiştirir, gün için satıra dokunup düzenleme sayfası), aç/kapat. Satıra dokun → madde düzenleme sayfası: ad, takvim türü ve değerleri, ölçüm tipi (şablon maddelerinde ölçüm tipi kilitli), "Tarih/km düzelt", şablon maddesi değilse "Sil". Listenin altında "Madde ekle" (aynı sayfa, boş).
- **Uygulama**: izin durumları (üçü) + düzelt butonları; "Şablon sürümü 1"; "Verileri sıfırla" (onay, her şeyi siler, kuruluma döner); debug derlemede "Geliştirici": `Kopmayı simüle et (25 dk)`, `Kopmayı simüle et (2 dk)`, `Bağlanmayı simüle et`, `Snapshot'ı göster`, `Yedek işi şimdi çalıştır`.

### 3.8 Bildirim (Android, Kotlin basar)
- Kanal: id `reminders`, ad "CarKeep hatırlatmaları", `IMPORTANCE_HIGH` (heads-up), varsayılan ses, titreşim.
- Bildirim id sabit `1001` (yenisi eskisini değiştirir).
- Başlık: `2 kontrol gecikti` (n=1: `1 kontrol gecikti`).
- Metin: ilk 3 madde adı virgülle, fazlası ` ve 2 daha`. `BigTextStyle`: tüm adlar satır satır + son satır "Arabanın yanındayken birkaç dakika sürer."
- Yedek (sürüşsüz) bildirimde başlık aynı; metnin başına `{n} gündür sürüş yok.` eklenir (son sürüş bilinmiyorsa `Bir süredir sürüş yok.`).
- Dokunma: `MainActivity`, extra `carkeep_action=overdue` → Kontroller sekmesi, vurgu.
- Eylemler: **Aç** (dokunma ile aynı), **Yarın** (`NotifActionReceiver`: `global_snooze_until_day = tomorrow`, bildirimi iptal et, pending event `snooze`).
- `setAutoCancel(true)`, `setOnlyAlertOnce(true)`, kategori `CATEGORY_REMINDER`.

## 4. Km ve tarih kuralları
- Km yalnız kullanıcıdan girilir (Km gir, kayıt anındaki km, Tarih/km düzelt, Ayarlar → Araç).
- "Yaptım" kaydındaki km = o anki `current_km` (kullanıcı ayrıca km girmek isterse önce Km gir).
- Tarih hesapları yerel takvim günü. Gün anahtarı `yyyy-MM-dd`. Gece yarısı geçişi: `today` her hesapta yeniden alınır.

## 5. Şablon ve sürümleme
- `assets/seed/checklist_seed.json` `version` alanı taşır. Kurulumda maddeler `template_key = id` ile kopyalanır.
- Uygulama açılışında `settings.template_version < seed.version` ise: seed'de olup DB'de olmayan maddeler eklenir (kapalı olarak, toast: "Şablona 2 yeni madde eklendi, Ayarlar'dan aç"). Mevcut maddelerin kullanıcı değişiklikleri (aralık, aç/kapat, metinler) **asla** ezilmez. Seed'den kaldırılan maddeler DB'de kalır.
- Kullanıcı eklediği maddede `template_key = null`.

## 6. Snapshot (Dart → Kotlin)
Her şu olayda yeniden üretilip `writeSnapshot` ile yazılır: kurulum bitişi, kayıt, silme, tarih/km düzeltme, km girişi, madde aç/kapat/aralık/ekle/sil, kural değişikliği, araç/cihaz değişikliği, uygulama açılışı (`resume`), erteleme. Şema `02-mimari.md` §5.

Snapshot yalnız `enabled=true` ve durumu `unknown` olmayan maddeleri içerir. `dueDay`/`dueKm` Dart'ta hesaplanır; Kotlin sadece `dueDay < today` / `dueKm < km` karşılaştırır.

## 7. Bildirim kuralları (ReminderEngine, Kotlin)

### 7.1 Olaylar
- `ACL_CONNECTED` (seçili araç adresi): `connected_at` boşsa `= now`. Doluysa ve `now - last_notified_at ≤ graceMinutes` ise **hızlı geri bağlanma**: bildirim iptal, `last_notified_day := prev_last_notified_day`, son trip kaydı `counted=false, notified=false, note="reconnect"` olarak güncellenir; `connected_at` **korunur** (sürüş devam ediyor sayılır). Diğer durumlarda `connected_at` korunur.
- `ACL_DISCONNECTED` (seçili araç adresi): `duration = now - connected_at` (dk). `connected_at := null`. Trip kaydı yazılır. Sonra:
  1. `connected_at` yoksa (bilinmeyen bağlantı) → `duration = 0`.
  2. `duration < minTripMinutes` → dur. Trip `counted=false`.
  3. Snapshot yok / araç adresi eşleşmiyor → dur.
  4. `global_snooze_until_day > today` → dur (`note="snoozed"`).
  5. Gecikmiş liste = snapshot maddelerinden `(dueDay != null && dueDay < today) || (dueKm != null && dueKm < km)` ve `snoozeUntilDay` bugünden sonra olmayanlar.
  6. `onlyOverdue && liste boş` → dur.
  7. `oncePerDay && last_notified_day == today` → dur (`note="once_per_day"`).
  8. Bildirimi bas; `prev_last_notified_day := last_notified_day`; `last_notified_day := today`; `last_notified_at := now`; trip `notified=true`.
- `onlyOverdue=false` iken liste boş olsa da bildirim: başlık "Kontroller zamanında", metin "Gecikmiş bir şey yok." (bu mod, motorun çalıştığını görmek için).
- Başka cihazların ACL olayları yok sayılır. Araç seçilmemişse motor hiçbir şey yapmaz.

### 7.2 Sürüşsüz dönem yedeği (`DailyCheckWorker`)
- Kendini yeniden planlayan tek seferlik WorkManager işi; hedef saat 19:00 (±WorkManager esnekliği), uygulama açılışında `REPLACE` ile planlanır.
- Koşul: `fallbackAfterDays` açık ve en az bir gecikmiş maddenin `today - dueDay ≥ fallbackAfterDays` (km maddeleri hariç) ve `last_notified_day` boş veya `≤ today - 3` ve global erteleme yok → yedek bildirimi bas, `last_notified_*` güncelle, pending event `fallback`.
- Aksi halde sessiz. Her çalışmada kendini bir sonraki 19:00'a yeniden planlar.

### 7.3 Pending events (Kotlin → Dart)
Kotlin her trip/snooze/fallback olayını `pending_events_json` dizisine ekler. Dart açılışta ve `resume`'da `drainPendingEvents` ile alır, `trips`/`settings` tablolarına işler, diziyi boşaltır. Kayıp olmaması için Dart işlemi bitene kadar Kotlin tarafı temizleme yapmaz (`drain` = oku + sil tek çağrı; Dart DB yazımı başarısızsa bir sonraki drain'de tekrar gelmesi için `ack` yok — v1'de kabul: drain atomik, DB yazımı hemen ardından).

## 8. İzinler ve dayanıklılık
- `BLUETOOTH_CONNECT` (API 31+) runtime; API 30 ve altı için `BLUETOOTH` normal izin. `POST_NOTIFICATIONS` (API 33+) runtime.
- Receiver manifest'te; uygulama "force stop" edilmişse Android receiver'ı çalıştırmaz → kullanıcı uygulamayı bir kez açmalı (kurulum bunu zaten yapar). Ayarlar → Uygulama'da açıklama satırı.
- OEM pil kısıtları (Xiaomi/Huawei/Samsung/Oppo): `07-android-notlar.md` §7. Uygulama içinde "Pil optimizasyonu" satırı + üretici özel not.
- Bluetooth kapalıysa olay gelmez; uygulama bunu tespit etmez, sadece chip "bağlı değil" gösterir.

## 9. Hata ve boş durumlar (metinler `strings_tr.dart`)
- Eşleşmiş cihaz yok → "Telefonu önce arabayla eşleştir." + Yenile.
- İzin reddedildi (kalıcı) → "İzin kapalı. Ayarlardan aç." + sistem ayarını açan buton.
- Şablon yüklenemedi (asset bozuk) → uygulama açılmaz, tam ekran hata: "Şablon dosyası okunamadı." (geliştirici hatası; test eder).
- DB açılamadı → tam ekran hata + "Verileri sıfırla".
- Snapshot yazılamadı → sessiz, `Log.e`, bir sonraki olayda tekrar denenir.

## 10. Görsel dil
Mockup'taki token'lar: metin `#141A24`, ikincil `#4A5361`, üçüncül `#8A93A0`, ekran `#F6F7F9`, yüzey `#FFFFFF`, çizgi `#E1E5EA`, kırmızı `#C4301C`/`#FBEBE8`, amber `#A66300`/`#FFF3DC`, yeşil `#1E7A45`/`#E4F3EA`. Birincil buton siyah dolgu, 48 dp, 12 dp yuvarlak. Liste satırları kart değil, ince çizgiyle ayrılmış; yalnız gecikmiş satırda sol kırmızı çizgi. Yazı tipi Manrope (Google Fonts'tan indirilip `assets/fonts` altına konur; ağ yok). Sayılarda tabular rakam (`FontFeature.tabularFigures()`). Material 3, `useMaterial3: true`, tema `lib/core/theme.dart`. Karanlık tema v1'de yok.
