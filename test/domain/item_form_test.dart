import 'package:carkeep/domain/item_form.dart';
import 'package:carkeep/domain/models/measure.dart';
import 'package:carkeep/domain/models/schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ItemFormData form({
    String name = 'Silecek suyu',
    ScheduleKind kind = ScheduleKind.days,
    int? days = 30,
    int? km,
    List<SeasonalDate> dates = const <SeasonalDate>[],
    MeasureType measureType = MeasureType.none,
    List<String> levels = const <String>[],
    String? unit,
    String? label,
  }) => ItemFormData(
    name: name,
    kind: kind,
    intervalDays: days,
    intervalKm: km,
    dates: dates,
    measureType: measureType,
    levels: levels,
    unit: unit,
    label: label,
  );

  group('validateItemForm', () {
    test('geçerli gün maddesi hatasız', () {
      expect(validateItemForm(form()), isEmpty);
    });

    test('ad boşsa hata', () {
      expect(
        validateItemForm(form(name: '   ')).keys,
        contains(ItemFormField.name),
      );
    });

    test('gün maddesinde gün zorunlu', () {
      expect(
        validateItemForm(form(days: null)).keys,
        contains(ItemFormField.intervalDays),
      );
    });

    test('gün sınırların dışındaysa hata', () {
      expect(
        validateItemForm(form(days: 0)).keys,
        contains(ItemFormField.intervalDays),
      );
      expect(
        validateItemForm(form(days: kMaxIntervalDays + 1)).keys,
        contains(ItemFormField.intervalDays),
      );
    });

    test('km maddesinde km zorunlu, gün istenmez', () {
      final Map<ItemFormField, String> e = validateItemForm(
        form(kind: ScheduleKind.km, days: null),
      );
      expect(e.keys, contains(ItemFormField.intervalKm));

      expect(
        validateItemForm(form(kind: ScheduleKind.km, days: null, km: 15000)),
        isEmpty,
      );
    });

    test('km sınırların dışındaysa hata', () {
      expect(
        validateItemForm(form(kind: ScheduleKind.km, days: null, km: 10)).keys,
        contains(ItemFormField.intervalKm),
      );
      expect(
        validateItemForm(
          form(kind: ScheduleKind.km, days: null, km: kMaxIntervalKm + 1),
        ).keys,
        contains(ItemFormField.intervalKm),
      );
    });

    test('both maddede ikisi de zorunlu', () {
      expect(
        validateItemForm(form(kind: ScheduleKind.both)).keys,
        contains(ItemFormField.intervalKm),
      );
      expect(
        validateItemForm(
          form(kind: ScheduleKind.both, days: 365, km: 15000),
        ),
        isEmpty,
      );
    });

    test('mevsimselde en az bir tarih', () {
      expect(
        validateItemForm(
          form(kind: ScheduleKind.seasonal, days: null),
        ).keys,
        contains(ItemFormField.seasonalDates),
      );
      expect(
        validateItemForm(
          form(
            kind: ScheduleKind.seasonal,
            days: null,
            dates: const <SeasonalDate>[SeasonalDate(11, 1)],
          ),
        ),
        isEmpty,
      );
    });

    test('level ölçümünde en az bir seçenek', () {
      expect(
        validateItemForm(form(measureType: MeasureType.level)).keys,
        contains(ItemFormField.measure),
      );
      expect(
        validateItemForm(
          form(
            measureType: MeasureType.level,
            levels: const <String>[' ', 'Orta'],
          ),
        ),
        isEmpty,
      );
    });

    test('number ölçümünde birim ve etiket zorunlu', () {
      expect(
        validateItemForm(
          form(measureType: MeasureType.number, unit: 'mm'),
        ).keys,
        contains(ItemFormField.measure),
      );
      expect(
        validateItemForm(
          form(
            measureType: MeasureType.number,
            unit: 'mm',
            label: 'En düşük diş',
          ),
        ),
        isEmpty,
      );
    });

    test('tires ve none ölçümü ek alan istemiyor', () {
      expect(validateItemForm(form(measureType: MeasureType.tires)), isEmpty);
      expect(validateItemForm(form(measureType: MeasureType.none)), isEmpty);
    });
  });

  group('buildSchedule', () {
    test('gün', () {
      expect(buildSchedule(form()), Schedule.days(30));
    });

    test('km', () {
      expect(
        buildSchedule(form(kind: ScheduleKind.km, days: null, km: 15000)),
        Schedule.km(15000),
      );
    });

    test('both', () {
      expect(
        buildSchedule(form(kind: ScheduleKind.both, days: 365, km: 15000)),
        Schedule.both(days: 365, km: 15000),
      );
    });

    test('mevsimsel', () {
      final Schedule s = buildSchedule(
        form(
          kind: ScheduleKind.seasonal,
          days: null,
          dates: const <SeasonalDate>[SeasonalDate(11, 1), SeasonalDate(4, 1)],
        ),
      );
      expect(s.kind, ScheduleKind.seasonal);
      expect(s.dates.length, 2);
    });
  });

  group('buildMeasure', () {
    test('level boş seçenekleri atıyor ve kırpıyor', () {
      final Measure m = buildMeasure(
        form(
          measureType: MeasureType.level,
          levels: const <String>[' Az ', '', 'Çok'],
        ),
      );
      expect(m.type, MeasureType.level);
      expect(m.levels, <String>['Az', 'Çok']);
    });

    test('number birim ve etiket', () {
      final Measure m = buildMeasure(
        form(measureType: MeasureType.number, unit: ' mm ', label: ' Diş '),
      );
      expect(m.unit, 'mm');
      expect(m.label, 'Diş');
    });

    test('tires', () {
      expect(
        buildMeasure(form(measureType: MeasureType.tires)).type,
        MeasureType.tires,
      );
    });
  });

  group('isKmGoingBack', () {
    test('küçültme geriye alma', () {
      expect(isKmGoingBack(current: 118420, next: 118000), isTrue);
    });

    test('aynı veya büyük değer değil', () {
      expect(isKmGoingBack(current: 118420, next: 118420), isFalse);
      expect(isKmGoingBack(current: 118420, next: 119000), isFalse);
    });
  });
}
