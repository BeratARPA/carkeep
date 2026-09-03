/// Türkçe biçimlendirme. `intl` kullanılmaz (K-09).
/// Metin parçaları `strings_tr.dart` içindedir; bu dosya yalnız birleştirir.
library;

import 'strings_tr.dart';

// ---------------------------------------------------------------------------
// Sayılar
// ---------------------------------------------------------------------------

/// `118420` → `118.420`. Binlik ayırıcı nokta. Negatif değer işaretini korur.
String formatKm(int km) {
  final bool negative = km < 0;
  final String digits = km.abs().toString();
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      out.write('.');
    }
    out.write(digits[i]);
  }
  return negative ? '-$out' : out.toString();
}

/// `2.3` → `2,3`. Basınç tek ondalıkla gösterilir.
String formatBar(double bar) => bar.toStringAsFixed(1).replaceAll('.', ',');

/// Dört lastik basıncı → `2,3 / 2,3 / 2,3 / 2,2 bar`.
String formatTires(List<double> bars) =>
    '${bars.map(formatBar).join(' / ')} ${S.unitBar}';

/// Kullanıcı girişi: hem `2,3` hem `2.3` kabul edilir (T08).
double? parseBar(String raw) {
  final String s = raw.trim().replaceAll(',', '.');
  if (s.isEmpty) {
    return null;
  }
  return double.tryParse(s);
}

/// Kullanıcı girişi: `118.420`, `118420`, `118 420` kabul edilir.
int? parseKm(String raw) {
  final String s = raw.replaceAll(RegExp(r'[.\s ]'), '').trim();
  if (s.isEmpty) {
    return null;
  }
  return int.tryParse(s);
}

// ---------------------------------------------------------------------------
// Tarihler
// ---------------------------------------------------------------------------

/// `16 Eyl`; [refYear] farklıysa `16 Eyl 2027`.
String formatDate(DateTime date, {required int refYear}) => date.year == refYear
    ? '${date.day} ${trMonthsShort[date.month]}'
    : '${date.day} ${trMonthsShort[date.month]} ${date.year}';

/// Her zaman yıllı: `3 Eyl 2026` (geçmiş ekranı gün başlıkları).
String formatDateWithYear(DateTime date) =>
    '${date.day} ${trMonthsShort[date.month]} ${date.year}';

/// Yılsız gün/ay: `1 Kas` (mevsimsel aralık metni).
String formatMonthDay(int month, int day) => '$day ${trMonthsShort[month]}';

/// `14:30` (Ayarlar tanı satırı).
String formatTime(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

// ---------------------------------------------------------------------------
// Durum metinleri (01-spec §2.4)
// ---------------------------------------------------------------------------

/// `8 gün gecikti`
String overdueDaysText(int daysOverdue) =>
    '$daysOverdue ${S.overdueDaysSuffix}';

/// `420 km geçti`
String overdueKmText(int kmOverdue) =>
    '${formatKm(kmOverdue)} ${S.overdueKmSuffix}';

/// `Bugün` (0) veya `2 gün kaldı`.
String soonDaysText(int daysLeft) =>
    daysLeft == 0 ? S.today : '$daysLeft ${S.soonDaysSuffix}';

/// `850 km kaldı`
String kmLeftText(int kmLeft) => '${formatKm(kmLeft)} ${S.kmLeftSuffix}';

/// Kısa metin + aralık: `8 gün gecikti. 14 günde bir.`
String longStatusText(String shortText, String intervalText) =>
    '$shortText. $intervalText.';

// ---------------------------------------------------------------------------
// Aralık metinleri (01-spec §2.4)
// ---------------------------------------------------------------------------

/// Küçük harfle: `14 günde bir`, `ayda bir`, `3 ayda bir`, `yılda bir`,
/// `2 yılda bir`.
String intervalDaysTextLower(int days) {
  if (days == 365) {
    return S.everyYear;
  }
  if (days == 30) {
    return S.everyMonth;
  }
  if (days % 365 == 0) {
    return '${days ~/ 365} ${S.everyNYearsSuffix}';
  }
  if (days % 30 == 0) {
    return '${days ~/ 30} ${S.everyNMonthsSuffix}';
  }
  return '$days ${S.everyNDaysSuffix}';
}

/// Küçük harfle: `15.000 km'de bir`.
String intervalKmTextLower(int km) => '${formatKm(km)} ${S.everyKmSuffix}';

/// Tam aralık metni. `both` maddede km parçası önce gelir (01-spec §2.4):
/// `15.000 km'de bir veya yılda bir`. Mevsimselde `Her yıl 1 Kas ve 1 Nis`.
String intervalText({
  int? intervalDays,
  int? intervalKm,
  List<({int month, int day})>? seasonalDates,
}) {
  if (seasonalDates != null && seasonalDates.isNotEmpty) {
    final String dates = seasonalDates
        .map((({int month, int day}) d) => formatMonthDay(d.month, d.day))
        .join(' ${S.seasonalJoiner} ');
    return '${S.seasonalPrefix} $dates';
  }
  final List<String> parts = <String>[
    if (intervalKm != null) intervalKmTextLower(intervalKm),
    if (intervalDays != null) intervalDaysTextLower(intervalDays),
  ];
  if (parts.isEmpty) {
    return '';
  }
  return capitalizeTr(parts.join(' ${S.intervalJoiner} '));
}

// ---------------------------------------------------------------------------
// Yardımcı
// ---------------------------------------------------------------------------

/// Türkçe kurallı ilk harf büyütme (`i` → `İ`).
String capitalizeTr(String s) {
  if (s.isEmpty) {
    return s;
  }
  final String first = s[0];
  final String upper = first == 'i' ? 'İ' : first.toUpperCase();
  return '$upper${s.substring(1)}';
}
