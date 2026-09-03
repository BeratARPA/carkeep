/// Madde düzenleme sayfasının saf doğrulaması (01-spec §3.7).
///
/// Widget iş mantığı taşımaz (CLAUDE.md): ekran yalnız metin toplar, geçerlilik
/// ve `Schedule`/`Measure` üretimi burada.
library;

import '../core/strings_tr.dart';
import 'models/measure.dart';
import 'models/schedule.dart';

/// Hata gösterilecek alan.
enum ItemFormField { name, intervalDays, intervalKm, seasonalDates, measure }

/// Aralık sınırları; presetlerin dışına elle çıkılabilir ama sınırsız değil.
const int kMinIntervalDays = 1;
const int kMaxIntervalDays = 3650;
const int kMinIntervalKm = 100;
const int kMaxIntervalKm = 200000;

/// Ekrandan gelen ham form. Immutable.
class ItemFormData {
  const ItemFormData({
    required this.name,
    required this.kind,
    this.intervalDays,
    this.intervalKm,
    this.dates = const <SeasonalDate>[],
    this.measureType = MeasureType.none,
    this.levels = const <String>[],
    this.unit,
    this.label,
  });

  final String name;
  final ScheduleKind kind;
  final int? intervalDays;
  final int? intervalKm;
  final List<SeasonalDate> dates;
  final MeasureType measureType;
  final List<String> levels;
  final String? unit;
  final String? label;

  ItemFormData copyWith({
    String? name,
    ScheduleKind? kind,
    Object? intervalDays = _sentinel,
    Object? intervalKm = _sentinel,
    List<SeasonalDate>? dates,
    MeasureType? measureType,
    List<String>? levels,
    Object? unit = _sentinel,
    Object? label = _sentinel,
  }) {
    return ItemFormData(
      name: name ?? this.name,
      kind: kind ?? this.kind,
      intervalDays: intervalDays == _sentinel
          ? this.intervalDays
          : intervalDays as int?,
      intervalKm: intervalKm == _sentinel
          ? this.intervalKm
          : intervalKm as int?,
      dates: dates ?? this.dates,
      measureType: measureType ?? this.measureType,
      levels: levels ?? this.levels,
      unit: unit == _sentinel ? this.unit : unit as String?,
      label: label == _sentinel ? this.label : label as String?,
    );
  }
}

const Object _sentinel = Object();

/// Boşsa form geçerli.
Map<ItemFormField, String> validateItemForm(ItemFormData d) {
  final Map<ItemFormField, String> errors = <ItemFormField, String>{};

  if (d.name.trim().isEmpty) {
    errors[ItemFormField.name] = S.errNameRequired;
  }

  final bool needsDays =
      d.kind == ScheduleKind.days || d.kind == ScheduleKind.both;
  final bool needsKm =
      d.kind == ScheduleKind.km || d.kind == ScheduleKind.both;

  if (needsDays && !_inRange(d.intervalDays, kMinIntervalDays, kMaxIntervalDays)) {
    errors[ItemFormField.intervalDays] = S.errIntervalDaysRequired;
  }
  if (needsKm && !_inRange(d.intervalKm, kMinIntervalKm, kMaxIntervalKm)) {
    errors[ItemFormField.intervalKm] = S.errIntervalKmRequired;
  }
  if (d.kind == ScheduleKind.seasonal && d.dates.isEmpty) {
    errors[ItemFormField.seasonalDates] = S.errSeasonalRequired;
  }

  switch (d.measureType) {
    case MeasureType.level:
      if (d.levels.where((String e) => e.trim().isNotEmpty).isEmpty) {
        errors[ItemFormField.measure] = S.errLevelsRequired;
      }
    case MeasureType.number:
      if ((d.unit ?? '').trim().isEmpty || (d.label ?? '').trim().isEmpty) {
        errors[ItemFormField.measure] = S.errNumberFieldsRequired;
      }
    case MeasureType.none:
    case MeasureType.tires:
      break;
  }

  return errors;
}

/// Yalnız [validateItemForm] boş döndüğünde çağrılmalı.
Schedule buildSchedule(ItemFormData d) => switch (d.kind) {
  ScheduleKind.days => Schedule.days(d.intervalDays!),
  ScheduleKind.km => Schedule.km(d.intervalKm!),
  ScheduleKind.both => Schedule.both(
    days: d.intervalDays!,
    km: d.intervalKm!,
  ),
  ScheduleKind.seasonal => Schedule.seasonal(d.dates),
};

/// Yalnız [validateItemForm] boş döndüğünde çağrılmalı.
Measure buildMeasure(ItemFormData d) => switch (d.measureType) {
  MeasureType.none => const Measure.none(),
  MeasureType.level => Measure.level(<String>[
    for (final String e in d.levels)
      if (e.trim().isNotEmpty) e.trim(),
  ]),
  MeasureType.tires => const Measure.tires(),
  MeasureType.number => Measure.number(
    unit: d.unit!.trim(),
    label: d.label!.trim(),
  ),
};

/// "Km düzelt": her değere izin var, geriye alınıyorsa onay istenir
/// (01-spec §3.7).
bool isKmGoingBack({required int current, required int next}) => next < current;

bool _inRange(int? v, int min, int max) => v != null && v >= min && v <= max;
