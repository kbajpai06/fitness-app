import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Base
  static const background   = Color(0xFF0A0A0A);
  static const surface      = Color(0xFF141414);
  static const surfaceHigh  = Color(0xFF1E1E1E);
  static const border       = Color(0xFF2A2A2A);

  // Text
  static const textPrimary   = Color(0xFFF5F4F0);
  static const textSecondary = Color(0xFF8A8A8A);
  static const textMuted     = Color(0xFF4A4A4A);

  // Accent
  static const accent        = Color(0xFFC8F55A);  // electric lime
  static const accentDim     = Color(0xFF3D4A1A);  // muted lime for backgrounds

  // Status
  static const success       = Color(0xFF4CAF82);
  static const warning       = Color(0xFFE8A838);
  static const error         = Color(0xFFE85538);

  // Add to AppColors class:
  static const cardGlass     = Color(0x1AFFFFFF);  // white 10% opacity
  static const cardGlassBorder = Color(0x33FFFFFF); // white 20% opacity 
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        background: AppColors.background,
        surface:    AppColors.surface,
        primary:    AppColors.accent,
        onPrimary:  AppColors.background,
        onSurface:  AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(
        const TextTheme(
          displayLarge:  TextStyle(color: AppColors.textPrimary, fontSize: 48, fontWeight: FontWeight.w700, letterSpacing: -1.5),
          displayMedium: TextStyle(color: AppColors.textPrimary, fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -1.0),
          headlineLarge: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          headlineMedium:TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w600),
          titleLarge:    TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
          titleMedium:   TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
          bodyLarge:     TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w400),
          bodyMedium:    TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w400),
          bodySmall:     TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w400),
          labelLarge:    TextStyle(color: AppColors.background, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}