import 'package:flutter/material.dart';

import '../../../core/format_tr.dart';
import '../../../core/strings_tr.dart';
import '../../../core/theme.dart';
import '../../../domain/models/vehicle.dart';

/// Ana ekran başlığı: araç adı, km, "Km gir" ve Bluetooth chip'i
/// (01-spec §3.2).
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.vehicle,
    required this.chipText,
    required this.connected,
    required this.onKmTap,
    super.key,
  });

  final Vehicle vehicle;
  final String chipText;
  final bool connected;
  final VoidCallback onKmTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        10,
        AppSizes.screenPadding,
        18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            vehicle.displayName,
            style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                '${formatKm(vehicle.currentKm)} ${S.unitKm}',
                key: const Key('home_km'),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.68,
                  color: AppColors.ink,
                  fontFeatures: tabularFigures,
                ),
              ),
              const SizedBox(width: 14),
              TextButton(
                key: const Key('home_km_entry'),
                onPressed: onKmTap,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, AppSizes.minTapTarget),
                ),
                child: const Text(
                  S.kmEntryLink,
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _Chip(text: chipText, connected: connected),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.connected});

  final String text;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('home_chip'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: connected ? AppColors.greenBg : const Color(0xFFEAEDF1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.bluetooth,
            size: 14,
            color: connected ? AppColors.green : AppColors.ink2,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: connected ? AppColors.green : AppColors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}
