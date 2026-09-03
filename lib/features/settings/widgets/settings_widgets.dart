import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// Ayarlar ekranının ortak satır ve bölüm kabukları (01-spec §3.7, §10).
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    required this.title,
    required this.children,
    this.help,
    super.key,
  });

  final String title;
  final String? help;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenPadding,
            24,
            AppSizes.screenPadding,
            8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: text.titleSmall),
              if (help != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(help!, style: text.bodySmall),
              ],
            ],
          ),
        ),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border.symmetric(
              horizontal: BorderSide(color: AppColors.line),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}

/// Başlık + değer, isteğe bağlı dokunma.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.title,
    this.value,
    this.help,
    this.onTap,
    this.trailing,
    this.danger = false,
    super.key,
  });

  final String title;
  final String? value;
  final String? help;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// "Verileri sıfırla" gibi geri dönüşü olmayan satırlar kırmızı.
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Widget content = Container(
      constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenPadding,
        vertical: 12,
      ),
      child: Row(
        children: <Widget>[
          // Değer uzun olabiliyor (cihaz adı 25+ karakter): başlık gevşek,
          // değer sıkı ve sağa yaslı; böylece uzun değer sarmalanacak yer
          // bulur, kısa değer sağ kenarda kalır.
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  title,
                  style: text.titleMedium?.copyWith(
                    color: danger ? AppColors.red : AppColors.ink,
                  ),
                ),
                if (help != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(help!, style: text.bodySmall),
                ],
              ],
            ),
          ),
          if (value != null) ...<Widget>[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value!,
                textAlign: TextAlign.end,
                style: text.bodyMedium,
              ),
            ),
          ] else
            const Spacer(),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );

    return _Divided(
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

/// Aç/kapat satırı.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.help,
    super.key,
  });

  final String title;
  final String? help;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return _Divided(
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
        padding: const EdgeInsets.fromLTRB(AppSizes.screenPadding, 10, 12, 10),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(title, style: text.titleMedium),
                  if (help != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(help!, style: text.bodySmall),
                  ],
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// − değer + biçiminde adımlayıcı satırı.
class SettingsStepperRow extends StatelessWidget {
  const SettingsStepperRow({
    required this.title,
    required this.valueText,
    required this.onDecrease,
    required this.onIncrease,
    required this.decreaseLabel,
    required this.increaseLabel,
    this.help,
    this.onTap,
    this.decreaseKey,
    this.increaseKey,
    super.key,
  });

  final String title;
  final String? help;
  final String valueText;

  /// null → o yönde durak kalmadı, buton pasif.
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final String decreaseLabel;
  final String increaseLabel;
  final VoidCallback? onTap;
  final Key? decreaseKey;
  final Key? increaseKey;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Widget content = Container(
      constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
      padding: const EdgeInsets.fromLTRB(AppSizes.screenPadding, 8, 8, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(title, style: text.titleMedium),
                if (help != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(help!, style: text.bodySmall),
                ],
              ],
            ),
          ),
          _StepButton(
            key: decreaseKey,
            icon: Icons.remove,
            tooltip: decreaseLabel,
            onPressed: onDecrease,
          ),
          SizedBox(
            width: 92,
            child: Text(
              valueText,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                fontFeatures: tabularFigures,
                color: AppColors.ink,
              ),
            ),
          ),
          _StepButton(
            key: increaseKey,
            icon: Icons.add,
            tooltip: increaseLabel,
            onPressed: onIncrease,
          ),
        ],
      ),
    );

    return _Divided(
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints(
        minWidth: AppSizes.minTapTarget,
        minHeight: AppSizes.minTapTarget,
      ),
      style: IconButton.styleFrom(
        foregroundColor: AppColors.ink,
        disabledForegroundColor: AppColors.line,
      ),
    );
  }
}

class _Divided extends StatelessWidget {
  const _Divided({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: child,
    );
  }
}
