import '../../core/constants.dart';

/// Kotlin'in yazdığı, Dart'ın `trips` tablosuna işlediği sürüş kaydı
/// (01-spec §7.3, 02-mimari §3). Immutable.
class Trip {
  const Trip({
    required this.id,
    required this.connectedAt,
    required this.disconnectedAt,
    required this.durationMin,
    required this.counted,
    required this.notified,
    required this.overdueCount,
    required this.note,
  });

  final int id;

  /// Bağlanma anı bilinmiyorsa null (kopma öncesi bağlanma görülmemiş).
  final DateTime? connectedAt;
  final DateTime disconnectedAt;
  final int durationMin;

  /// `minTripMinutes` eşiğini geçti mi.
  final bool counted;
  final bool notified;
  final int overdueCount;

  /// K-24 sözlüğü.
  final String? note;

  /// Yedek bildirim satırı; kopma değil (K-26).
  bool get isFallback => note == kTripNoteFallback;

  @override
  String toString() =>
      'Trip($id, $disconnectedAt, $durationMin dk, counted: $counted, '
      'notified: $notified, note: $note)';
}
