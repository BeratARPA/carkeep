/// Tarih yardımcıları. K-10: yalnız yerel takvim günü, saat yok, UTC dönüşümü yok.
/// Gün anahtarı `yyyy-MM-dd` (Kotlin `DayKey` ile aynı biçim).
library;

/// Saat/dakika/saniyeyi atar, yerel gün başlangıcını döndürür.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// `2026-09-03`. Leksikografik sıralama kronolojik sıralamaya eşittir.
String dayKey(DateTime d) {
  final String y = d.year.toString().padLeft(4, '0');
  final String m = d.month.toString().padLeft(2, '0');
  final String day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

/// `yyyy-MM-dd` → yerel gün. Biçim bozuksa [FormatException].
DateTime parseDay(String key) {
  if (key.length != 10 || key[4] != '-' || key[7] != '-') {
    throw FormatException('Gün anahtarı yyyy-MM-dd olmalı', key);
  }
  final int? y = int.tryParse(key.substring(0, 4));
  final int? m = int.tryParse(key.substring(5, 7));
  final int? d = int.tryParse(key.substring(8, 10));
  if (y == null || m == null || d == null) {
    throw FormatException('Gün anahtarı sayısal değil', key);
  }
  if (m < 1 || m > 12 || d < 1 || d > 31) {
    throw FormatException('Gün anahtarı geçersiz tarih', key);
  }
  final DateTime parsed = DateTime(y, m, d);
  if (parsed.month != m || parsed.day != d) {
    throw FormatException('Gün anahtarı geçersiz tarih', key);
  }
  return parsed;
}

/// `yyyy-MM-dd` → gün; bozuksa null.
DateTime? tryParseDay(String? key) {
  if (key == null || key.isEmpty) {
    return null;
  }
  try {
    return parseDay(key);
  } on FormatException {
    return null;
  }
}

/// `b - a`, takvim günü farkı. Saat farkı ve yaz saati uygulaması etkilemez.
int daysBetween(DateTime a, DateTime b) {
  final DateTime from = dateOnly(a);
  final DateTime to = dateOnly(b);
  return (to.difference(from).inHours / 24).round();
}

/// Takvim günü ekler (yaz saati geçişinde de gün sayısı korunur).
DateTime addDays(DateTime d, int days) {
  final DateTime base = dateOnly(d);
  return DateTime(base.year, base.month, base.day + days);
}

/// [a] ile [b] aynı takvim günü mü.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
