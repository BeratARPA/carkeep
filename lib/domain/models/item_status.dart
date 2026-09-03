/// Madde durumu (01-spec §1, §2).
enum ItemState { overdue, soon, ok, unknown }

/// `both` maddede hesabı bağlayan boyut (01-spec §2.2).
enum BindingDim { days, km }

/// `StatusCalculator.compute` çıktısı. Yan etkisiz, immutable.
class ItemStatus {
  const ItemStatus({
    required this.state,
    required this.shortText,
    required this.longText,
    required this.sortKey,
    this.dueDay,
    this.dueKm,
    this.daysLeft,
    this.kmLeft,
    this.binding,
  });

  final ItemState state;

  /// `yyyy-MM-dd`; hesaplanamıyorsa null.
  final String? dueDay;
  final int? dueKm;

  /// `dueDay - today`, takvim günü.
  final int? daysLeft;

  /// `dueKm - currentKm`.
  final int? kmLeft;

  /// `both` maddede hangi boyut bağlıyor; tek boyutlu maddede o boyut.
  /// `unknown` durumda null.
  final BindingDim? binding;

  /// Ana ekranın sağ sütunu: `8 gün gecikti`, `1.480 km kaldı`, `16 Eyl`…
  final String shortText;

  /// Detay sayfası: `{kısa metin}. {aralık}.`
  final String longText;

  /// K-17: bölüm içi sıralama anahtarı = bağlayıcı kalan / bağlayıcı aralık,
  /// artan. `unknown` maddelerde `double.infinity` (şablon sırası korunur).
  final double sortKey;

  bool get isOverdue => state == ItemState.overdue;
  bool get isUnknown => state == ItemState.unknown;

  @override
  String toString() =>
      'ItemStatus($state, dueDay: $dueDay, dueKm: $dueKm, '
      'daysLeft: $daysLeft, kmLeft: $kmLeft, binding: $binding, '
      'short: "$shortText", sortKey: $sortKey)';
}
