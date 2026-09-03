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
}
