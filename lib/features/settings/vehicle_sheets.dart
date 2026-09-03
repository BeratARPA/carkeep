import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format_tr.dart';
import '../../core/strings_tr.dart';
import '../../core/theme.dart';
import '../../domain/item_form.dart';
import '../../domain/models/vehicle.dart';
import '../../providers.dart';
import 'settings_controller.dart';

/// Ayarlar → Araç bölümünün üç alt sayfası (01-spec §3.7).

Future<void> showVehicleEditSheet(BuildContext context) {
  return _show(context, const _VehicleEditSheet());
}

Future<void> showKmFixSheet(BuildContext context) {
  return _show(context, const _KmFixSheet());
}

Future<void> showTireTargetSheet(BuildContext context) {
  return _show(context, const _TireTargetSheet());
}

Future<void> _show(BuildContext context, Widget child) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => child,
  );
}

/// Ortak kabuk: tutamak, başlık, içerik, Kaydet.
class _SheetShell extends StatelessWidget {
  const _SheetShell({
    required this.title,
    required this.children,
    required this.onSave,
    this.help,
    this.saveKey,
  });

  final String title;
  final String? help;
  final List<Widget> children;
  final VoidCallback onSave;
  final Key? saveKey;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
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
                  Text(title, style: text.titleLarge),
                  if (help != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(help!, style: text.bodyMedium),
                  ],
                  const SizedBox(height: 16),
                  ...children,
                  const SizedBox(height: 16),
                  ElevatedButton(
                    key: saveKey,
                    onPressed: onSave,
                    child: const Text(S.save),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.fieldKey,
    this.keyboardType,
    this.formatters,
  });

  final String label;
  final TextEditingController controller;
  final Key? fieldKey;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          TextField(
            key: fieldKey,
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: formatters,
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------- marka/model/yıl

class _VehicleEditSheet extends ConsumerStatefulWidget {
  const _VehicleEditSheet();

  @override
  ConsumerState<_VehicleEditSheet> createState() => _VehicleEditSheetState();
}

class _VehicleEditSheetState extends ConsumerState<_VehicleEditSheet> {
  late final Vehicle? _vehicle = ref.read(vehicleProvider).valueOrNull;
  late final TextEditingController _brand = TextEditingController(
    text: _vehicle?.brand ?? '',
  );
  late final TextEditingController _model = TextEditingController(
    text: _vehicle?.model ?? '',
  );
  late final TextEditingController _year = TextEditingController(
    text: _vehicle?.year ?? '',
  );

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final Vehicle? v = _vehicle;
    if (v == null) {
      return;
    }
    if (_brand.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text(S.errBrandRequired)));
      return;
    }
    await ref
        .read(settingsControllerProvider)
        .updateProfile(
          vehicleId: v.id,
          brand: _brand.text.trim(),
          model: _model.text.trim(),
          year: _year.text.trim(),
        );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: S.settingsVehicleEdit,
      saveKey: const Key('vehicle_edit_save'),
      onSave: _save,
      children: <Widget>[
        _Field(
          label: S.fieldBrand,
          controller: _brand,
          fieldKey: const Key('vehicle_brand'),
        ),
        _Field(
          label: S.fieldModel,
          controller: _model,
          fieldKey: const Key('vehicle_model'),
        ),
        _Field(
          label: S.fieldYear,
          controller: _year,
          fieldKey: const Key('vehicle_year'),
          keyboardType: TextInputType.number,
          formatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
        ),
      ],
    );
  }
}

// ------------------------------------------------------------- km düzelt

class _KmFixSheet extends ConsumerStatefulWidget {
  const _KmFixSheet();

  @override
  ConsumerState<_KmFixSheet> createState() => _KmFixSheetState();
}

class _KmFixSheetState extends ConsumerState<_KmFixSheet> {
  late final Vehicle? _vehicle = ref.read(vehicleProvider).valueOrNull;
  late final TextEditingController _km = _initial();

  TextEditingController _initial() {
    final String text = _vehicle?.currentKm.toString() ?? '';
    return TextEditingController.fromValue(
      TextEditingValue(
        text: text,
        selection: TextSelection(baseOffset: 0, extentOffset: text.length),
      ),
    );
  }

  @override
  void dispose() {
    _km.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final Vehicle? v = _vehicle;
    if (v == null) {
      return;
    }
    final int? km = parseKm(_km.text);
    if (km == null || km < 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text(S.errKmRequired)));
      return;
    }
    // 01-spec §3.7: her değere izin var, geriye alınıyorsa onay istenir.
    if (isKmGoingBack(current: v.currentKm, next: km)) {
      final bool? ok = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          content: const Text(S.settingsKmBackConfirm),
          actions: <Widget>[
            TextButton(
              key: const Key('km_back_cancel'),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(S.cancel),
            ),
            TextButton(
              key: const Key('km_back_confirm'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(S.save),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) {
        return;
      }
    }
    await ref.read(settingsControllerProvider).setCurrentKm(v.id, km);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(kmUpdatedText(km))));
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: S.settingsKmFix,
      saveKey: const Key('km_fix_save'),
      onSave: _save,
      children: <Widget>[
        _Field(
          label: S.fieldKm,
          controller: _km,
          fieldKey: const Key('km_fix_field'),
          keyboardType: TextInputType.number,
          formatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(7),
          ],
        ),
      ],
    );
  }
}

// ------------------------------------------------------- hedef basınçlar

/// Boş bırakılabilir; girildiyse 1,0–4,0 bar arası olmalı.
String? validateTargetBar(String raw) {
  if (raw.trim().isEmpty) {
    return null;
  }
  final double? bar = parseBar(raw);
  if (bar == null || bar < 1.0 || bar > 4.0) {
    return S.errBarInvalid;
  }
  return null;
}

class _TireTargetSheet extends ConsumerStatefulWidget {
  const _TireTargetSheet();

  @override
  ConsumerState<_TireTargetSheet> createState() => _TireTargetSheetState();
}

class _TireTargetSheetState extends ConsumerState<_TireTargetSheet> {
  late final Vehicle? _vehicle = ref.read(vehicleProvider).valueOrNull;
  late final TextEditingController _front = TextEditingController(
    text: _vehicle?.tireFrontBar == null
        ? ''
        : formatBar(_vehicle!.tireFrontBar!),
  );
  late final TextEditingController _rear = TextEditingController(
    text: _vehicle?.tireRearBar == null
        ? ''
        : formatBar(_vehicle!.tireRearBar!),
  );

  @override
  void dispose() {
    _front.dispose();
    _rear.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final Vehicle? v = _vehicle;
    if (v == null) {
      return;
    }
    final String? problem =
        validateTargetBar(_front.text) ?? validateTargetBar(_rear.text);
    if (problem != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(problem)));
      return;
    }
    await ref
        .read(settingsControllerProvider)
        .setTargetPressure(
          v.id,
          front: parseBar(_front.text),
          rear: parseBar(_rear.text),
        );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: S.settingsTireTargets,
      help: S.settingsTireTargetsHelp,
      saveKey: const Key('tire_target_save'),
      onSave: _save,
      children: <Widget>[
        _Field(
          label: S.settingsTireFront,
          controller: _front,
          fieldKey: const Key('tire_front_field'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        _Field(
          label: S.settingsTireRear,
          controller: _rear,
          fieldKey: const Key('tire_rear_field'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }
}
