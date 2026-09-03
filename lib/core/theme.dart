/// Görsel dil (01-spec §10). Material 3, tek (açık) tema; karanlık tema v1'de yok.
library;

import 'package:flutter/material.dart';

/// Mockup'taki renk token'ları (01-spec §10).
abstract final class AppColors {
  static const Color ink = Color(0xFF141A24);
  static const Color ink2 = Color(0xFF4A5361);
  static const Color ink3 = Color(0xFF8A93A0);

  static const Color screen = Color(0xFFF6F7F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color line = Color(0xFFE1E5EA);

  static const Color red = Color(0xFFC4301C);
  static const Color redBg = Color(0xFFFBEBE8);

  static const Color amber = Color(0xFFA66300);
  static const Color amberBg = Color(0xFFFFF3DC);

  static const Color green = Color(0xFF1E7A45);
  static const Color greenBg = Color(0xFFE4F3EA);

  static const Color focus = Color(0xFF1A55C8);
}

/// Ölçüler.
abstract final class AppSizes {
  static const double buttonHeight = 48;
  static const double buttonRadius = 12;
  static const double fieldHeight = 48;
  static const double fieldRadius = 10;
  static const double sheetRadius = 24;

  /// Erişilebilirlik: en küçük dokunma alanı (T16).
  static const double minTapTarget = 48;

  static const double screenPadding = 20;

  /// Gecikmiş satırdaki sol kırmızı çizgi.
  static const double overdueBarWidth = 3;
}

const String _fontFamily = 'Manrope';

/// Sayılarda tabular rakam (01-spec §10).
const List<FontFeature> tabularFigures = <FontFeature>[
  FontFeature.tabularFigures(),
];

ThemeData buildCarKeepTheme() {
  const ColorScheme scheme = ColorScheme.light(
    primary: AppColors.ink,
    onPrimary: Colors.white,
    secondary: AppColors.ink2,
    onSecondary: Colors.white,
    error: AppColors.red,
    onError: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    outline: AppColors.line,
  );

  const TextTheme text = TextTheme(
    // Kurulum başlıkları
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.24,
      color: AppColors.ink,
    ),
    // Alt sayfa başlıkları
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.2,
      color: AppColors.ink,
    ),
    // Liste satırı başlığı
    titleMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    ),
    // Bölüm başlığı
    titleSmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColors.ink2,
    ),
    // Gövde metni
    bodyLarge: TextStyle(fontSize: 15, color: AppColors.ink),
    bodyMedium: TextStyle(fontSize: 14, color: AppColors.ink2),
    // Satır altı, yardım metni, durum metni
    bodySmall: TextStyle(fontSize: 12.5, color: AppColors.ink2),
    labelLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    ),
    labelMedium: TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: AppColors.ink2,
    ),
    labelSmall: TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      color: AppColors.ink3,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: _fontFamily,
    scaffoldBackgroundColor: AppColors.screen,
    canvasColor: AppColors.surface,
    dividerColor: AppColors.line,
    textTheme: text,
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.ink.withValues(alpha: 0.4),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
        elevation: 0,
        textStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppSizes.buttonRadius),
          ),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size(0, AppSizes.minTapTarget),
        textStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.fieldRadius)),
        borderSide: BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.fieldRadius)),
        borderSide: BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.fieldRadius)),
        borderSide: BorderSide(color: AppColors.focus, width: 2),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.ink,
      unselectedItemColor: AppColors.ink3,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.sheetRadius),
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: TextStyle(
        fontFamily: _fontFamily,
        color: Colors.white,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.buttonRadius)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll<Color>(Colors.white),
      trackColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) => states.contains(WidgetState.selected)
            ? AppColors.ink
            : const Color(0xFFCCD2DA),
      ),
      trackOutlineColor: const WidgetStatePropertyAll<Color>(
        Colors.transparent,
      ),
    ),
  );
}
