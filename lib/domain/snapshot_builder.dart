/// Dart → Kotlin snapshot'ı (02-mimari §5, 01-spec §6). Yan etkisiz.
///
/// Kotlin hesap yapmaz (K-04): burada üretilen `dueDay`/`dueKm` değerlerini
/// bugünle ve km ile karşılaştırmakla yetinir.
library;

import 'dart:convert';

import '../core/constants.dart';
import 'models/check_item.dart';
import 'models/item_status.dart';
import 'models/rules.dart';
import 'models/vehicle.dart';
import 'status_calculator.dart';

abstract final class SnapshotBuilder {
  /// [generatedAt] yerel saat; ISO 8601 + yerel offset olarak yazılır.
  ///
  /// Snapshot yalnız `enabled = true` **ve** durumu `unknown` olmayan
  /// maddeleri içerir (01-spec §6).
  static Map<String, Object?> build({
    required Vehicle? vehicle,
    required List<CheckItem> items,
    required Rules rules,
    required DateTime installDay,
    required DateTime today,
    required DateTime generatedAt,
  }) {
    final List<Map<String, Object?>> snapshotItems = <Map<String, Object?>>[];

    if (vehicle != null) {
      for (final CheckItem item in items) {
        if (!item.enabled) {
          continue;
        }
        final ItemStatus status = StatusCalculator.compute(
          item: item,
          currentKm: vehicle.currentKm,
          installDay: installDay,
          today: today,
        );
        if (status.state == ItemState.unknown) {
          continue;
        }
        snapshotItems.add(<String, Object?>{
          'id': item.id,
          'name': item.name,
          'dueDay': status.dueDay,
          'dueKm': status.dueKm,
          'snoozeUntilDay': item.snoozeUntilDay,
        });
      }
    }

    return <String, Object?>{
      'version': kSnapshotVersion,
      'generatedAt': isoWithLocalOffset(generatedAt),
      'car': <String, Object?>{
        'address': vehicle?.btAddress,
        'name': vehicle?.btName,
        'km': vehicle?.currentKm ?? 0,
      },
      'rules': <String, Object?>{
        'onlyOverdue': rules.onlyOverdue,
        'oncePerDay': rules.oncePerDay,
        'minTripMinutes': rules.minTripMinutes,
        'graceMinutes': rules.graceMinutes,
        'fallbackAfterDays': rules.fallbackAfterDays,
        'requireMotion': rules.requireMotion,
      },
      'items': snapshotItems,
    };
  }

  /// `writeSnapshot` argümanı.
  static String buildJson({
    required Vehicle? vehicle,
    required List<CheckItem> items,
    required Rules rules,
    required DateTime installDay,
    required DateTime today,
    required DateTime generatedAt,
  }) {
    return jsonEncode(
      build(
        vehicle: vehicle,
        items: items,
        rules: rules,
        installDay: installDay,
        today: today,
        generatedAt: generatedAt,
      ),
    );
  }
}

/// `2026-09-03T14:05:12+03:00`. `DateTime.toIso8601String()` yerel saatte
/// offset yazmadığı için elle kuruluyor.
String isoWithLocalOffset(DateTime local) {
  String two(int v) => v.toString().padLeft(2, '0');

  final Duration offset = local.timeZoneOffset;
  final String sign = offset.isNegative ? '-' : '+';
  final Duration abs = offset.abs();
  final String offsetText =
      '$sign${two(abs.inHours)}:${two(abs.inMinutes.remainder(60))}';

  return '${local.year.toString().padLeft(4, '0')}-'
      '${two(local.month)}-${two(local.day)}'
      'T${two(local.hour)}:${two(local.minute)}:${two(local.second)}'
      '$offsetText';
}
