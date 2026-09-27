import 'package:flutter/material.dart';

/// ZapTV Palette based on:
/// --black: #050609ff
/// --almond-silk: #f5d0c5ff
/// --light-bronze: #d69f7eff
/// --clay-soil: #774936ff
/// --rich-mahogany: #3c0000ff
///
/// Design direction: Mostly black surfaces with tasteful palette accents.
class AppColors {
  AppColors._();

  // Core 5 palette colors
  static const Color black = Color(0xFF050609);
  static const Color almondSilk = Color(0xFFF5D0C5);
  static const Color lightBronze = Color(0xFFD69F7E);
  static const Color claySoil = Color(0xFF774936);
  static const Color richMahogany = Color(0xFF3C0000);

  // Surfaces: primarily black and ultra-dark tones
  static const Color bgDark = black;
  static const Color surfaceSidebar = black;
  static const Color surfaceCard = Color(0xFF0C0D12);
  static const Color surfaceCardFocused = Color(0xFF141622);
  static const Color surfaceElevated = Color(0xFF10121A);
  static const Color surfaceDialog = black;

  // Crisp hairline borders
  static const Color borderSubtle = Color(0xFF1A1C26);
  static const Color borderMedium = Color(0xFF262A38);
  static const Color borderHighlight = lightBronze;

  // Text variations
  static const Color textPrimary = almondSilk;
  static const Color textSecondary = Color(0xB8F5D0C5); // almondSilk ~72%
  static const Color textMuted = Color(0x99D69F7E); // lightBronze ~60%
  static const Color textDisabled = Color(0x80774936); // claySoil ~50%
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.lightBronze,
      onPrimary: AppColors.black,
      primaryContainer: Color(0xFF141622),
      onPrimaryContainer: AppColors.almondSilk,
      secondary: AppColors.claySoil,
      onSecondary: AppColors.almondSilk,
      secondaryContainer: Color(0xFF10121A),
      onSecondaryContainer: AppColors.almondSilk,
      tertiary: AppColors.richMahogany,
      onTertiary: AppColors.almondSilk,
      surface: AppColors.black,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: Color(0xFF10121A),
      outline: AppColors.borderSubtle,
      outlineVariant: AppColors.borderSubtle,
      error: Color(0xFFCF6679),
      onError: AppColors.black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.black,
      canvasColor: AppColors.black,
      cardTheme: const CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.black,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.lightBronze,
        linearTrackColor: Color(0xFF10121A),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.black,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.textPrimary),
        displayMedium: TextStyle(color: AppColors.textPrimary),
        displaySmall: TextStyle(color: AppColors.textPrimary),
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(color: AppColors.textSecondary),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
        bodySmall: TextStyle(color: AppColors.lightBronze),
        labelLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        labelMedium: TextStyle(color: AppColors.textSecondary),
        labelSmall: TextStyle(color: AppColors.lightBronze),
      ),
    );
  }
}
