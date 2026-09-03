import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings_tr.dart';
import '../../core/theme.dart';
import '../../providers.dart';

/// Ayarlar → Geliştirici (01-spec §3.7). Yalnız debug derlemede görünür;
/// kanal tarafı da `BuildConfig.DEBUG` ile korunuyor.
class DebugController {
  const DebugController(this._ref);

  final Ref _ref;

  Future<void> simulateDisconnect(
    BuildContext context, {
    required int minutes,
  }) => _simulate(context, event: 'disconnect', minutes: minutes);

  Future<void> simulateConnect(BuildContext context) =>
      _simulate(context, event: 'connect');

  Future<void> _simulate(
    BuildContext context, {
    required String event,
    int minutes = 0,
  }) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await _ref
          .read(platformBridgeProvider)
          .debugSimulate(event: event, minutes: minutes);
    } on PlatformException catch (e) {
      _toast(messenger, e.code == 'NO_CAR' ? S.debugNoCar : S.errGeneric);
      return;
    } on MissingPluginException {
      _toast(messenger, S.errGeneric);
      return;
    }
    // Tanı satırı ve chip motorun yeni durumunu göstersin.
    await _ref.read(bluetoothStateProvider.notifier).refresh();
    _toast(messenger, S.debugDone);
  }

  /// Kotlin'e yazılmış snapshot'ı olduğu gibi gösterir.
  Future<void> showSnapshot(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    String? json;
    try {
      json = await _ref.read(platformBridgeProvider).readSnapshot();
    } on Object {
      json = null;
    }
    if (!context.mounted) {
      return;
    }
    if (json == null || json.isEmpty) {
      _toast(messenger, S.debugSnapshotEmpty);
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        key: const Key('debug_snapshot_dialog'),
        title: const Text(S.debugShowSnapshot),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              json!,
              style: const TextStyle(fontSize: 11, color: AppColors.ink2),
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            key: const Key('debug_snapshot_close'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(S.close),
          ),
        ],
      ),
    );
  }

  void _toast(ScaffoldMessengerState messenger, String message) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

final Provider<DebugController> debugControllerProvider =
    Provider<DebugController>((Ref ref) => DebugController(ref));
