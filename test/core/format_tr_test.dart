import 'package:carkeep/core/constants.dart';
import 'package:carkeep/core/format_tr.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatKm', () {
    test('binlik ayırıcı nokta', () {
      expect(formatKm(118420), '118.420');
    });

    test('sınır değerler', () {
      expect(formatKm(0), '0');
      expect(formatKm(7), '7');
      expect(formatKm(999), '999');
      expect(formatKm(1000), '1.000');
      expect(formatKm(15000), '15.000');
      expect(formatKm(1480), '1.480');
      expect(formatKm(480), '480');
      expect(formatKm(1234567), '1.234.567');
    });

    test('negatif işaret korunur', () {
      expect(formatKm(-420), '-420');
      expect(formatKm(-1480), '-1.480');
    });
  });

  group('formatBar', () {
    test('ondalık virgülle', () {
      expect(formatBar(2.3), '2,3');
      expect(formatBar(2.0), '2,0');
      expect(formatBar(2.25), '2,3');
    });

    test('dört lastik biçimi', () {
      expect(
        formatTires(<double>[2.3, 2.3, 2.3, 2.2]),
        '2,3 / 2,3 / 2,3 / 2,2 bar',
      );
    });
  });

  group('parseBar', () {
    test('hem nokta hem virgül kabul', () {
      expect(parseBar('2.3'), 2.3);
      expect(parseBar('2,3'), 2.3);
      expect(parseBar(' 2,3 '), 2.3);
    });

    test('geçersiz giriş null', () {
      expect(parseBar(''), isNull);
      expect(parseBar('abc'), isNull);
    });
  });

  group('parseKm', () {
    test('binlik noktası ve boşluk temizlenir', () {
      expect(parseKm('118420'), 118420);
      expect(parseKm('118.420'), 118420);
      expect(parseKm('118 420'), 118420);
    });

    test('geçersiz giriş null', () {
      expect(parseKm(''), isNull);
      expect(parseKm('abc'), isNull);
    });
  });

  group('formatDate', () {
    test('aynı yıl → yılsız', () {
      expect(formatDate(DateTime(2026, 9, 16), refYear: 2026), '16 Eyl');
      expect(formatDate(DateTime(2026, 8, 12), refYear: 2026), '12 Ağu');
      expect(formatDate(DateTime(2026, 11, 1), refYear: 2026), '1 Kas');
    });

    test('farklı yıl → yıllı', () {
      expect(formatDate(DateTime(2027, 9, 16), refYear: 2026), '16 Eyl 2027');
      expect(formatDate(DateTime(2027, 4, 1), refYear: 2026), '1 Nis 2027');
      expect(formatDate(DateTime(2025, 9, 16), refYear: 2026), '16 Eyl 2025');
    });

    test('her zaman yıllı biçim', () {
      expect(formatDateWithYear(DateTime(2026, 9, 3)), '3 Eyl 2026');
    });

    test('tüm ay kısaltmaları', () {
      const List<String> expected = <String>[
        '1 Oca',
        '1 Şub',
        '1 Mar',
        '1 Nis',
        '1 May',
        '1 Haz',
        '1 Tem',
        '1 Ağu',
        '1 Eyl',
        '1 Eki',
        '1 Kas',
        '1 Ara',
      ];
      for (int m = 1; m <= 12; m++) {
        expect(formatDate(DateTime(2026, m, 1), refYear: 2026), expected[m - 1]);
      }
    });
  });

  group('formatTime', () {
    test('sıfır dolgulu', () {
      expect(formatTime(DateTime(2026, 9, 3, 14, 30)), '14:30');
      expect(formatTime(DateTime(2026, 9, 3, 9, 5)), '09:05');
    });
  });

  group('durum metinleri', () {
    test('overdue', () {
      expect(overdueDaysText(8), '8 gün gecikti');
      expect(overdueDaysText(306), '306 gün gecikti');
      expect(overdueKmText(420), '420 km geçti');
      expect(overdueKmText(1480), '1.480 km geçti');
    });

    test('soon', () {
      expect(soonDaysText(0), 'Bugün');
      expect(soonDaysText(1), '1 gün kaldı');
      expect(soonDaysText(12), '12 gün kaldı');
      expect(kmLeftText(850), '850 km kaldı');
      expect(kmLeftText(1000), '1.000 km kaldı');
      expect(kmLeftText(1480), '1.480 km kaldı');
    });

    test('uzun biçim', () {
      expect(
        longStatusText('8 gün gecikti', '14 günde bir'),
        '8 gün gecikti. 14 günde bir.',
      );
    });
  });

  group('intervalText', () {
    test('gün aralıkları', () {
      expect(intervalText(intervalDays: 14), '14 günde bir');
      expect(intervalText(intervalDays: 7), '7 günde bir');
      expect(intervalText(intervalDays: 30), 'Ayda bir');
      expect(intervalText(intervalDays: 60), '2 ayda bir');
      expect(intervalText(intervalDays: 90), '3 ayda bir');
      expect(intervalText(intervalDays: 180), '6 ayda bir');
      expect(intervalText(intervalDays: 365), 'Yılda bir');
      expect(intervalText(intervalDays: 730), '2 yılda bir');
      expect(intervalText(intervalDays: 1460), '4 yılda bir');
      expect(intervalText(intervalDays: 1825), '5 yılda bir');
    });

    test('km aralıkları', () {
      expect(intervalText(intervalKm: 15000), "15.000 km'de bir");
      expect(intervalText(intervalKm: 10000), "10.000 km'de bir");
      expect(intervalText(intervalKm: 120000), "120.000 km'de bir");
    });

    test('both: km önce, sonra gün', () {
      expect(
        intervalText(intervalKm: 15000, intervalDays: 365),
        "15.000 km'de bir veya yılda bir",
      );
      expect(
        intervalText(intervalKm: 120000, intervalDays: 1825),
        "120.000 km'de bir veya 5 yılda bir",
      );
    });

    test('mevsimsel', () {
      expect(
        intervalText(
          seasonalDates: <({int month, int day})>[
            (month: 11, day: 1),
            (month: 4, day: 1),
          ],
        ),
        'Her yıl 1 Kas ve 1 Nis',
      );
    });

    test('boş girdi boş metin', () {
      expect(intervalText(), '');
    });
  });

  group('lastTripText (01-spec §3.7)', () {
    test('sayılan sürüş, bildirim gönderildi', () {
      expect(
        lastTripText(
          disconnectedAt: DateTime(2026, 9, 3, 14, 30),
          durationMin: 25,
          counted: true,
          notified: true,
          refYear: 2026,
        ),
        'Son kopma: 3 Eyl 14:30, 25 dk sürüş, bildirim gönderildi',
      );
    });

    test('sayılan sürüş, bildirim yok', () {
      expect(
        lastTripText(
          disconnectedAt: DateTime(2026, 9, 3, 14, 30),
          durationMin: 25,
          counted: true,
          notified: false,
          refYear: 2026,
        ),
        'Son kopma: 3 Eyl 14:30, 25 dk sürüş, bildirim yok',
      );
    });

    test('kısa bağlantı sürüş sayılmadı', () {
      expect(
        lastTripText(
          disconnectedAt: DateTime(2026, 9, 3, 14, 30),
          durationMin: 2,
          counted: false,
          notified: false,
          refYear: 2026,
        ),
        'Son kopma: 3 Eyl 14:30, 2 dk, sürüş sayılmadı',
      );
    });

    test('geçmiş yılda yıl da yazılır', () {
      expect(
        lastTripText(
          disconnectedAt: DateTime(2025, 12, 31, 9, 5),
          durationMin: 12,
          counted: true,
          notified: true,
          refYear: 2026,
        ),
        'Son kopma: 31 Ara 2025 09:05, 12 dk sürüş, bildirim gönderildi',
      );
    });

    test('kopma yoksa', () {
      expect(
        lastTripText(
          disconnectedAt: null,
          durationMin: 0,
          counted: false,
          notified: false,
          refYear: 2026,
        ),
        'Henüz kopma görülmedi',
      );
    });
  });

  group('lastTripReason (K-24)', () {
    String r(String? note, {bool counted = true, bool notified = false}) =>
        lastTripReason(note: note, counted: counted, notified: notified);

    test('motorun ürettiği yedi not karşılığını buluyor', () {
      expect(r(kTripNoteOk), 'bildirim gönderildi');
      expect(r(kTripNoteShortTrip, counted: false), 'sürüş sayılmadı');
      expect(r(kTripNoteOncePerDay), 'bugün zaten hatırlatıldı');
      expect(r(kTripNoteNoOverdue), 'gecikmiş yoktu');
      expect(r(kTripNoteSnoozed), 'ertelenmişti');
      expect(r(kTripNoteReconnect, counted: false), 'geri bağlandı, sürüş sürüyor');
      expect(r(kTripNoteNoSnapshot), 'veri hazır değildi');
      expect(r(kTripNoteNoPermission), 'bildirim izni yok');
    });

    test('not yoksa bayraklara düşüyor', () {
      expect(r(null, counted: false), 'sürüş sayılmadı');
      expect(r(null, notified: true), 'bildirim gönderildi');
      expect(r(null), 'bildirim yok');
      expect(r('bilinmeyen_not'), 'bildirim yok');
    });

    test('06 §3 adım 4 metni', () {
      expect(
        lastTripText(
          disconnectedAt: DateTime(2026, 9, 3, 18, 5),
          durationMin: 8,
          counted: true,
          notified: false,
          refYear: 2026,
          note: kTripNoteOncePerDay,
        ),
        'Son kopma: 3 Eyl 18:05, 8 dk sürüş, bugün zaten hatırlatıldı',
      );
    });

    test('06 §3 adım 6 metni (reconnect)', () {
      expect(
        lastTripText(
          disconnectedAt: DateTime(2026, 9, 3, 18, 5),
          durationMin: 8,
          counted: false,
          notified: false,
          refYear: 2026,
          note: kTripNoteReconnect,
        ),
        'Son kopma: 3 Eyl 18:05, 8 dk, geri bağlandı, sürüş sürüyor',
      );
    });
  });

  group('minutesText / fallbackDaysText', () {
    test('dakika', () {
      expect(minutesText(5), '5 dk');
      expect(minutesText(0), '0 dk');
    });

    test('yedek bildirim', () {
      expect(fallbackDaysText(0), 'Kapalı');
      expect(fallbackDaysText(7), '7 gün sonra');
    });
  });

  group('capitalizeTr', () {
    test('Türkçe i büyük harfi İ', () {
      expect(capitalizeTr('iki'), 'İki');
      expect(capitalizeTr('yılda bir'), 'Yılda bir');
      expect(capitalizeTr('ayda bir'), 'Ayda bir');
      expect(capitalizeTr("15.000 km'de bir"), "15.000 km'de bir");
      expect(capitalizeTr(''), '');
    });
  });
}
