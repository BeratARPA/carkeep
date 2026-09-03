/// Gün / ay / yıl üçlüsü. `showDatePicker` ve `flutter_localizations`
/// kullanılmaz (K-21).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../strings_tr.dart';
import '../theme.dart';

/// Geçmiş bir tarih girmek için üç alanlı giriş. Bugünden ileri tarih
/// kabul edilmez; geçersiz girişte [onChanged] `null` alır.
class TrDateField extends StatefulWidget {
  const TrDateField({
    required this.value,
    required this.today,
    required this.onChanged,
    this.label,
    this.errorText,
    super.key,
  });

  final DateTime? value;

  /// Üst sınır (dahil). Yerel takvim günü.
  final DateTime today;

  /// Geçerli tarihte gün, geçersiz veya eksik girişte `null`.
  final ValueChanged<DateTime?> onChanged;

  final String? label;
  final String? errorText;

  @override
  State<TrDateField> createState() => _TrDateFieldState();
}

class _TrDateFieldState extends State<TrDateField> {
  late final TextEditingController _day;
  late final TextEditingController _year;
  int? _month;

  @override
  void initState() {
    super.initState();
    _day = TextEditingController(text: widget.value?.day.toString() ?? '');
    // Yıl gerçek bir değerle açılır. Önceden yalnız ipucuydu: kutu doluymuş
    // gibi görünüyor, alan boş kaldığı için "Tarih gir" hatası veriyordu ve
    // hangi alanın eksik olduğu anlaşılmıyordu (cihaz testi bulgusu).
    _year = TextEditingController(
      text: (widget.value?.year ?? widget.today.year).toString(),
    );
    _month = widget.value?.month;
  }

  @override
  void dispose() {
    _day.dispose();
    _year.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      parseTrDateParts(
        day: _day.text,
        month: _month,
        year: _year.text,
        today: widget.today,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.label != null) ...<Widget>[
          Text(widget.label!, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 3,
              child: TextField(
                key: const Key('date_day'),
                controller: _day,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                decoration: const InputDecoration(
                  hintText: S.dateDay,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
                onChanged: (_) => _emit(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              // Dar diyalogda "Tem" → "Te" kırpılıyordu: açılır kutu ok
              // simgesine ve varsayılan yatay boşluğa yer ayırıyor.
              flex: 5,
              child: DropdownButtonFormField<int>(
                key: const Key('date_month'),
                initialValue: _month,
                isExpanded: true,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
                hint: const Text(S.dateMonth),
                items: <DropdownMenuItem<int>>[
                  for (int m = 1; m <= 12; m++)
                    DropdownMenuItem<int>(
                      value: m,
                      child: Text(trMonthsShort[m]),
                    ),
                ],
                onChanged: (int? m) {
                  setState(() => _month = m);
                  _emit();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: TextField(
                key: const Key('date_year'),
                controller: _year,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
                onChanged: (_) => _emit(),
              ),
            ),
          ],
        ),
        if (widget.errorText != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.red),
          ),
        ],
      ],
    );
  }
}

/// Üç parçadan tarih kurar. Eksik, geçersiz veya [today]'den ileri ise `null`.
/// Ayrıştırma saf tutuldu ki widget testi olmadan da sınanabilsin.
DateTime? parseTrDateParts({
  required String day,
  required int? month,
  required String year,
  required DateTime today,
}) {
  final int? d = int.tryParse(day.trim());
  final int? y = int.tryParse(year.trim());
  if (d == null || month == null || y == null) {
    return null;
  }
  if (d < 1 || d > 31 || month < 1 || month > 12 || y < 1900) {
    return null;
  }
  final DateTime candidate = DateTime(y, month, d);
  // Taşmayı yakala: 31 Şub → 3 Mar.
  if (candidate.year != y || candidate.month != month || candidate.day != d) {
    return null;
  }
  if (candidate.isAfter(DateTime(today.year, today.month, today.day))) {
    return null;
  }
  return candidate;
}

/// Alanların hepsi boş mu (isteğe bağlı tarih için).
bool isTrDateEmpty({
  required String day,
  required int? month,
  required String year,
}) => day.trim().isEmpty && month == null && year.trim().isEmpty;
