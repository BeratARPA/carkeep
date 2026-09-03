import 'package:carkeep/data/platform/platform_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kanalı taklit eden yardımcı: gelen çağrıları kaydeder, hazır cevap döner.
class _FakeChannel {
  _FakeChannel() : channel = const MethodChannel('carkeep.test/platform');

  final MethodChannel channel;
  final List<MethodCall> calls = <MethodCall>[];
  final Map<String, Object?> replies = <String, Object?>{};
  final Map<String, PlatformException> errors = <String, PlatformException>{};

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call);
          final PlatformException? err = errors[call.method];
          if (err != null) {
            throw err;
          }
          return replies[call.method];
        });
  }

  void dispose() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  }

  MethodCall get last => calls.last;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeChannel fake;
  late PlatformBridge bridge;

  setUp(() {
    fake = _FakeChannel()..install();
    bridge = PlatformBridge(channel: fake.channel);
  });

  tearDown(() => fake.dispose());

  group('izinler', () {
    test('bool dönen metotlar', () async {
      fake.replies['hasBluetoothPermission'] = true;
      fake.replies['hasNotificationPermission'] = false;
      fake.replies['isIgnoringBatteryOptimizations'] = true;
      fake.replies['areNotificationsEnabled'] = false;

      expect(await bridge.hasBluetoothPermission(), isTrue);
      expect(await bridge.hasNotificationPermission(), isFalse);
      expect(await bridge.isIgnoringBatteryOptimizations(), isTrue);
      expect(await bridge.areNotificationsEnabled(), isFalse);
    });

    test('null cevap güvenli varsayılana düşüyor', () async {
      expect(await bridge.hasBluetoothPermission(), isFalse);
      expect(await bridge.hasNotificationPermission(), isFalse);
      // Bildirim kanalı bilgisi gelmezse uyarı şeridi göstermeyiz.
      expect(await bridge.areNotificationsEnabled(), isTrue);
    });

    test('izin isteme metotları', () async {
      fake.replies['requestBluetoothPermission'] = true;
      fake.replies['requestNotificationPermission'] = false;
      expect(await bridge.requestBluetoothPermission(), isTrue);
      expect(await bridge.requestNotificationPermission(), isFalse);
      expect(
        fake.calls.map((MethodCall c) => c.method).toList(),
        <String>['requestBluetoothPermission', 'requestNotificationPermission'],
      );
    });

    test('ayar ekranlarını açan metotlar çağrılıyor', () async {
      await bridge.openAppSettings();
      await bridge.openBatteryOptimizationSettings();
      await bridge.openNotificationSettings();
      expect(fake.calls.map((MethodCall c) => c.method).toList(), <String>[
        'openAppSettings',
        'openBatteryOptimizationSettings',
        'openNotificationSettings',
      ]);
    });
  });

  group('getBondedDevices', () {
    test('liste tipli modele dönüşüyor ve ada göre sıralanıyor', () async {
      fake.replies['getBondedDevices'] = <Object?>[
        <Object?, Object?>{'name': 'Uconnect', 'address': '00:11:22:33:44:55'},
        <Object?, Object?>{'name': 'JBL Flip 6', 'address': 'AA:BB:CC:DD:EE:FF'},
      ];
      final List<BondedDevice> devices = await bridge.getBondedDevices();
      expect(devices.length, 2);
      expect(devices.first.name, 'JBL Flip 6');
      expect(devices.last.address, '00:11:22:33:44:55');
    });

    test('adı boş cihazda adres gösterilir', () async {
      fake.replies['getBondedDevices'] = <Object?>[
        <Object?, Object?>{'name': '', 'address': '00:11:22:33:44:55'},
      ];
      expect(
        (await bridge.getBondedDevices()).single.displayName,
        '00:11:22:33:44:55',
      );
    });

    test('boş liste', () async {
      fake.replies['getBondedDevices'] = <Object?>[];
      expect(await bridge.getBondedDevices(), isEmpty);
    });

    test('isBluetoothEnabled adaptör durumunu veriyor', () async {
      fake.replies['isBluetoothEnabled'] = true;
      expect(await bridge.isBluetoothEnabled(), isTrue);
      fake.replies['isBluetoothEnabled'] = false;
      expect(await bridge.isBluetoothEnabled(), isFalse);
      // Cevap gelmezse "kapalı" varsayılır: yanlışlıkla "cihaz yok" demeyiz.
      fake.replies.remove('isBluetoothEnabled');
      expect(await bridge.isBluetoothEnabled(), isFalse);
    });

    test('adaptör kapalıyken boş liste hata değil', () async {
      fake.replies['isBluetoothEnabled'] = false;
      fake.replies['getBondedDevices'] = <Object?>[];
      expect(await bridge.isBluetoothEnabled(), isFalse);
      expect(await bridge.getBondedDevices(), isEmpty);
    });

    test('NO_PERMISSION → BluetoothPermissionException', () async {
      fake.errors['getBondedDevices'] = PlatformException(
        code: 'NO_PERMISSION',
        message: 'BLUETOOTH_CONNECT',
      );
      expect(
        () => bridge.getBondedDevices(),
        throwsA(isA<BluetoothPermissionException>()),
      );
    });

    test('NO_ADAPTER → BluetoothUnavailableException', () async {
      fake.errors['getBondedDevices'] = PlatformException(code: 'NO_ADAPTER');
      expect(
        () => bridge.getBondedDevices(),
        throwsA(isA<BluetoothUnavailableException>()),
      );
    });

    test('bilinmeyen hata olduğu gibi geçiyor', () async {
      fake.errors['getBondedDevices'] = PlatformException(code: 'BASKA');
      expect(
        () => bridge.getBondedDevices(),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  group('snapshot', () {
    test('writeSnapshot json argümanını sarıyor', () async {
      await bridge.writeSnapshot('{"version":1}');
      expect(fake.last.method, 'writeSnapshot');
      expect(fake.last.arguments, <String, Object?>{'json': '{"version":1}'});
    });

    test('readSnapshot geçiyor', () async {
      fake.replies['readSnapshot'] = '{"version":1}';
      expect(await bridge.readSnapshot(), '{"version":1}');
    });

    test('readSnapshot boşken null', () async {
      expect(await bridge.readSnapshot(), isNull);
    });
  });

  group('getBluetoothState', () {
    test('bağlı değilken', () async {
      fake.replies['getBluetoothState'] = <Object?, Object?>{
        'connected': false,
        'since': null,
        'lastTrip': null,
      };
      final BluetoothState s = await bridge.getBluetoothState();
      expect(s.connected, isFalse);
      expect(s.since, isNull);
      expect(s.lastTrip, isNull);
    });

    test('bağlıyken ve son sürüş varken', () async {
      fake.replies['getBluetoothState'] = <Object?, Object?>{
        'connected': true,
        'since': 1756900000000,
        'lastTrip':
            '{"type":"trip","connectedAt":1756900000000,'
            '"disconnectedAt":1756901500000,"durationMin":25,'
            '"counted":true,"notified":true,"overdueCount":2,"note":"ok"}',
      };
      final BluetoothState s = await bridge.getBluetoothState();
      expect(s.connected, isTrue);
      expect(s.since, DateTime.fromMillisecondsSinceEpoch(1756900000000));
      expect(s.lastTrip!.durationMin, 25);
      expect(s.lastTrip!.counted, isTrue);
      expect(s.lastTrip!.notified, isTrue);
      expect(s.lastTrip!.overdueCount, 2);
      expect(s.lastTrip!.note, 'ok');
    });

    test('bozuk lastTrip JSON çökertmiyor', () async {
      fake.replies['getBluetoothState'] = <Object?, Object?>{
        'connected': false,
        'lastTrip': 'bozuk',
      };
      expect((await bridge.getBluetoothState()).lastTrip, isNull);
    });

    test('cevap yoksa unknown', () async {
      expect(await bridge.getBluetoothState(), BluetoothState.unknown);
    });
  });

  group('drainPendingEvents', () {
    test('boşken boş liste', () async {
      fake.replies['drainPendingEvents'] = '[]';
      expect(await bridge.drainPendingEvents(), isEmpty);
    });

    test('cevap gelmezse boş liste', () async {
      expect(await bridge.drainPendingEvents(), isEmpty);
    });

    test('trip, snooze ve fallback ayrıştırılıyor', () async {
      fake.replies['drainPendingEvents'] =
          '['
          '{"type":"trip","connectedAt":1756900000000,'
          '"disconnectedAt":1756901500000,"durationMin":25,"counted":true,'
          '"notified":true,"overdueCount":2,"note":"ok"},'
          '{"type":"snooze","untilDay":"2026-09-04"},'
          '{"type":"fallback","at":1756990800000,"overdueCount":1}'
          ']';
      final List<PendingEvent> events = await bridge.drainPendingEvents();
      expect(events.length, 3);

      final TripEvent trip = events[0] as TripEvent;
      expect(trip.durationMin, 25);
      expect(trip.counted, isTrue);
      expect(trip.overdueCount, 2);
      expect(trip.note, 'ok');
      expect(
        trip.connectedAt,
        DateTime.fromMillisecondsSinceEpoch(1756900000000),
      );

      expect((events[1] as SnoozeEvent).untilDay, '2026-09-04');
      expect((events[2] as FallbackEvent).overdueCount, 1);
    });

    test('connectedAt null olan trip (bilinmeyen bağlantı)', () async {
      fake.replies['drainPendingEvents'] =
          '[{"type":"trip","connectedAt":null,"disconnectedAt":1756901500000,'
          '"durationMin":0,"counted":false,"notified":false,'
          '"overdueCount":0,"note":"short_trip"}]';
      final TripEvent trip =
          (await bridge.drainPendingEvents()).single as TripEvent;
      expect(trip.connectedAt, isNull);
      expect(trip.durationMin, 0);
      expect(trip.counted, isFalse);
      expect(trip.note, 'short_trip');
    });

    test('bilinmeyen tip atlanıyor, bozuk JSON boş liste', () async {
      fake.replies['drainPendingEvents'] =
          '[{"type":"uydurma"},{"type":"snooze","untilDay":"2026-09-04"}]';
      expect((await bridge.drainPendingEvents()).length, 1);

      fake.replies['drainPendingEvents'] = 'bozuk';
      expect(await bridge.drainPendingEvents(), isEmpty);
    });
  });

  group('yaşam döngüsü', () {
    test('getLaunchAction', () async {
      fake.replies['getLaunchAction'] = 'overdue';
      expect(await bridge.getLaunchAction(), 'overdue');
    });

    test('scheduleDailyWorker, cancelNotification, clearEngine', () async {
      await bridge.scheduleDailyWorker();
      await bridge.cancelNotification();
      await bridge.clearEngine();
      expect(fake.calls.map((MethodCall c) => c.method).toList(), <String>[
        'scheduleDailyWorker',
        'cancelNotification',
        'clearEngine',
      ]);
    });

    test('getSdkInt ve getManufacturer', () async {
      fake.replies['getSdkInt'] = 36;
      fake.replies['getManufacturer'] = 'Xiaomi';
      expect(await bridge.getSdkInt(), 36);
      expect(await bridge.getManufacturer(), 'Xiaomi');
    });
  });

  group('onLaunchAction (Kotlin → Dart)', () {
    test('handler çağrılıyor', () async {
      final List<String> received = <String>[];
      bridge.setLaunchActionHandler(received.add);

      await TestDefaultBinaryMessengerBinding
          .instance
          .defaultBinaryMessenger
          .handlePlatformMessage(
            fake.channel.name,
            fake.channel.codec.encodeMethodCall(
              const MethodCall('onLaunchAction', 'overdue'),
            ),
            (_) {},
          );

      expect(received, <String>['overdue']);
      bridge.clearLaunchActionHandler();
    });

    test('boş veya tanınmayan çağrı yok sayılıyor', () async {
      final List<String> received = <String>[];
      bridge.setLaunchActionHandler(received.add);

      await TestDefaultBinaryMessengerBinding
          .instance
          .defaultBinaryMessenger
          .handlePlatformMessage(
            fake.channel.name,
            fake.channel.codec.encodeMethodCall(
              const MethodCall('baskaBirSey', 'x'),
            ),
            (_) {},
          );

      expect(received, isEmpty);
      bridge.clearLaunchActionHandler();
    });
  });
}
