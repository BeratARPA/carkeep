# 03 — Kontrol listesi şablonu (v1)

Makine okunur hali: `seed/checklist_seed.json` (build'de `assets/seed/checklist_seed.json`). Bu doküman ile JSON birebir aynı içeriği taşır; çelişki olursa JSON düzeltilir, doküman değil. Hedef araç: 2019 Fiat Egea 1.6 MultiJet (dizel, otomatik). Maddelerin çoğu her araç için geçerli; araca özel olanlar işaretli.

## Doğrulama durumu
| İşaret | Anlam |
|---|---|
| ✅ | Genel kabul görmüş, kaynaklar tutarlı. |
| ◐ | Kaynaklar var ama üretici değeri farklı olabilir; `sourceNote` alanında yazıyor. Kullanıcı kılavuzdan doğrular, aralığı Ayarlar'dan değiştirir. |
| ❌ | Varsayılan değer tahmin; madde kapalı gelir, doğrulamadan açılmaz. |

Kural: Claude Code aralıkları **değiştirmez**, madde **eklemez/çıkarmaz**. Eksik/yanlış gördüğünü `docs/ILERLEME.md` Notlar'a yazar.

## Alanlar
`id`, `group` (`frequent|monthly|quarterly|service|yearly|seasonal`), `name`, `schedule` (`{kind:"days",days}`, `{kind:"km",km}`, `{kind:"both",days,km}`, `{kind:"seasonal",dates:[{month,day}]}`), `measure` (`{type:"none"}`, `{type:"level",levels:[…]}`, `{type:"tires",unit:"bar"}`, `{type:"number",unit,label}`), `why`, `how[]`, `warn?`, `startsFromInstall` (son yapılış bilinmiyorsa kurulum gününden başlasın mı), `appliesLastService` (kurulumdaki "son servis" girişi bunu doldurur), `enabledByDefault`, `verified` (`true|partial|false`), `sourceNote?`.

## Özet tablo
| # | id | Ad | Grup | Aralık | Ölçüm | Açık | Doğr. |
|---|---|---|---|---|---|---|---|
| 1 | oil_level | Motor yağı seviyesi | frequent | 14 gün | level | ✓ | ✅ |
| 2 | tire_pressure | Lastik basıncı | frequent | 14 gün | tires | ✓ | ✅ |
| 3 | coolant_level | Soğutma suyu seviyesi | monthly | 30 gün | level | ✓ | ✅ |
| 4 | brake_fluid_level | Fren hidroliği seviyesi | monthly | 30 gün | level | ✓ | ✅ |
| 5 | washer_fluid | Silecek suyu | monthly | 30 gün | level | ✓ | ✅ |
| 6 | lights_horn | Işıklar ve korna | monthly | 30 gün | none | ✓ | ✅ |
| 7 | tire_visual | Lastik gövde kontrolü | monthly | 30 gün | none | ✓ | ✅ |
| 8 | leak_check | Park yeri sızıntı kontrolü | monthly | 30 gün | none | ✓ | ✅ |
| 9 | dpf_drive | Uzun yol sürüşü (partikül filtresi) | monthly | 30 gün | none | ✓ | ✅ |
| 10 | adblue_level | AdBlue seviyesi (varsa) | monthly | 30 gün | none | ✗ | ❌ |
| 11 | tread_depth | Lastik diş derinliği | quarterly | 90 gün | number mm | ✓ | ✅ |
| 12 | battery_terminals | Akü kutup başları | quarterly | 90 gün | none | ✓ | ✅ |
| 13 | wiper_blades | Silecek lastikleri | quarterly | 90 gün | none | ✓ | ✅ |
| 14 | spare_tire | Stepne ve tamir kiti | quarterly | 90 gün | none | ✓ | ✅ |
| 15 | belt_visual | V kayışı görsel kontrol | quarterly | 180 gün | none | ✓ | ✅ |
| 16 | oil_change | Motor yağı ve yağ filtresi | service | 15.000 km / 1 yıl | none | ✓ | ◐ |
| 17 | pollen_filter | Polen (kabin) filtresi | service | 15.000 km / 1 yıl | none | ✓ | ✅ |
| 18 | air_filter | Hava filtresi | service | 30.000 km | none | ✓ | ◐ |
| 19 | fuel_filter | Yakıt filtresi (dizel) | service | 30.000 km | none | ✓ | ◐ |
| 20 | brake_pads | Fren balataları | service | 20.000 km | none | ✓ | ✅ |
| 21 | tire_rotation | Lastik rotasyonu | service | 10.000 km | none | ✓ | ✅ |
| 22 | brake_fluid_change | Fren hidroliği değişimi | service | 2 yıl | none | ✓ | ✅ |
| 23 | coolant_change | Antifriz değişimi | service | 2 yıl | none | ✓ | ◐ |
| 24 | timing_belt | Triger seti | service | 120.000 km / 5 yıl | none | ✓ | ✅ |
| 25 | aux_belt | V kayışı değişimi | service | 80.000 km / 4 yıl | none | ✓ | ◐ |
| 26 | battery_age | Akü yaşı | service | 4 yıl | none | ✓ | ✅ |
| 27 | gearbox_oil | Otomatik şanzıman yağı | service | 60.000 km | none | ✗ | ❌ |
| 28 | safety_kit | Zorunlu ekipman ve son kullanma | yearly | 1 yıl | none | ✓ | ◐ |
| 29 | inspection | Araç muayenesi | yearly | 2 yıl | none | ✓ | ◐ |
| 30 | insurance | Trafik sigortası yenileme | yearly | 1 yıl | none | ✓ | ✅ |
| 31 | kasko | Kasko yenileme | yearly | 1 yıl | none | ✗ | ✅ |
| 32 | emission | Egzoz emisyon ölçümü | yearly | 1 yıl | none | ✗ | ❌ |
| 33 | ac_check | Klima kontrolü | yearly | 1 yıl | none | ✗ | ✅ |
| 34 | winter_tires | Kışlık / yazlık lastik değişimi | seasonal | 1 Kas, 1 Nis | none | ✓ | ◐ |

`startsFromInstall`: 1–15, 28, 33, 34 → true (fiziksel kontrol, kurulum gününden sayılır). Servis/belge maddeleri (16–27, 29–32) → false (son yapılış girilmeden "Bilinmiyor"). `appliesLastService`: 16, 17.

Kurulum sonrası ilk günlerde tipik görünüm: fiziksel maddeler "Zamanında" (vade = kurulum + aralık), servis maddeleri "Bilinmiyor" (tarih/km girilene kadar). Kullanıcı 16–17'yi kurulumdaki "son servis" adımıyla, 24–26 ve 29–30'u detay sayfasındaki "Tarih/km düzelt" ile doldurur; girmezse bildirim de gelmez, liste "Bilinmiyor"da bekler.

## Madde ayrıntıları

### 1. Motor yağı seviyesi — 14 gün — level: `Min'e yakın / Orta / Max'a yakın`
- Neden: Yağ azalınca motor kendini sürtünmeye karşı koruyamaz; en pahalı arıza buradan çıkar. Bu araçta seviye sensörü yok, çubuk dışında bilen yok. Dizelde partikül filtresi temizliği yağı zamanla mazotla artırabilir de; Max üstü de sorundur.
- Nasıl: (1) Motor soğuk (en az 10 dk durmuş), araba düz zeminde. (2) Çubuğu çek, bezle sil, sonuna kadar sok, tekrar çek. (3) Seviye Min ile Max arasında olmalı; Min'e yakınsa aynı özellikte yağdan yarım litre ekle, tekrar ölç. (4) Yağ sütlü/köpüklü görünüyorsa veya Max'ın üstündeyse ekleme, servise git.
- Servise git: Min altındaysa aracı çalıştırma; Max üstü veya sütlü yağ.

### 2. Lastik basıncı — 14 gün — tires (4 × bar), hedef araç profilinden
- Neden: Düşük basınç lastiği ısıtır, yakıtı artırır, fren mesafesini uzatır, lastiği omuzdan yer. Arabanın uyarısı ancak belirgin düşüşte yanar; 0,3 bar eksiği hiçbir zaman söylemez.
- Nasıl: (1) Lastikler soğukken ölç (en az 3 saat durmuş veya 2 km'den az gidilmiş). (2) Hedef değer sürücü kapısı direğindeki etikette; yük ve lastik ölçüsüne göre iki değer olabilir. (3) Dördünü de ölç, hedeften düşük olanı tamamla; sıcak ölçtüysen 0,2 bar ekle. (4) Basınç uyarı sistemi varsa şişirdikten sonra araç menüsünden sıfırla.
- Servise git: Bir lastik iki haftada 0,2 bar ve üstü kaybediyorsa lastikçiye (çivi, jant sızıntısı).
- Uygulama: girilen değer hedeften 0,3 bar ve fazla sapıyorsa alan amber vurgulanır.

### 3. Soğutma suyu seviyesi — 30 gün — level: `Min'de / Orta / Max'ta`
- Neden: Su azalırsa motor ısınır; ısınan motor conta yakar, silindir kapağı eğilir. Kapalı devre sistemde su kendi kendine eksilmez; eksiliyorsa kaçak var.
- Nasıl: (1) Motor soğukken bak; sıcakken genleşme kabının kapağını asla açma. (2) Şeffaf kaptaki seviye Min–Max arasında olmalı. (3) Düşükse kılavuzda yazan spesifikasyonda antifrizle tamamla, saf suyla değil. (4) Ne kadar eklediğini nota yaz; iki ayda tekrar düşerse kaçak var.
- Servise git: Tekrar eden düşüş, kapta yağ lekesi/çamur.

### 4. Fren hidroliği seviyesi — 30 gün — level: `Min'de / Orta / Max'ta`
- Neden: Seviye düşüyorsa iki ihtimal: balata bitmiş (pistonlar ileri çıkmış) ya da kaçak. İkisinde de fren gidiyor.
- Nasıl: (1) Kap motor bölmesinde sürücü tarafında, şeffaf. (2) Dışarıdan bak, Min–Max arası olmalı; kapağı açma, hidrolik nem çeker. (3) Düşükse ekleme, sebebi buldur.
- Servise git: Min'e inmişse veya pedal yumuşadıysa aracı kullanma, çektir.

### 5. Silecek suyu — 30 gün — level: `Boş / Yarım / Dolu`
- Neden: Boş depo yağmurda, çamurda ve tuzlu yolda görüşü anında kapatır.
- Nasıl: (1) Mavi kapaklı depoyu aç, silecek suyuyla doldur. (2) Kışın antifrizli silecek suyu; yazın da musluk suyu koyma, kireç fıskiyeyi tıkar.

### 6. Işıklar ve korna — 30 gün
- Neden: Yanmayan stop lambası arkadan çarpma sebebi; sinyal ve far cezası da var. Kendin fark edemezsin, arkadaki fark eder.
- Nasıl: (1) Kısa far, uzun far, park, sinyaller, dörtlü, sis farı. (2) Stop ve geri vites lambaları: birisi pedala bassın sen arkadan bak; yalnızsan cama/duvara yansımadan. (3) Plaka lambası ve korna.
- Servise git: LED modülse; ampulse hemen değiştir.

### 7. Lastik gövde kontrolü — 30 gün
- Neden: Yanakta şişlik iç kat kopmasıdır, patlar. Çivi yavaş yavaş boşaltır.
- Nasıl: (1) Dört lastiğin yanaklarında şişlik, kesik, çatlak var mı? (2) Sırtta çivi, vida, taş sıkışmış mı? (3) Aşınma tek tarafta mı (rot-balans sinyali)?
- Servise git: Yanak şişliği → lastik değişir, tamir olmaz. Çivi → çıkarma, lastikçiye.

### 8. Park yeri sızıntı kontrolü — 30 gün
- Neden: Sızıntı önce yerde görünür, panelde değil. Bir gecelik leke ucuz onarımla kapanır; bir ay sonra motor.
- Nasıl: (1) Sabah aracı çektikten sonra park yerine bak. (2) Siyah/kahverengi yağlı leke: motor yağı. Renkli (pembe/yeşil/mavi), tatlı kokulu: antifriz. Berrak su: klima yoğuşması, normal. (3) Lekenin yerini (ön/orta/arka) nota yaz.
- Servise git: Yağ veya antifriz lekesi.

### 9. Uzun yol sürüşü (partikül filtresi) — 30 gün — dizel
- Neden: Dizel partikül filtresi ancak uzun süre yüksek egzoz sıcaklığında kendini temizler. Sürekli kısa şehir içi sürüş filtreyi tıkar; DPF uyarısı ve pahalı temizlik/değişim gelir.
- Nasıl: (1) Ayda en az bir kez 20–30 dk kesintisiz, tercihen 70 km/s üstü ve 2.000 devir civarı sürüş. (2) Rölanti fanı çalışıyor ve tüketim geçici arttıysa temizlik yapıyordur; o anda motoru kapatma.
- Servise git: DPF lambası yandıysa kılavuzdaki rejenerasyon sürüşünü yap; sönmüyorsa servise.

### 10. AdBlue seviyesi (varsa) — 30 gün — kapalı gelir — ❌
- Neden: AdBlue biterse araç bir süre sonra çalışmaz; uyarı geç gelir, dolum yeri her yerde yok.
- Nasıl: (1) Gösterge menüsünden kalan menzili gör. (2) 1.000 km altına inmeden dolum; sadece ISO 22241 AdBlue.
- Not: Egea 1.6 MultiJet'in Euro 6d sürümlerinde SCR/AdBlue var; 2019 aracın durumunu kılavuz/gösterge menüsünden doğrula. Yoksa kapalı bırak.

### 11. Lastik diş derinliği — 90 gün — number (mm, "En düşük diş")
- Neden: 1,6 mm yasal sınır; 3 mm altında ıslak zemin tutuşu belirgin düşer, kışlıkta 4 mm.
- Nasıl: (1) Dişlerin içindeki aşınma göstergesi (kabartı) sırtla aynı seviyeye geldiyse sınır. (2) Diş ölçer varsa en düşük noktayı ölç, kaydet. (3) Orta aşınmış → basınç fazla; kenarlar → düşük.
- Servise git: 3 mm altı → değişimi planla; 1,6 altı → sürme.

### 12. Akü kutup başları — 90 gün
- Neden: Oksitlenen kutup başı bir sabah marş basmaz demektir; akü sağlam olsa bile.
- Nasıl: (1) Kutup başlarında beyaz/yeşil toz var mı? (2) Varsa fırça ve sıcak suyla temizle, kuruyunca ince vazelin. (3) Kelepçeler ve akü sabitleme gevşekse sık.
- Servise git: Gövde şişmiş veya sızıntı → akü değişir.

### 13. Silecek lastikleri — 90 gün
- Neden: Çizgi bırakan, ses çıkaran silecek yağmurda görüşü kapatır; kışa girmeden değiştirmek ucuz.
- Nasıl: (1) Cam ıslakken çalıştır: çizgi, atlama, gıcırtı? (2) Lastik kenarı yırtık/sertleşmişse değiştir; arka silecek dahil.

### 14. Stepne ve tamir kiti — 90 gün
- Neden: Stepne altı ayda kendi kendine iner; lazım olduğu gece inik stepneyle kalırsın. Kitli araçta köpüğün son kullanma tarihi var.
- Nasıl: (1) Bagaj altındaki stepnenin basıncını ölç; üzerindeki etikette yazan değere şişir. (2) Kriko, bijon anahtarı, bijon kilit adaptörü yerinde mi? (3) Tamir kiti varsa köpük şişesinin son kullanma tarihi.

### 15. V kayışı görsel kontrol — 180 gün
- Neden: Aksesuar kayışı alternatörü, klima kompresörünü çevirir; koparsa şarj kesilir, yolda kalırsın.
- Nasıl: (1) Motor kapalıyken kayışın görünen kısmı: çatlak, tüylenme, parlama? (2) Soğuk çalıştırmada ilk saniyelerde ıslık/cıyaklama → gerginlik veya yıpranma.
- Servise git: Çatlak/ses → kayış ve gergi kontrolü.

### 16. Motor yağı ve yağ filtresi — 15.000 km veya 1 yıl — ◐ — appliesLastService
- Neden: Yağ 15.000 km ya da bir yılda özelliğini kaybeder; dizelde DPF rejenerasyonu yağı mazotla inceltir. Filtre yağla birlikte değişir.
- Nasıl: (1) Kılavuzdaki viskozite/spesifikasyona uygun yağ (DPF'li motor için düşük küllü). (2) Fişi sakla; km ve tarihi buraya kaydet.
- Not: Türkiye'de yaygın uygulama 15.000 km / 12 ay; Tofaş resmi takvimi 20.000 km / 12 ay olabilir. Kendi tercihini Ayarlar'dan gir.

### 17. Polen (kabin) filtresi — 15.000 km veya 1 yıl — appliesLastService
- Neden: Tıkalı filtre camları buğulatır, klimayı zayıflatır, kabine koku verir.
- Nasıl: Torpido arkasında; yağ değişimiyle birlikte değiştirt veya kendin (5 dk).

### 18. Hava filtresi — 30.000 km — ◐
- Neden: Kirli hava filtresi tüketimi artırır, turboyu zorlar, performansı düşürür.
- Nasıl: Her periyodik bakımda kontrol, 30.000 km'de değişim; tozlu yolda daha erken.
- Not: Yaygın öneri 30.000 km; kılavuzu doğrula.

### 19. Yakıt filtresi (dizel) — 30.000 km — ◐
- Neden: Dizel enjektörleri kir ve neme karşı bu filtre korur; tıkanınca güç kaybı, zor çalışma, sonra enjektör masrafı.
- Nasıl: 30.000 km'de değişim; kalitesiz mazot kullanıldıysa daha erken. Hava alma servisin işi.
- Not: 1.3/1.6 MultiJet için 30.000 km yaygın; kılavuzu doğrula.

### 20. Fren balataları — 20.000 km
- Neden: Balata bittikten sonra disk de gider; kontrol ucuz, disk pahalı. Şehir içinde ön balata 30–40 bin km'de biter.
- Nasıl: (1) Jant aralığından balata kalınlığı: 3 mm altı değişim. (2) Metalik ses, titreme, uzayan mesafe → hemen kontrol. (3) Servis her bakımda ölçsün, nota yaz.
- Servise git: Metal metale ses → sürme.

### 21. Lastik rotasyonu — 10.000 km
- Neden: Önden çekişte ön lastikler çok daha hızlı aşınır; rotasyon dördünün ömrünü eşitler.
- Nasıl: (1) Lastikçide ön-arka yer değiştir (yön işaretli lastikte aynı taraf). (2) Sonra basınçları hedefe getir, TPMS sıfırla.

### 22. Fren hidroliği değişimi — 2 yıl
- Neden: Hidrolik havadan nem çeker; nemli hidrolik sert frende kaynar, pedal boşa basar. Görünüşte değişmez, takvimle değişir.
- Nasıl: 2 yılda bir serviste; kılavuzdaki sınıf (DOT 4).

### 23. Antifriz değişimi — 2 yıl — ◐
- Neden: Antifrizin korozyon önleyicisi zamanla biter; radyatör ve su pompası paslanır.
- Nasıl: Serviste, kılavuzdaki spesifikasyon.
- Not: Yaygın öneri 2 yıl; uzun ömürlü (OAT) antifrizde 5 yıl olabilir. Kılavuzu doğrula, aralığı düzenle.

### 24. Triger seti — 120.000 km veya 5 yıl — ✅ — araca özel (1.6 MultiJet kayışlı)
- Neden: 1.6 MultiJet çakışmalı motor: kayış koparsa supaplar pistonlara çarpar, motor tek seferde biter. Aralık hem km hem yıl; hangisi önce dolarsa.
- Nasıl: (1) 120.000 km veya 5 yılda bir; kayış, gergi ve devirdaim pompası set olarak. (2) Arızaya değil takvime göre; kayış uyarı vermez.
- Servise git: Motor bölmesinden tıkırtı/sürtme sesi → sürme.
- Not: Kaynaklar 120.000 km / 5 yıl konusunda hemfikir; bazı servisler 7 yıl der, 5 yılı esas al.

### 25. V kayışı değişimi — 80.000 km veya 4 yıl — ◐
- Neden: Alternatör ve klima kayışı; kopunca şarj kesilir. Trigerle birlikte değiştirmek işçilikten kazandırır.
- Nasıl: 80.000 km / 4–5 yılda değişim; 60.000 km bakımında kontrol.
- Not: Servis kaynaklarında 80.000 km / 4–5 yıl; kılavuzu doğrula.

### 26. Akü yaşı — 4 yıl
- Neden: Akü 4–5 yılda tükenir; genellikle ilk soğuk sabah haber vermeden bırakır. Yaşını bilmek en ucuz sigorta.
- Nasıl: (1) Akünün üstündeki üretim tarihi (etiket/kod); satın alma tarihini gir. (2) 4 yılı geçtiyse kışa girmeden test ettir.
- Servise git: Soğukta marş yavaşladıysa test.

### 27. Otomatik şanzıman yağı — 60.000 km — kapalı gelir — ❌
- Neden: "Ömürlük" denilse de 60–80 bin km'de değişim vites kalitesini ve şanzıman ömrünü korur.
- Nasıl: Yetkili servis/şanzımancı, doğru spesifikasyon.
- Not: Şanzıman tipine (tork konvertörlü / DCT) göre değişir; kılavuz ve serviste doğrula, sonra aç.

### 28. Zorunlu ekipman ve son kullanma — 1 yıl — ◐
- Neden: Üçgen reflektör (2), ilk yardım çantası ve yangın söndürücü muayenede ve denetimde sorulur; söndürücü ve ilk yardım malzemesinin son kullanma tarihi var.
- Nasıl: (1) Söndürücü: gösterge yeşilde mi, son kullanma/dolum tarihi? (2) İlk yardım çantası: eksik ve tarihi geçmiş malzeme. (3) 2 üçgen reflektör, yedek ampul seti, reflektif yelek.
- Not: Zorunlu ekipman listesi ve söndürücü periyodu için güncel mevzuatı doğrula.

### 29. Araç muayenesi — 2 yıl — ◐ — son muayene tarihi girilir
- Neden: Binekte ilk muayene 3. yılda, sonra 2 yılda bir. Gecikmenin her ayı için ek ücret ve ceza.
- Nasıl: (1) Son muayene tarihini ruhsat/e-Devlet'ten gir. (2) Randevuyu 1 ay önceden al; öncesinde ışıklar, lastik, silecek, cam çatlağı, emisyon.
- Not: Süreleri e-Devlet/TÜVTÜRK'ten doğrula.

### 30. Trafik sigortası yenileme — 1 yıl — poliçe başlangıcı girilir
- Neden: Sigortasız gün trafik cezası ve kaza riski.
- Nasıl: (1) Poliçe başlangıç tarihini "son yapılış" olarak gir. (2) Bitişten 2 hafta önce teklif topla.

### 31. Kasko yenileme — 1 yıl — kapalı gelir
- Neden: Kasko varsa yenileme tarihi trafik sigortasından farklı olabilir.
- Nasıl: Poliçe başlangıç tarihini gir.

### 32. Egzoz emisyon ölçümü — 1 yıl — kapalı gelir — ❌
- Neden: Egzoz emisyon pulu olmadan ceza; periyot araç tipine göre değişir.
- Nasıl: Son ölçüm tarihini gir; periyodu mevzuattan doğrulayıp aralığı düzenle.
- Not: Binek için periyot/muafiyet mevzuata göre değişti; doğrulamadan açma.

### 33. Klima kontrolü — 1 yıl — kapalı gelir
- Neden: Gaz eksilmesi ve evaporatör bakterisi yaz gelince ortaya çıkar; bahar sonunda kontrol ucuz.
- Nasıl: Nisan–Mayıs'ta soğutma performansı; koku → evaporatör temizliği, soğutmuyor → gaz/kaçak.

### 34. Kışlık / yazlık lastik değişimi — her yıl 1 Kasım ve 1 Nisan — ◐
- Neden: 7 °C altında yazlık lastik sertleşir ve tutmaz. Zorunluluk şehirlerarası/ticari için; özel araçta zorunlu olmasa da fren mesafesi farkı büyük.
- Nasıl: (1) Kasım başında kışlık, Nisan başında yazlık; havaya göre 2 hafta oynat. (2) Değişimde diş derinliği ve depodaki lastiklerin yaşı (DOT kodu, 6 yıl). (3) Sonra basınç ve TPMS sıfırlama.
- Not: Zorunluluk kapsamı ve tarihler için güncel yönetmeliği doğrula.

## Araca özel bilgi (araç profili, şablon değil)
- Hedef lastik basıncı: ön/arka bar — kurulumda boş, Ayarlar → Araç'tan girilir (sürücü kapısı etiketi).
- Egea 1.6 MultiJet için bilinenler: triger kayışlı ve çakışmalı motor (24); DPF var (9); TPMS dolaylı, basınç değeri göstermez (2).
