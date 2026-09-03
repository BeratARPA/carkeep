import 'dart:convert';

/// Takvim türü (01-spec §1).
enum ScheduleKind { days, km, both, seasonal }

ScheduleKind scheduleKindFromString(String raw) {
  return switch (raw) {
    'days' => ScheduleKind.days,
    'km' => ScheduleKind.km,
    'both' => ScheduleKind.both,
    'seasonal' => ScheduleKind.seasonal,
    _ => throw FormatException('Bilinmeyen takvim türü', raw),
  };
}

String scheduleKindToString(ScheduleKind kind) => switch (kind) {
  ScheduleKind.days => 'days',
  ScheduleKind.km => 'km',
  ScheduleKind.both => 'both',
  ScheduleKind.seasonal => 'seasonal',
};

/// Mevsimsel tarih: yıl taşımaz.
class SeasonalDate {
  const SeasonalDate(this.month, this.day);

  final int month;
  final int day;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeasonalDate && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(month, day);

  @override
  String toString() => 'SeasonalDate($month, $day)';
}

/// Maddenin ne zaman "geldiğini" belirleyen kural (01-spec §1).
class Schedule {
  const Schedule._({
    required this.kind,
    this.intervalDays,
    this.intervalKm,
    this.dates = const <SeasonalDate>[],
  });

  factory Schedule.days(int days) {
    _positive(days, 'days');
    return Schedule._(kind: ScheduleKind.days, intervalDays: days);
  }

  factory Schedule.km(int km) {
    _positive(km, 'km');
    return Schedule._(kind: ScheduleKind.km, intervalKm: km);
  }

  factory Schedule.both({required int days, required int km}) {
    _positive(days, 'days');
    _positive(km, 'km');
    return Schedule._(
      kind: ScheduleKind.both,
      intervalDays: days,
      intervalKm: km,
    );
  }

  factory Schedule.seasonal(List<SeasonalDate> dates) {
    if (dates.isEmpty) {
      throw const FormatException('Mevsimsel takvimde en az bir tarih olmalı');
    }
    for (final SeasonalDate d in dates) {
      if (d.month < 1 || d.month > 12 || d.day < 1 || d.day > 31) {
        throw FormatException('Geçersiz mevsimsel tarih', '$d');
      }
    }
    return Schedule._(
      kind: ScheduleKind.seasonal,
      dates: List<SeasonalDate>.unmodifiable(dates),
    );
  }

  /// DB satırından. Değerler tutarsızsa [FormatException].
  factory Schedule.fromDb({
    required String kind,
    int? intervalDays,
    int? intervalKm,
    String? seasonalDatesJson,
  }) {
    return switch (scheduleKindFromString(kind)) {
      ScheduleKind.days => Schedule.days(
        _required(intervalDays, 'interval_days'),
      ),
      ScheduleKind.km => Schedule.km(_required(intervalKm, 'interval_km')),
      ScheduleKind.both => Schedule.both(
        days: _required(intervalDays, 'interval_days'),
        km: _required(intervalKm, 'interval_km'),
      ),
      ScheduleKind.seasonal => Schedule.seasonal(
        decodeSeasonalDates(_requiredStr(seasonalDatesJson, 'seasonal_dates')),
      ),
    };
  }

  final ScheduleKind kind;
  final int? intervalDays;
  final int? intervalKm;
  final List<SeasonalDate> dates;

  String? get seasonalDatesJson =>
      kind == ScheduleKind.seasonal ? encodeSeasonalDates(dates) : null;

  Schedule copyWith({int? intervalDays, int? intervalKm}) {
    return switch (kind) {
      ScheduleKind.days => Schedule.days(intervalDays ?? this.intervalDays!),
      ScheduleKind.km => Schedule.km(intervalKm ?? this.intervalKm!),
      ScheduleKind.both => Schedule.both(
        days: intervalDays ?? this.intervalDays!,
        km: intervalKm ?? this.intervalKm!,
      ),
      ScheduleKind.seasonal => this,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Schedule) {
      return false;
    }
    if (other.kind != kind ||
        other.intervalDays != intervalDays ||
        other.intervalKm != intervalKm ||
        other.dates.length != dates.length) {
      return false;
    }
    for (int i = 0; i < dates.length; i++) {
      if (other.dates[i] != dates[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(kind, intervalDays, intervalKm, Object.hashAll(dates));

  @override
  String toString() =>
      'Schedule(${scheduleKindToString(kind)}, days: $intervalDays, '
      'km: $intervalKm, dates: $dates)';

  static void _positive(int v, String field) {
    if (v <= 0) {
      throw FormatException('$field pozitif olmalı', '$v');
    }
  }

  static int _required(int? v, String field) {
    if (v == null) {
      throw FormatException('$field zorunlu', 'null');
    }
    return v;
  }

  static String _requiredStr(String? v, String field) {
    if (v == null || v.isEmpty) {
      throw FormatException('$field zorunlu', 'null');
    }
    return v;
  }
}

String encodeSeasonalDates(List<SeasonalDate> dates) {
  return jsonEncode(<Map<String, int>>[
    for (final SeasonalDate d in dates)
      <String, int>{'month': d.month, 'day': d.day},
  ]);
}

List<SeasonalDate> decodeSeasonalDates(String json) {
  final Object? decoded = jsonDecode(json);
  if (decoded is! List<Object?>) {
    throw FormatException('Mevsimsel tarihler dizi olmalı', json);
  }
  return <SeasonalDate>[
    for (final Object? e in decoded)
      if (e is Map<String, Object?>)
        SeasonalDate(e['month']! as int, e['day']! as int)
      else
        throw FormatException('Mevsimsel tarih nesne olmalı', json),
  ];
}
