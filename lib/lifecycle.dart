/// Açılış ve `resume` işleri (02-mimari §10 adım 3–4 ve 7).
///
/// `providers.dart` çekirdek sağlayıcıları tutuyor; buradaki iş onları
/// sıralamak, o yüzden ayrı dosya (features'a bağımlılık yok).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/date_utils.dart';
import 'data/platform/platform_bridge.dart';
import 'domain/models/rules.dart';
import 'features/settings/settings_controller.dart';
import 'providers.dart';

/// Kotlin'in biriktirdiklerini DB'ye işler ve platform durumunu tazeler.
class AppLifecycle {
  AppLifecycle(this._ref);

  final Ref _ref;

  /// Yalnız test için: kaç kez drain edildi.
  int drainCount = 0;

  /// 01-spec §7.3. `drainPendingEvents` oku+sil tek çağrı olduğu için ikinci
  /// çağrı boş döner; olaylar bir kez işlenir.
  ///
  /// Kanal yoksa veya DB yazımı patlarsa sessiz geçer (01-spec §9): bir
  /// sonraki açılışta/`resume`'da yenileri gelir.
  Future<int> drainPendingEvents() async {
    drainCount++;
    final List<PendingEvent> events;
    try {
      events = await _ref.read(platformBridgeProvider).drainPendingEvents();
    } on Object {
      return 0;
    }
    if (events.isEmpty) {
      return 0;
    }
    try {
      return await _ref.read(tripRepoProvider).applyPendingEvents(events);
    } on Object {
      return 0;
    }
  }

  /// Bildirimden mi açıldı (02-mimari §10 adım 4). Okununca Kotlin temizler.
  Future<void> readLaunchAction() async {
    final String? action;
    try {
      action = await _ref.read(platformBridgeProvider).getLaunchAction();
    } on Object {
      return;
    }
    if (action == null || action.isEmpty) {
      return;
    }
    _ref.read(launchActionProvider.notifier).state = action;
    _ref.read(launchActionSeqProvider.notifier).state++;
  }

  /// 02-mimari §10 adım 5 (K-12). `REPLACE` olduğu için tekrar çağırmak
  /// zararsız; hedef saat bir sonraki 19:00.
  Future<void> scheduleDailyWorker() async {
    try {
      await _ref.read(platformBridgeProvider).scheduleDailyWorker();
    } on Object {
      // Kanal yoksa (test/masaüstü) sessiz.
    }
  }

  /// Gece yarısı geçişi: uygulama açık kalıp gün değiştiyse bütün vade
  /// hesapları eski güne göre kalırdı (02-mimari §9).
  void refreshToday() {
    final DateTime now = dateOnly(DateTime.now());
    if (!isSameDay(_ref.read(todayProvider), now)) {
      _ref.read(todayProvider.notifier).state = now;
    }
  }

  /// 02-mimari §10 adım 7.
  Future<void> onResume() async {
    // Önce gün: sonraki her hesap doğru güne göre yapılsın.
    refreshToday();
    await drainPendingEvents();
    await readLaunchAction();
    await _ref.read(bluetoothStateProvider.notifier).refresh();
    await _ref.read(permissionsProvider.notifier).refresh();
    await _syncMotionRule();
    // 01-spec §6: `resume` de bir snapshot tetikleyicisi.
    await _ref.read(snapshotSyncProvider).write();
  }

  /// K-30: yeniden başlatma ve "force stop" geçiş aboneliğini düşürüyor;
  /// kural açıkken her `resume`'da yeniden kuruluyor. İzin sistem
  /// ayarlarından geri alınmışsa kural da kapanıyor: motor o durumda
  /// doğrulamayı atlıyor, açık kalan anahtar yalan söylerdi.
  Future<void> _syncMotionRule() async {
    final Rules? rules = _ref.read(rulesProvider).valueOrNull;
    if (rules == null || !rules.requireMotion) {
      return;
    }
    if (await _ref.read(permissionsProvider.notifier).ensureMotion()) {
      return;
    }
    await _ref
        .read(settingsControllerProvider)
        .setRules(rules.copyWith(requireMotion: false));
  }
}

final Provider<AppLifecycle> appLifecycleProvider = Provider<AppLifecycle>(
  (Ref ref) => AppLifecycle(ref),
);
