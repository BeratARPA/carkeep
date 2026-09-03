import 'dart:convert';

import 'measure.dart';
import 'schedule.dart';

/// Kontrol edilecek tek şey (01-spec §1). Immutable.
class CheckItem {
  const CheckItem({
    required this.id,
    required this.templateKey,
    required this.name,
    required this.groupKey,
    required this.schedule,
    required this.measure,
    required this.why,
    required this.how,
    required this.warn,
    required this.sourceNote,
    required this.verified,
    required this.startsFromInstall,
    required this.appliesLastService,
    required this.enabled,
    required this.sortOrder,
    required this.lastDoneDay,
    required this.lastDoneKm,
    required this.lastValue,
    required this.snoozeUntilDay,
  });

  final int id;

  /// Seed `id`; kullanıcı maddesinde null.
  final String? templateKey;
  final String name;
  final String groupKey;
  final Schedule schedule;
  final Measure measure;
  final String why;
  final List<String> how;
  final String? warn;
  final String? sourceNote;

  /// `true|partial|false`
  final String verified;

  final bool startsFromInstall;
  final bool appliesLastService;
  final bool enabled;
  final int sortOrder;

  /// `yyyy-MM-dd`
  final String? lastDoneDay;
  final int? lastDoneKm;
  final String? lastValue;

  /// `yyyy-MM-dd`
  final String? snoozeUntilDay;

  bool get isTemplateItem => templateKey != null;
  bool get hasLastDone => lastDoneDay != null;

  CheckItem copyWith({
    String? name,
    Schedule? schedule,
    bool? enabled,
    int? sortOrder,
    Object? lastDoneDay = _sentinel,
    Object? lastDoneKm = _sentinel,
    Object? lastValue = _sentinel,
    Object? snoozeUntilDay = _sentinel,
  }) {
    return CheckItem(
      id: id,
      templateKey: templateKey,
      name: name ?? this.name,
      groupKey: groupKey,
      schedule: schedule ?? this.schedule,
      measure: measure,
      why: why,
      how: how,
      warn: warn,
      sourceNote: sourceNote,
      verified: verified,
      startsFromInstall: startsFromInstall,
      appliesLastService: appliesLastService,
      enabled: enabled ?? this.enabled,
      sortOrder: sortOrder ?? this.sortOrder,
      lastDoneDay: lastDoneDay == _sentinel
          ? this.lastDoneDay
          : lastDoneDay as String?,
      lastDoneKm: lastDoneKm == _sentinel
          ? this.lastDoneKm
          : lastDoneKm as int?,
      lastValue: lastValue == _sentinel
          ? this.lastValue
          : lastValue as String?,
      snoozeUntilDay: snoozeUntilDay == _sentinel
          ? this.snoozeUntilDay
          : snoozeUntilDay as String?,
    );
  }

  @override
  String toString() => 'CheckItem($id, $name)';

  static const Object _sentinel = Object();
}

/// `how_json` sütununu çözer; bozuksa boş liste (metin gösterimi kritik değil).
List<String> decodeHow(String json) {
  try {
    final Object? decoded = jsonDecode(json);
    if (decoded is! List<Object?>) {
      return const <String>[];
    }
    return <String>[
      for (final Object? e in decoded)
        if (e is String) e,
    ];
  } on FormatException {
    return const <String>[];
  }
}

String encodeHow(List<String> how) => jsonEncode(how);
