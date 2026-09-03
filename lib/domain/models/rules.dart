import '../../core/constants.dart';

/// Bildirim kuralları (01-spec §3.7, §7). Immutable.
class Rules {
  const Rules({
    this.onlyOverdue = kDefaultOnlyOverdue,
    this.oncePerDay = kDefaultOncePerDay,
    this.minTripMinutes = kDefaultMinTripMinutes,
    this.graceMinutes = kDefaultGraceMinutes,
    this.fallbackAfterDays = kDefaultFallbackAfterDays,
  });

  /// Yalnız gecikmiş madde varken bildir.
  final bool onlyOverdue;

  /// Aynı gün ikinci sürüşte sus.
  final bool oncePerDay;

  /// Bundan kısa bağlantı sürüş sayılmaz (1–30).
  final int minTripMinutes;

  /// Hızlı geri bağlanma toleransı, dakika (0–5). K-06.
  final int graceMinutes;

  /// Sürüşsüz dönem yedeği eşiği, gün. 0 = kapalı. K-12.
  final int fallbackAfterDays;

  static const Rules defaults = Rules();

  Rules copyWith({
    bool? onlyOverdue,
    bool? oncePerDay,
    int? minTripMinutes,
    int? graceMinutes,
    int? fallbackAfterDays,
  }) {
    return Rules(
      onlyOverdue: onlyOverdue ?? this.onlyOverdue,
      oncePerDay: oncePerDay ?? this.oncePerDay,
      minTripMinutes: minTripMinutes ?? this.minTripMinutes,
      graceMinutes: graceMinutes ?? this.graceMinutes,
      fallbackAfterDays: fallbackAfterDays ?? this.fallbackAfterDays,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Rules &&
          other.onlyOverdue == onlyOverdue &&
          other.oncePerDay == oncePerDay &&
          other.minTripMinutes == minTripMinutes &&
          other.graceMinutes == graceMinutes &&
          other.fallbackAfterDays == fallbackAfterDays;

  @override
  int get hashCode => Object.hash(
    onlyOverdue,
    oncePerDay,
    minTripMinutes,
    graceMinutes,
    fallbackAfterDays,
  );

  @override
  String toString() =>
      'Rules(onlyOverdue: $onlyOverdue, oncePerDay: $oncePerDay, '
      'minTripMinutes: $minTripMinutes, graceMinutes: $graceMinutes, '
      'fallbackAfterDays: $fallbackAfterDays)';
}
