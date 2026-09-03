import 'dart:convert';

/// Ölçüm tipi (01-spec §3.3).
enum MeasureType { none, level, tires, number }

MeasureType measureTypeFromString(String raw) {
  return switch (raw) {
    'none' => MeasureType.none,
    'level' => MeasureType.level,
    'tires' => MeasureType.tires,
    'number' => MeasureType.number,
    _ => throw FormatException('Bilinmeyen ölçüm tipi', raw),
  };
}

String measureTypeToString(MeasureType type) => switch (type) {
  MeasureType.none => 'none',
  MeasureType.level => 'level',
  MeasureType.tires => 'tires',
  MeasureType.number => 'number',
};

/// Ölçüm tanımı. `measure_json` sütununun tipli hâli.
class Measure {
  const Measure._(
    this.type, {
    this.levels = const <String>[],
    this.unit,
    this.label,
  });

  const Measure.none() : this._(MeasureType.none);

  factory Measure.level(List<String> levels) {
    if (levels.isEmpty) {
      throw const FormatException('level ölçümünde en az bir seçenek olmalı');
    }
    return Measure._(
      MeasureType.level,
      levels: List<String>.unmodifiable(levels),
    );
  }

  const Measure.tires({String unit = 'bar'})
    : this._(MeasureType.tires, unit: unit);

  const Measure.number({required String unit, required String label})
    : this._(MeasureType.number, unit: unit, label: label);

  /// DB satırından.
  factory Measure.fromDb({required String type, String? json}) {
    final MeasureType t = measureTypeFromString(type);
    final Map<String, Object?> m = json == null || json.isEmpty
        ? const <String, Object?>{}
        : (jsonDecode(json) as Map<String, Object?>);
    return switch (t) {
      MeasureType.none => const Measure.none(),
      MeasureType.level => Measure.level(<String>[
        for (final Object? e in (m['levels'] as List<Object?>? ??
            const <Object?>[]))
          e! as String,
      ]),
      MeasureType.tires => Measure.tires(
        unit: (m['unit'] as String?) ?? 'bar',
      ),
      MeasureType.number => Measure.number(
        unit: _requiredStr(m['unit'], 'unit'),
        label: _requiredStr(m['label'], 'label'),
      ),
    };
  }

  final MeasureType type;

  /// `level` için seçenek çipleri.
  final List<String> levels;

  /// `tires` (`bar`) ve `number` (`mm`) için birim.
  final String? unit;

  /// `number` için alan etiketi (ör. "En düşük diş").
  final String? label;

  /// Kullanıcının değer girmesi zorunlu mu (01-spec §3.3).
  bool get isRequired =>
      type == MeasureType.level || type == MeasureType.tires;

  String? get json => switch (type) {
    MeasureType.none => null,
    MeasureType.level => jsonEncode(<String, Object?>{'levels': levels}),
    MeasureType.tires => jsonEncode(<String, Object?>{'unit': unit}),
    MeasureType.number => jsonEncode(<String, Object?>{
      'unit': unit,
      'label': label,
    }),
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Measure) {
      return false;
    }
    if (other.type != type ||
        other.unit != unit ||
        other.label != label ||
        other.levels.length != levels.length) {
      return false;
    }
    for (int i = 0; i < levels.length; i++) {
      if (other.levels[i] != levels[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(type, unit, label, Object.hashAll(levels));

  @override
  String toString() =>
      'Measure(${measureTypeToString(type)}, levels: $levels, '
      'unit: $unit, label: $label)';

  static String _requiredStr(Object? v, String field) {
    if (v is! String || v.isEmpty) {
      throw FormatException('$field zorunlu', '$v');
    }
    return v;
  }
}
