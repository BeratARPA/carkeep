import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings_tr.dart';
import '../../core/theme.dart';
import '../../data/platform/platform_bridge.dart';
import '../../domain/item_grouping.dart';
import '../../domain/models/item_status.dart';
import '../../domain/models/vehicle.dart';
import '../../providers.dart';
import 'home_controller.dart';
import 'widgets/home_header.dart';
import 'widgets/item_row.dart';
import 'widgets/warning_banner.dart';

/// Kontroller ekranı (01-spec §3.2).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Uyarı şeritleri buna bakıyor; `resume`'da da tazelenecek (T15).
      ref.read(permissionsProvider.notifier).refresh();
      ref.read(bluetoothStateProvider.notifier).refresh();
    });
  }

  Future<void> _onBannerTap(HomeBanner banner) async {
    final PlatformBridge bridge = ref.read(platformBridgeProvider);
    switch (banner) {
      case HomeBanner.noBluetooth:
        await bridge.requestBluetoothPermission();
        await ref.read(permissionsProvider.notifier).refresh();
      case HomeBanner.noNotification:
        await bridge.requestNotificationPermission();
        await ref.read(permissionsProvider.notifier).refresh();
      case HomeBanner.battery:
        await bridge.openBatteryOptimizationSettings();
      case HomeBanner.noDevice:
        // Cihaz seçici T11'de Ayarlar altında; şerit oraya götürür.
        ref.read(homeTabProvider.notifier).select(HomeTab.settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Vehicle? vehicle = ref.watch(vehicleProvider).valueOrNull;
    final GroupedItems grouped = ref.watch(groupedItemsProvider);
    final List<HomeBanner> banners = ref.watch(homeBannersProvider);
    final BluetoothState bt = ref.watch(bluetoothStateProvider);
    final int refYear = ref.watch(todayProvider).year;
    final String? launchAction = ref.watch(launchActionProvider);
    final bool highlightOverdue = launchAction == 'overdue';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            if (vehicle != null)
              HomeHeader(
                vehicle: vehicle,
                connected: bt.connected,
                chipText: bluetoothChipText(
                  deviceName: vehicle.btName,
                  connected: bt.connected,
                ),
                onKmTap: () {
                  // Km giriş alt sayfası T09'da.
                },
              ),
            for (final HomeBanner banner in banners)
              WarningBanner(
                key: Key('banner_${banner.name}'),
                banner: banner,
                onTap: () => _onBannerTap(banner),
                onDismiss: bannerDismissible(banner)
                    ? () =>
                          ref.read(batteryBannerDismissedProvider.notifier).dismiss()
                    : null,
              ),
            ..._sections(context, grouped, refYear, highlightOverdue),
          ],
        ),
      ),
    );
  }

  List<Widget> _sections(
    BuildContext context,
    GroupedItems grouped,
    int refYear,
    bool highlightOverdue,
  ) {
    final List<Widget> out = <Widget>[];

    void addSection(
      ItemState state,
      List<StatusedItem> items, {
      bool highlight = false,
    }) {
      if (items.isEmpty) {
        return;
      }
      final Widget block = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _SectionHeader(state: state, count: items.length),
          for (final StatusedItem e in items)
            ItemRow(
              key: Key('item_${e.item.id}'),
              entry: e,
              refYear: refYear,
              onTap: () {
                // Madde detayı T08'de.
              },
            ),
        ],
      );
      out.add(
        highlight
            ? _OverdueHighlight(key: const Key('overdue_highlight'), child: block)
            : block,
      );
    }

    addSection(
      ItemState.overdue,
      grouped.overdue,
      highlight: highlightOverdue && grouped.overdue.isNotEmpty,
    );
    addSection(ItemState.soon, grouped.soon);

    if (grouped.total == 0) {
      out.add(const _EmptyText(S.homeNoItems, key: Key('home_no_items')));
    } else if (grouped.nothingPending) {
      out.add(const _EmptyText(S.homeAllGood, key: Key('home_all_good')));
    }

    addSection(ItemState.ok, grouped.ok);
    addSection(ItemState.unknown, grouped.unknown);

    out.add(const SizedBox(height: 16));
    return out;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.state, required this.count});

  final ItemState state;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.screenPadding, 20, 20, 8),
      child: Text(
        sectionTitle(state, count),
        key: Key('section_${state.name}'),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: state == ItemState.overdue
              ? AppColors.red
              : state == ItemState.soon
              ? AppColors.amber
              : AppColors.ink2,
        ),
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

/// Bildirimden gelindiğinde Gecikmiş bölümü bir kez vurgulanır: arka plan
/// kırmızıdan beyaza sönümlenir (01-spec §3.2). Tek seferlik, süresiz
/// animasyon değil.
class _OverdueHighlight extends StatelessWidget {
  const _OverdueHighlight({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1, end: 0),
      duration: const Duration(milliseconds: 1200),
      builder: (BuildContext context, double t, Widget? inner) {
        return ColoredBox(
          color: Color.lerp(AppColors.surface, AppColors.redBg, t)!,
          child: inner,
        );
      },
      child: child,
    );
  }
}
