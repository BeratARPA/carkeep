import 'package:flutter/material.dart';

import '../../../core/strings_tr.dart';
import '../../../core/theme.dart';
import '../home_controller.dart';

/// Uyarı şeridi (01-spec §3.2). Dokununca ilgili aksiyonu açar; yalnız pil
/// şeridi kapatılabilir ve kapatılınca bir daha gösterilmez.
class WarningBanner extends StatelessWidget {
  const WarningBanner({
    required this.banner,
    required this.onTap,
    this.onDismiss,
    super.key,
  });

  final HomeBanner banner;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.amberBg,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppSizes.minTapTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenPadding,
            vertical: 10,
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: AppColors.amber,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  bannerText(banner),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  key: const Key('banner_dismiss'),
                  onPressed: onDismiss,
                  iconSize: 18,
                  color: AppColors.amber,
                  tooltip: S.bannerDismiss,
                  constraints: const BoxConstraints(
                    minWidth: AppSizes.minTapTarget,
                    minHeight: AppSizes.minTapTarget,
                  ),
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
