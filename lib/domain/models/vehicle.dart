/// Araç profili (01-spec §3.1, §3.7). Tek araç (K-01). Immutable.
class Vehicle {
  const Vehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.currentKm,
    required this.btAddress,
    required this.btName,
    required this.tireFrontBar,
    required this.tireRearBar,
    required this.createdAt,
  });

  final int id;
  final String brand;
  final String model;
  final String year;
  final int currentKm;

  /// Seçili araç Bluetooth cihazı; seçilmediyse null.
  final String? btAddress;
  final String? btName;

  /// Hedef lastik basınçları (bar); girilmediyse null.
  final double? tireFrontBar;
  final double? tireRearBar;

  final DateTime createdAt;

  bool get hasDevice => btAddress != null && btAddress!.isNotEmpty;
  bool get hasTargetPressure => tireFrontBar != null || tireRearBar != null;

  /// Ana ekran başlığı: `Fiat Egea 1.6 MultiJet, 2019`.
  String get displayName {
    final String base = <String>[
      brand,
      model,
    ].where((String s) => s.isNotEmpty).join(' ');
    return year.isEmpty ? base : '$base, $year';
  }

  Vehicle copyWith({
    String? brand,
    String? model,
    String? year,
    int? currentKm,
    Object? btAddress = _sentinel,
    Object? btName = _sentinel,
    Object? tireFrontBar = _sentinel,
    Object? tireRearBar = _sentinel,
  }) {
    return Vehicle(
      id: id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      currentKm: currentKm ?? this.currentKm,
      btAddress: btAddress == _sentinel
          ? this.btAddress
          : btAddress as String?,
      btName: btName == _sentinel ? this.btName : btName as String?,
      tireFrontBar: tireFrontBar == _sentinel
          ? this.tireFrontBar
          : tireFrontBar as double?,
      tireRearBar: tireRearBar == _sentinel
          ? this.tireRearBar
          : tireRearBar as double?,
      createdAt: createdAt,
    );
  }

  @override
  String toString() => 'Vehicle($id, $displayName, $currentKm km)';

  static const Object _sentinel = Object();
}
