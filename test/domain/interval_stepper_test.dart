import 'package:carkeep/core/constants.dart';
import 'package:carkeep/domain/interval_stepper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('stepInterval — gün presetleri', () {
    test('preset üzerinde bir adım ileri', () {
      expect(stepInterval(14, kIntervalDaysPresets, 1), 30);
      expect(stepInterval(365, kIntervalDaysPresets, 1), 730);
    });

    test('preset üzerinde bir adım geri', () {
      expect(stepInterval(30, kIntervalDaysPresets, -1), 14);
      expect(stepInterval(7, kIntervalDaysPresets, -1), 7);
    });

    test('K-19: 1460 preset listesinde', () {
      expect(kIntervalDaysPresets.contains(1460), isTrue);
      expect(stepInterval(1460, kIntervalDaysPresets, 1), 1825);
      expect(stepInterval(1460, kIntervalDaysPresets, -1), 730);
    });

    test('üst uçta artırma değeri değiştirmiyor', () {
      expect(stepInterval(1825, kIntervalDaysPresets, 1), 1825);
    });

    test('K-19: preset dışı değer en yakın durağa atlıyor', () {
      // 100 gün presetlerde yok; ileri 180, geri 90.
      expect(stepInterval(100, kIntervalDaysPresets, 1), 180);
      expect(stepInterval(100, kIntervalDaysPresets, -1), 90);
    });

    test('preset dışı değer listenin dışındaysa yön korunur', () {
      // 3 gün en küçük presetin altında: + ile 7'ye çıkar, − ile değişmez
      // (aksi hâlde "kısalt" düğmesi aralığı uzatırdı).
      expect(stepInterval(3, kIntervalDaysPresets, 1), 7);
      expect(stepInterval(3, kIntervalDaysPresets, -1), 3);
      // 4000 en büyük presetin üstünde: − ile 1825'e iner, + ile değişmez.
      expect(stepInterval(4000, kIntervalDaysPresets, -1), 1825);
      expect(stepInterval(4000, kIntervalDaysPresets, 1), 4000);
    });
  });

  group('stepInterval — km presetleri', () {
    test('ileri ve geri', () {
      expect(stepInterval(15000, kIntervalKmPresets, 1), 20000);
      expect(stepInterval(15000, kIntervalKmPresets, -1), 10000);
    });

    test('uçlarda duruyor', () {
      expect(stepInterval(5000, kIntervalKmPresets, -1), 5000);
      expect(stepInterval(120000, kIntervalKmPresets, 1), 120000);
    });
  });

  group('kenar durumlar', () {
    test('boş preset listesi değeri değiştirmiyor', () {
      expect(stepInterval(30, const <int>[], 1), 30);
    });

    test('yön 0 değeri değiştirmiyor', () {
      expect(stepInterval(30, kIntervalDaysPresets, 0), 30);
    });
  });

  group('canStepInterval', () {
    test('adım varsa true', () {
      expect(canStepInterval(14, kIntervalDaysPresets, 1), isTrue);
      expect(canStepInterval(14, kIntervalDaysPresets, -1), isTrue);
    });

    test('uçta false', () {
      expect(canStepInterval(1825, kIntervalDaysPresets, 1), isFalse);
      expect(canStepInterval(7, kIntervalDaysPresets, -1), isFalse);
    });
  });
}
