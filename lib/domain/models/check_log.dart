/// "Yaptım" ile oluşan kayıt satırı (01-spec §1). Immutable.
class CheckLog {
  const CheckLog({
    required this.id,
    required this.itemId,
    required this.doneAt,
    required this.doneDay,
    required this.km,
    required this.value,
    required this.note,
    required this.kind,
  });

  final int id;
  final int itemId;
  final DateTime doneAt;

  /// `yyyy-MM-dd`
  final String doneDay;
  /// K-23: gün bazlı bir maddenin düzeltmesinde null.
  final int? km;

  /// Ölçüm değeri; `none` tipinde null.
  final String? value;
  final String? note;

  /// K-23: `done` = "Yaptım", `fix` = "Tarih/km düzelt".
  final String kind;

  bool get hasValue => value != null && value!.isNotEmpty;
  bool get hasNote => note != null && note!.isNotEmpty;
  bool get isFix => kind == 'fix';

  @override
  String toString() =>
      'CheckLog($id, item: $itemId, $doneDay, $km km, $kind)';
}
