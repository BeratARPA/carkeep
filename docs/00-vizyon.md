# 00 — Vizyon

## Kök sorun
Rutin araba kontrollerinin doğal bir tetikleyicisi yok. Araba ancak sorun çıktıktan sonra uyarır (yağ lambası, lastik uyarısı = geç kalınmış). "2 haftada bir" gibi görevleri insan hafızası tutmaz; takvim hatırlatması yanlış anda gelir (masadasın, arabanın yanında değilsin), ertelenir, unutulur. Hazır uygulamalar defter mantığında: açmayı hatırlaman gerekir, aralıkları senin bilmen gerekir.

Kullanıcının kendi ifadesiyle üç sorun: **unutuyorum**, **bilmiyorum** (neye ne sıklıkla bakılır), **karıştırıyorum** (en son ne zaman yaptım).

## Amaç (tek cümle)
Kullanıcı hiçbir aralığı ezberlemeden ve uygulamayı açmayı hatırlamadan rutin araba kontrollerini zamanında yapsın. Hatırlama yükü kullanıcıdan uygulamaya geçer.

## Hedef kullanıcı
- v1: Berat, tek araç (2019 Fiat Egea 1.6 MultiJet, Uconnect'li), Android telefon. Kişisel kullanım, Play Store yok.
- Sonrası: arabadan anlamayan, "neye ne zaman bakılır" bilmeyen sıradan araç sahibi. Tamirci/meraklı değil.

## Kullanıcıya ne verir
| Sorun | Karşılığı |
|---|---|
| Bilmiyorum | Hazır kontrol listesi, aralıklar gömülü, "neden" ve "nasıl" her maddede. |
| Unutuyorum | Bildirim yapabileceğin anda gelir: arabadan indiğin saniye. Sürüşsüz uzun dönemde günlük sessiz yedek bildirim. |
| Karıştırıyorum | Her maddenin "en son ne zaman, ne değerle" kaydı; geçmiş listesi. |
| Dolaylı | Düşük yağ/su/basınç erken yakalanır. Triger, fren hidroliği gibi "unutulursa motor/fren gider" maddeleri takvimde. Geçmiş, satışta bakım kanıtı. |

## Başarı ölçütü
1. 3 ay boyunca hiçbir aktif madde kendi aralığını 1 haftadan fazla aşmıyor.
2. Kullanıcı uygulamayı bildirim dışında açmak zorunda kalmıyor. Uygulama sessizce çalışıyorsa amacına ulaşmıştır.
3. Gerçek arabada: kontak kapatıp arabadan indikten en geç 30 sn içinde bildirim (gecikmiş madde varsa), günde en fazla bir.

## v1 kapsamı
- Tek araç profili (marka/model/yıl, güncel km, hedef lastik basınçları).
- Hazır şablon (34 madde, `03-kontrol-listesi.md`): zaman, km, ikisi birden veya mevsimsel takvim; aralıklar düzenlenebilir, madde aç/kapat, "son yapılış" düzeltme.
- "Yaptım" ile kayıt; ölçüm (seviye, 4 lastik bar, mm) ve not isteğe bağlı.
- Km girişi (yakıt alırken).
- Bluetooth kopma tetikli bildirim + kurallar; bildirimden "Aç" ve "Yarın".
- Sürüşsüz dönem için günlük yedek bildirim.
- Ana ekran (gecikmiş / yaklaşan / zamanında / bilinmiyor), madde detayı, geçmiş, ayarlar, kurulum sihirbazı.
- Yerel SQLite, sıfır ağ trafiği.

## v1 değil (sonraki uygulama/sürüm)
OBD-II okuma, GPS ile km tahmini, birden fazla araç, bulut/hesap/yedekleme, yakıt-harcama takibi, servis randevusu, iOS, Android Auto ekranı, Play Store yayını, çoklu dil.

## Ne değildir
Arıza teşhis aracı değil, servis defteri değil, harcama uygulaması değil. Sınır: "ne zaman neye bakacağım" sorusunu kapatır, başka soru açmaz.

## Neden hazır uygulama değil
Hazırlar (Drivvo, Simply Auto vb.) saat bazlı bildirim + boş şablon; içeriği ve zamanlamayı kullanıcı yönetir. Buradaki iki fark: **içerik hazır**, **tetikleyici bağlamsal**. Bu ikisi olmadan "unutma" sorunu çözülmüyor.

## Neden Android Auto ve OBD değil
- Android Auto sürüş anı içindir; bakım kontrolü park halinde, telefon elinde yapılır. Google yalnız belirli kategorileri (medya, mesajlaşma, navigasyon, POI, IoT, hava durumu) kabul eder; Flutter'ın AA desteği yok. Kazanç sıfır, maliyet yüksek.
- Bu kontrollerin manuel olmasının sebebi arabanın bu verileri bilmemesi: Egea'da yağ seviyesi sensörü yok, soğutma suyu seviyesi okunmuyor, TPMS dolaylı (basınç değeri yok). OBD'den alınabilecekler (motor sıcaklığı, akü voltajı, arıza kodu) v1'in derdini çözmüyor.
- Android Auto kablolu bile olsa aramalar için arabanın Bluetooth'una bağlanır; dolayısıyla tek sinyal (Bluetooth kopması) hem AA'lı hem AA'sız sürüşü yakalar.
