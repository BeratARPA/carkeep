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
  });

  final int id;
  final int itemId;
  final DateTime doneAt;

  /// `yyyy-MM-dd`
  final String doneDay;
  final int km;

  /// Ölçüm değeri; `none` tipinde null.
  final String? value;
  final String? note;

  bool get hasValue => value != null && value!.isNotEmpty;
  bool get hasNote => note != null && note!.isNotEmpty;

  @override
  String toString() => 'CheckLog($id, item: $itemId, $doneDay, $km km)';
}
