/// Kotlin köprüsünün tek Dart sarmalayıcısı (K-05, 02-mimari §6).
/// Plugin yok; tek `MethodChannel`.
library;

import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/constants.dart';

/// Eşleşmiş Bluetooth cihazı (01-spec §3.1 adım 4).
class BondedDevice {
  const BondedDevice({required this.name, required this.address});

  final String name;
  final String address;

  /// Adı boş gelen cihazlar için adres gösterilir.
  String get displayName => name.isEmpty ? address : name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BondedDevice && other.address == address && other.name == name;

  @override
  int get hashCode => Object.hash(name, address);

  @override
  String toString() => 'BondedDevice($displayName, $address)';
}

/// Kotlin'in tuttuğu son sürüş özeti (Ayarlar tanı satırı, 01-spec §3.7).
class LastTripInfo {
  const LastTripInfo({
    required this.connectedAt,
    required this.disconnectedAt,
    required this.durationMin,
    required this.counted,
    required this.notified,
    required this.overdueCount,
    required this.note,
  });

  final DateTime? connectedAt;
  final DateTime? disconnectedAt;
  final int durationMin;
  final bool counted;
  final bool notified;
  final int overdueCount;
  final String? note;

  static LastTripInfo? fromJson(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) {
        return null;
      }
      return LastTripInfo(
        connectedAt: _millis(decoded['connectedAt']),
        disconnectedAt: _millis(decoded['disconnectedAt']),
        durationMin: (decoded['durationMin'] as num?)?.toInt() ?? 0,
        counted: decoded['counted'] == true,
        notified: decoded['notified'] == true,
        overdueCount: (decoded['overdueCount'] as num?)?.toInt() ?? 0,
        note: decoded['note'] as String?,
      );
    } on FormatException {
      return null;
    }
  }

  static DateTime? _millis(Object? v) =>
      v is num ? DateTime.fromMillisecondsSinceEpoch(v.toInt()) : null;

  @override
  String toString() =>
      'LastTripInfo($durationMin dk, counted: $counted, '
      'notified: $notified, note: $note)';
}

/// Ana ekran chip'i ve Ayarlar tanı satırı için (02-mimari §6).
class BluetoothState {
  const BluetoothState({
    required this.connected,
    required this.since,
    required this.lastTrip,
  });

  static const BluetoothState unknown = BluetoothState(
    connected: false,
    since: null,
    lastTrip: null,
  );

  final bool connected;
  final DateTime? since;
  final LastTripInfo? lastTrip;

  @override
  String toString() => 'BluetoothState(connected: $connected, since: $since)';
}

/// Kotlin'in biriktirdiği olaylar (02-mimari §6, 01-spec §7.3).
sealed class PendingEvent {
  const PendingEvent();

  static List<PendingEvent> decodeAll(String rawJson) {
    final Object? decoded;
    try {
      decoded = jsonDecode(rawJson);
    } on FormatException {
      return const <PendingEvent>[];
    }
    if (decoded is! List<Object?>) {
      return const <PendingEvent>[];
    }
    final List<PendingEvent> out = <PendingEvent>[];
    for (final Object? e in decoded) {
      if (e is! Map<String, Object?>) {
        continue;
      }
      final PendingEvent? event = switch (e['type']) {
        'trip' => TripEvent._from(e),
        'snooze' => SnoozeEvent._from(e),
        'fallback' => FallbackEvent._from(e),
        _ => null,
      };
      if (event != null) {
        out.add(event);
      }
    }
    return out;
  }
}

class TripEvent extends PendingEvent {
  const TripEvent({
    required this.connectedAt,
    required this.disconnectedAt,
    required this.durationMin,
    required this.counted,
    required this.notified,
    required this.overdueCount,
    required this.note,
  });

  factory TripEvent._from(Map<String, Object?> m) => TripEvent(
    connectedAt: LastTripInfo._millis(m['connectedAt']),
    disconnectedAt:
        LastTripInfo._millis(m['disconnectedAt']) ?? DateTime.now(),
    durationMin: (m['durationMin'] as num?)?.toInt() ?? 0,
    counted: m['counted'] == true,
    notified: m['notified'] == true,
    overdueCount: (m['overdueCount'] as num?)?.toInt() ?? 0,
    note: m['note'] as String?,
  );

  final DateTime? connectedAt;
  final DateTime disconnectedAt;
  final int durationMin;
  final bool counted;
  final bool notified;
  final int overdueCount;
  final String? note;
}

class SnoozeEvent extends PendingEvent {
  const SnoozeEvent({required this.untilDay});

  factory SnoozeEvent._from(Map<String, Object?> m) =>
      SnoozeEvent(untilDay: (m['untilDay'] as String?) ?? '');

  /// `yyyy-MM-dd`
  final String untilDay;
}

class FallbackEvent extends PendingEvent {
  const FallbackEvent({required this.at, required this.overdueCount});

  factory FallbackEvent._from(Map<String, Object?> m) => FallbackEvent(
    at: LastTripInfo._millis(m['at']) ?? DateTime.now(),
    overdueCount: (m['overdueCount'] as num?)?.toInt() ?? 0,
  );

  final DateTime at;
  final int overdueCount;
}

/// Bluetooth izni verilmediğinde `getBondedDevices` bunu fırlatır.
class BluetoothPermissionException implements Exception {
  const BluetoothPermissionException();

  @override
  String toString() => 'BluetoothPermissionException';
}

/// Bluetooth adaptörü bulunamadı (kapalı veya donanım yok).
class BluetoothUnavailableException implements Exception {
  const BluetoothUnavailableException();

  @override
  String toString() => 'BluetoothUnavailableException';
}

/// `MethodChannel` sarmalayıcısı. Tüm çağrılar tipli; `PlatformException`
/// anlamlı Dart hatalarına çevrilir.
class PlatformBridge {
  PlatformBridge({MethodChannel? channel})
    : channel = channel ?? const MethodChannel(kPlatformChannel);

  final MethodChannel channel;

  /// Kotlin → Dart: bildirime dokunulduğunda (uygulama açıkken).
  void setLaunchActionHandler(void Function(String action) onAction) {
    channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onLaunchAction') {
        final Object? arg = call.arguments;
        if (arg is String && arg.isNotEmpty) {
          onAction(arg);
        }
      }
      return null;
    });
  }

  void clearLaunchActionHandler() => channel.setMethodCallHandler(null);

  // ------------------------------------------------------------------ cihaz

  Future<int> getSdkInt() async =>
      await channel.invokeMethod<int>('getSdkInt') ?? 0;

  Future<String> getManufacturer() async =>
      await channel.invokeMethod<String>('getManufacturer') ?? '';

  // ----------------------------------------------------------------- izinler

  Future<bool> hasBluetoothPermission() async =>
      await channel.invokeMethod<bool>('hasBluetoothPermission') ?? false;

  Future<bool> requestBluetoothPermission() async =>
      await channel.invokeMethod<bool>('requestBluetoothPermission') ?? false;

  Future<bool> hasNotificationPermission() async =>
      await channel.invokeMethod<bool>('hasNotificationPermission') ?? false;

  Future<bool> requestNotificationPermission() async =>
      await channel.invokeMethod<bool>('requestNotificationPermission') ?? false;

  /// Kanal kullanıcı tarafından kapatılmış mı (07 §8).
  Future<bool> areNotificationsEnabled() async =>
      await channel.invokeMethod<bool>('areNotificationsEnabled') ?? true;

  Future<bool> isIgnoringBatteryOptimizations() async =>
      await channel.invokeMethod<bool>('isIgnoringBatteryOptimizations') ??
      false;

  Future<void> openBatteryOptimizationSettings() =>
      channel.invokeMethod<void>('openBatteryOptimizationSettings');

  Future<void> openAppSettings() =>
      channel.invokeMethod<void>('openAppSettings');

  Future<void> openNotificationSettings() =>
      channel.invokeMethod<void>('openNotificationSettings');

  // -------------------------------------------------------------- bluetooth

  /// İzin yoksa [BluetoothPermissionException], adaptör yoksa
  /// [BluetoothUnavailableException].
  Future<List<BondedDevice>> getBondedDevices() async {
    try {
      final List<Object?>? raw = await channel.invokeMethod<List<Object?>>(
        'getBondedDevices',
      );
      if (raw == null) {
        return const <BondedDevice>[];
      }
      return <BondedDevice>[
        for (final Object? e in raw)
          if (e is Map<Object?, Object?>)
            BondedDevice(
              name: (e['name'] as String?) ?? '',
              address: (e['address'] as String?) ?? '',
            ),
      ]..sort(
        (BondedDevice a, BondedDevice b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
    } on PlatformException catch (e) {
      throw switch (e.code) {
        'NO_PERMISSION' => const BluetoothPermissionException(),
        'NO_ADAPTER' => const BluetoothUnavailableException(),
        _ => e,
      };
    }
  }

  Future<BluetoothState> getBluetoothState() async {
    final Map<Object?, Object?>? raw = await channel
        .invokeMethod<Map<Object?, Object?>>('getBluetoothState');
    if (raw == null) {
      return BluetoothState.unknown;
    }
    final Object? since = raw['since'];
    return BluetoothState(
      connected: raw['connected'] == true,
      since: since is num
          ? DateTime.fromMillisecondsSinceEpoch(since.toInt())
          : null,
      lastTrip: LastTripInfo.fromJson(raw['lastTrip'] as String?),
    );
  }

  // --------------------------------------------------------------- snapshot

  Future<void> writeSnapshot(String json) =>
      channel.invokeMethod<void>('writeSnapshot', <String, Object?>{
        'json': json,
      });

  Future<String?> readSnapshot() =>
      channel.invokeMethod<String>('readSnapshot');

  // ----------------------------------------------------------------- olaylar

  /// Oku + sil, tek çağrı. Boşken `[]`.
  Future<List<PendingEvent>> drainPendingEvents() async {
    final String raw =
        await channel.invokeMethod<String>('drainPendingEvents') ?? '[]';
    return PendingEvent.decodeAll(raw);
  }

  /// Bildirimden gelindi mi (`overdue`); okununca temizlenir.
  Future<String?> getLaunchAction() =>
      channel.invokeMethod<String>('getLaunchAction');

  // -------------------------------------------------------------- yaşam döngüsü

  Future<void> scheduleDailyWorker() =>
      channel.invokeMethod<void>('scheduleDailyWorker');

  Future<void> cancelNotification() =>
      channel.invokeMethod<void>('cancelNotification');

  /// "Verileri sıfırla": prefs temizlenir, bildirim iptal edilir.
  Future<void> clearEngine() => channel.invokeMethod<void>('clearEngine');
}
