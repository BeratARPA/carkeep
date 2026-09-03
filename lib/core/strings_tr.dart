/// Tüm kullanıcıya görünen metinler burada (CLAUDE.md dil kuralları, K-09).
/// Widget içine string gömülmez. `format_tr.dart` buradaki parçaları birleştirir.
library;

/// Ay kısaltmaları, 1 = Ocak. Dizin 0 kullanılmaz.
const List<String> trMonthsShort = <String>[
  '',
  'Oca',
  'Şub',
  'Mar',
  'Nis',
  'May',
  'Haz',
  'Tem',
  'Ağu',
  'Eyl',
  'Eki',
  'Kas',
  'Ara',
];

/// Metin sabitleri. Yeni ticket yeni alan ekler; var olanı yeniden adlandırmaz.
abstract final class S {
  // ---------------------------------------------------------------- uygulama
  static const String appName = 'CarKeep';

  // ------------------------------------------------------- durum metinleri
  /// `8 gün gecikti`
  static const String overdueDaysSuffix = 'gün gecikti';

  /// `420 km geçti`
  static const String overdueKmSuffix = 'km geçti';

  /// `2 gün kaldı`
  static const String soonDaysSuffix = 'gün kaldı';

  /// `850 km kaldı`
  static const String kmLeftSuffix = 'km kaldı';

  /// Bugün vadesi dolan gün bazlı madde.
  static const String today = 'Bugün';

  /// Ertelenmiş gecikmiş madde.
  static const String tomorrow = 'Yarın';

  /// Son yapılışı bilinmeyen madde.
  static const String enterDate = 'Tarih gir';

  /// K-18: son yapılışı olmayan maddenin liste alt satırı.
  static const String lastDoneMissing = 'Son yapılış girilmedi';

  /// `Son: 12 Ağu, Orta` öneki.
  static const String lastDonePrefix = 'Son:';

  // ----------------------------------------------------- aralık metinleri
  /// `14 günde bir`
  static const String everyNDaysSuffix = 'günde bir';

  /// `Ayda bir`
  static const String everyMonth = 'ayda bir';

  /// `3 ayda bir`
  static const String everyNMonthsSuffix = 'ayda bir';

  /// `Yılda bir`
  static const String everyYear = 'yılda bir';

  /// `2 yılda bir`
  static const String everyNYearsSuffix = 'yılda bir';

  /// `15.000 km'de bir`
  static const String everyKmSuffix = "km'de bir";

  /// `15.000 km'de bir veya yılda bir`
  static const String intervalJoiner = 'veya';

  /// `Her yıl 1 Kas ve 1 Nis`
  static const String seasonalPrefix = 'Her yıl';

  /// Mevsimsel tarihleri birleştirir.
  static const String seasonalJoiner = 've';

  // ------------------------------------------------------------- birimler
  static const String unitKm = 'km';
  static const String unitBar = 'bar';

  // ------------------------------------------------------- ortak eylemler
  static const String next = 'İleri';
  static const String back = 'Geri';
  static const String start = 'Başla';
  static const String save = 'Kaydet';
  static const String cancel = 'İptal';
  static const String refresh = 'Yenile';
  static const String allow = 'İzin ver';
  static const String open = 'Aç';
  static const String granted = 'Verildi';
  static const String notGranted = 'Verilmedi';
  static const String optional = 'İsteğe bağlı';
  static const String skipForNow = 'Sonra seçerim';

  // ------------------------------------------ kurulum (01-spec §3.1)
  /// 1. adım
  static const String setupVehicleTitle = 'Aracın';
  static const String setupVehicleHelp = 'Bir kere gir, bir daha sorulmaz.';
  static const String fieldBrand = 'Marka';
  static const String fieldModel = 'Model';
  static const String fieldYear = 'Yıl';
  static const String errBrandRequired = 'Marka gir';

  /// 2. adım
  static const String setupKmTitle = "Kaç km'de?";
  static const String setupKmHelp =
      "Gösterge km'si. Km'ye bağlı bakımlar bundan sayılır; sonra yakıt "
      'alırken güncellersin.';
  static const String fieldKm = 'Km';
  static const String errKmRequired = 'Km gir';

  /// 3. adım
  static const String setupPermissionsTitle = 'İzinler';
  static const String permBluetooth = 'Bluetooth';
  static const String permBluetoothWhy =
      "Arabanın Bluetooth'unu görmem ve kopmayı yakalamam için.";
  static const String permNotification = 'Bildirim';
  static const String permNotificationWhy =
      'Gecikmiş kontrolü söyleyebilmem için.';
  static const String permBattery = 'Pil optimizasyonu';
  static const String permBatteryWhy =
      'Telefon uygulamayı uyutursa kopmayı kaçırabilirim.';
  static const String permBatteryOff = 'Kapatıldı';
  static const String permBatteryOn = 'Açık';
  static const String permDeniedPermanently = 'İzin kapalı. Ayarlardan aç.';
  static const String openSettings = 'Ayarları aç';

  /// 4. adım
  static const String setupDeviceTitle = "Arabanın Bluetooth'u hangisi?";
  static const String setupDeviceHelp =
      'Telefon bu cihazdan koptuğunda arabadan indiğini anlar ve o anda '
      'hatırlatır. Android Auto kullanıyorsan da aynı cihaz.';
  static const String deviceListEmpty =
      'Eşleşmiş cihaz yok. Telefonu önce arabayla eşleştir.';

  /// T05 cihaz testinde bulundu: adaptör kapalıyken liste boş gelir, ama
  /// bu "eşleşmiş cihaz yok" demek değildir.
  static const String deviceListBluetoothOff =
      'Bluetooth kapalı. Eşleşmiş cihazları görebilmem için aç.';
  static const String deviceListNoPermission =
      'Cihazları listeleyebilmem için Bluetooth izni gerek.';

  /// 5. adım
  static const String setupLastServiceTitle = 'Son servis';
  static const String setupLastServiceQuestion =
      'Son yağ değişimi ne zaman ve kaç km\'de yapıldı?';
  static const String setupLastServiceHelp =
      'İsteğe bağlı. Boş bırakırsan yağ ve polen filtresi "Bilinmiyor" '
      'olarak bekler, sonra girebilirsin.';
  static const String fieldServiceDate = 'Tarih';
  static const String fieldServiceKm = 'Km';
  static const String errServiceIncomplete =
      'Tarihi ve km\'yi birlikte gir ya da ikisini de boş bırak';

  /// 6. adım
  static const String setupChecklistTitle = 'Kontrol listesi';
  static const String setupChecklistHelp =
      "Aralıklar hazır. İstemediğini kapat; sonra Ayarlar'dan "
      'değiştirebilirsin.';

  /// "Başla" sonrası
  static const String setupDoneToast =
      'Hazır. Bir sonraki sürüşten sonra hatırlatırım.';

  // ------------------------------------------------- tarih alanı (K-21)
  static const String dateDay = 'Gün';
  static const String dateMonth = 'Ay';
  static const String dateYear = 'Yıl';
  static const String errDateInvalid = 'Geçerli bir tarih gir';
  static const String errDateFuture = 'İleri tarih olamaz';

  // ------------------------------------------ ana ekran (01-spec §3.2)
  static const String tabHome = 'Kontroller';
  static const String tabHistory = 'Geçmiş';
  static const String tabSettings = 'Ayarlar';

  static const String kmEntryLink = 'Km gir';

  /// `Uconnect bağlı değil`
  static const String chipDisconnectedSuffix = 'bağlı değil';

  /// `Uconnect bağlı, sürüşte`
  static const String chipConnectedSuffix = 'bağlı, sürüşte';

  /// Cihaz seçilmemişken chip.
  static const String chipNoDevice = 'Araba seçilmedi';

  static const String sectionOverdue = 'Gecikmiş';
  static const String sectionSoon = 'Yaklaşan';
  static const String sectionOk = 'Zamanında';
  static const String sectionUnknown = 'Bilinmiyor';

  static const String homeAllGood =
      'Her şey zamanında. Bir sonraki sürüşten sonra gecikmiş bir şey olursa '
      'haber veririm.';
  static const String homeNoItems =
      "Kontrol listesi boş. Ayarlar'dan madde aç.";

  // ------------------------------------------------- uyarı şeritleri §3.2
  static const String bannerNoBluetooth =
      'Bluetooth izni yok, kopmayı yakalayamam.';
  static const String bannerNoNotification = 'Bildirim izni yok.';
  static const String bannerNoDevice = 'Araba seçilmedi.';
  static const String bannerBattery =
      'Pil optimizasyonu açık, bildirim gecikebilir.';
  static const String bannerDismiss = 'Kapat';

  // ------------------------------------------ madde detayı (01-spec §3.3)
  static const String detailWhy = 'Neden';
  static const String detailHow = 'Nasıl bakılır';
  static const String detailPreviousLogs = 'Önceki kayıtlar';
  static const String detailNoteLabel = 'Not (isteğe bağlı)';
  static const String detailNoteHint = 'Örn. arka sağ hep düşük';
  static const String detailSaveDone = 'Yaptım olarak kaydet';
  static const String detailSnooze = 'Yarın hatırlat';
  static const String detailFixDate = 'Tarih/km düzelt';

  /// `unknown` maddede düzeltme öne çıkarılır (01-spec §3.4).
  static const String detailUnknownCallout =
      'Bu bilgi olmadan hesaplayamam.';

  /// Ölçüm blokları
  static const String measureLevel = 'Seviye';
  static const String measureTires = 'Ölçülen basınç';
  static const String tireFrontLeft = 'Ön sol';
  static const String tireFrontRight = 'Ön sağ';
  static const String tireRearLeft = 'Arka sol';
  static const String tireRearRight = 'Arka sağ';

  /// `Hedef: ön 2,3 / arka 2,3`
  static const String tireTargetPrefix = 'Hedef:';
  static const String tireTargetFront = 'ön';
  static const String tireTargetRear = 'arka';
  static const String tireTargetUnknown =
      'Hedef değer sürücü kapısındaki etikette yazar.';

  /// Doğrulama uyarıları
  static const String errPickLevel = 'Önce seviyeyi seç';
  static const String errAllFourTires = 'Dört lastiği de gir';

  /// `Kaydedildi. Sonraki: 16 Eyl`
  static const String savedPrefix = 'Kaydedildi.';
  static const String nextDuePrefix = 'Sonraki:';
  static const String snoozedToast = 'Yarın tekrar hatırlatırım';

  // ------------------------------------- tarih/km düzelt (01-spec §3.4)
  static const String fixDialogTitle = 'Bu madde en son ne zaman yapıldı?';
  static const String errFixDateRequired = 'Tarih gir';
  static const String errFixKmRequired = 'Km gir';

  // ------------------------------------------------------------- hatalar
  static const String errSeedLoad = 'Şablon dosyası okunamadı.';
  static const String errDbOpen = 'Veriler açılamadı.';
  static const String errGeneric = 'Bir şey ters gitti.';
}
