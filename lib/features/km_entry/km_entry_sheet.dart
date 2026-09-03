import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format_tr.dart';
import '../../core/strings_tr.dart';
import '../../core/theme.dart';
import '../../domain/models/vehicle.dart';
import '../../providers.dart';

/// Km giriş alt sayfası (01-spec §3.5).
Future<void> showKmEntrySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => const KmEntrySheet(),
  );
}

/// Girilen km'yi doğrular. Geçerliyse null, değilse uyarı metni.
///
/// Küçültme burada reddedilir; km'yi geriye almak yalnız Ayarlar → Araç'tan
/// yapılır (01-spec §3.5, §3.7).
String? validateKmEntry(String raw, int currentKm) {
  final int? km = parseKm(raw);
  if (km == null || km < 0) {
    return S.errKmRequired;
  }
  if (km < currentKm) {
    return kmTooSmallText(currentKm);
  }
  return null;
}

class KmEntrySheet extends ConsumerStatefulWidget {
  const KmEntrySheet({super.key});

  @override
  ConsumerState<KmEntrySheet> createState() => _KmEntrySheetState();
}

class _KmEntrySheetState extends ConsumerState<KmEntrySheet> {
  /// Alan güncel km ile dolu açılır (01-spec §3.5) ve metin **seçili** gelir;
  /// aksi halde kullanıcı yazmaya başlayınca mevcut değerin sonuna ekliyor
  /// (cihaz testinde `118420` + `119950` → `1184201` çıktı).
  late final TextEditingController _controller = _initialController();

  TextEditingController _initialController() {
    final String initial =
        ref.read(vehicleProvider).valueOrNull?.currentKm.toString() ?? '';
    return TextEditingController.fromValue(
      TextEditingValue(
        text: initial,
        selection: TextSelection(
          baseOffset: 0,
          extentOffset: initial.length,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save(Vehicle vehicle) async {
    final String? problem = validateKmEntry(
      _controller.text,
      vehicle.currentKm,
    );
    if (problem != null) {
      _toast(problem);
      return;
    }
    final int km = parseKm(_controller.text)!;
    await ref.read(vehicleRepoProvider).setCurrentKm(vehicle.id, km);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    _toast(kmUpdatedText(km));
  }

  @override
  Widget build(BuildContext context) {
    final Vehicle? vehicle = ref.watch(vehicleProvider).valueOrNull;
    if (vehicle == null) {
      return const SizedBox.shrink();
    }
    final TextTheme text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSizes.screenPadding,
              0,
              AppSizes.screenPadding,
              18 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  S.kmEntryTitle,
                  key: const Key('km_entry_title'),
                  style: text.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(S.kmEntryHelp, style: text.bodyMedium),
                const SizedBox(height: 16),
                Text(S.fieldKm, style: text.labelMedium),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('km_entry_field'),
                  controller: _controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(7),
                  ],
                  onSubmitted: (_) => _save(vehicle),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  key: const Key('km_entry_save'),
                  onPressed: () => _save(vehicle),
                  child: const Text(S.save),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
