import 'package:carkeep/core/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dayKey', () {
    test('gece yarısına yakın saat günü kaydırmaz', () {
      expect(dayKey(DateTime(2026, 9, 3, 23, 59)), '2026-09-03');
      expect(dayKey(DateTime(2026, 9, 3, 0, 0)), '2026-09-03');
      expect(dayKey(DateTime(2026, 9, 3, 12, 30, 45)), '2026-09-03');
    });

    test('tek haneli ay ve gün sıfır dolgulu', () {
      expect(dayKey(DateTime(2026, 1, 5)), '2026-01-05');
      expect(dayKey(DateTime(2026, 12, 31)), '2026-12-31');
    });

    test('leksikografik sıralama kronolojik', () {
      final List<String> keys = <String>[
        dayKey(DateTime(2026, 11, 1)),
        dayKey(DateTime(2026, 2, 3)),
        dayKey(DateTime(2025, 12, 31)),
        dayKey(DateTime(2027, 4, 1)),
      ]..sort();
      expect(keys, <String>[
        '2025-12-31',
        '2026-02-03',
        '2026-11-01',
        '2027-04-01',
      ]);
    });
  });

  group('parseDay', () {
    test('gidiş dönüş', () {
      expect(parseDay('2026-09-03'), DateTime(2026, 9, 3));
      expect(dayKey(parseDay('2027-04-01')), '2027-04-01');
    });

    test('bozuk biçim hata fırlatır', () {
      expect(() => parseDay('2026-9-3'), throwsFormatException);
      expect(() => parseDay('03.09.2026'), throwsFormatException);
      expect(() => parseDay(''), throwsFormatException);
      expect(() => parseDay('2026-13-01'), throwsFormatException);
      expect(() => parseDay('2026-02-30'), throwsFormatException);
    });

    test('tryParseDay bozukta null', () {
      expect(tryParseDay(null), isNull);
      expect(tryParseDay(''), isNull);
      expect(tryParseDay('bozuk'), isNull);
      expect(tryParseDay('2026-09-03'), DateTime(2026, 9, 3));
    });
  });

  group('daysBetween', () {
    test('saat farkı etkilemiyor', () {
      expect(
        daysBetween(DateTime(2026, 9, 3, 23, 59), DateTime(2026, 9, 4, 0, 1)),
        1,
      );
      expect(
        daysBetween(DateTime(2026, 9, 3, 0, 1), DateTime(2026, 9, 3, 23, 59)),
        0,
      );
    });

    test('takvim günü sayıyor', () {
      expect(daysBetween(DateTime(2026, 8, 12), DateTime(2026, 9, 3)), 22);
      expect(daysBetween(DateTime(2026, 9, 3), DateTime(2026, 8, 12)), -22);
      expect(daysBetween(DateTime(2026, 9, 3), DateTime(2026, 9, 3)), 0);
    });

    test('ay ve yıl sınırını geçiyor', () {
      expect(daysBetween(DateTime(2025, 12, 31), DateTime(2026, 1, 1)), 1);
      expect(daysBetween(DateTime(2025, 11, 1), DateTime(2026, 9, 3)), 306);
      expect(daysBetween(DateTime(2026, 9, 3), DateTime(2027, 4, 1)), 210);
      expect(daysBetween(DateTime(2026, 9, 3), DateTime(2026, 11, 1)), 59);
    });

    test('artık yıl', () {
      expect(daysBetween(DateTime(2028, 2, 28), DateTime(2028, 3, 1)), 2);
      expect(daysBetween(DateTime(2026, 2, 28), DateTime(2026, 3, 1)), 1);
    });

    test('yaz saati geçişi gün sayısını bozmuyor', () {
      // 2026 Mart sonu / Ekim sonu civarı: 30 gün 30 gün kalmalı.
      expect(daysBetween(DateTime(2026, 3, 15), DateTime(2026, 4, 14)), 30);
      expect(daysBetween(DateTime(2026, 10, 15), DateTime(2026, 11, 14)), 30);
    });
  });

  group('addDays', () {
    test('gün ekleme', () {
      expect(addDays(DateTime(2026, 8, 20), 14), DateTime(2026, 9, 3));
      expect(addDays(DateTime(2026, 9, 3), 1), DateTime(2026, 9, 4));
      expect(addDays(DateTime(2026, 12, 31), 1), DateTime(2027, 1, 1));
      expect(addDays(DateTime(2026, 3, 12), 365), DateTime(2027, 3, 12));
    });

    test('negatif gün', () {
      expect(addDays(DateTime(2026, 8, 20), -1), DateTime(2026, 8, 19));
    });

    test('saat bilgisini atar', () {
      expect(addDays(DateTime(2026, 9, 3, 23, 59), 0), DateTime(2026, 9, 3));
    });

    test('addDays ve daysBetween tutarlı', () {
      final DateTime base = DateTime(2026, 9, 3);
      for (final int n in <int>[0, 1, 3, 14, 30, 59, 210, 306, 365, 730, 1825]) {
        expect(daysBetween(base, addDays(base, n)), n, reason: 'n=$n');
      }
    });
  });

  group('dateOnly / isSameDay', () {
    test('dateOnly saati sıfırlar', () {
      expect(dateOnly(DateTime(2026, 9, 3, 14, 5, 12)), DateTime(2026, 9, 3));
    });

    test('isSameDay', () {
      expect(
        isSameDay(DateTime(2026, 9, 3, 1), DateTime(2026, 9, 3, 23)),
        isTrue,
      );
      expect(isSameDay(DateTime(2026, 9, 3), DateTime(2026, 9, 4)), isFalse);
    });
  });
}
