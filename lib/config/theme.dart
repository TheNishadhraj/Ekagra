import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Section A2 — Color System
class EkagraColors {
  EkagraColors._();

  // Primary — Warm, calming purple (not clinical blue)
  static const primary = Color(0xFF7C5CFC);
  static const primaryLight = Color(0xFFB8A9FC);
  static const primaryDark = Color(0xFF5A3FD6);

  // Background — Not pure white (reduces eye strain)
  static const background = Color(0xFFFAF8FF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceElevated = Color(0xFFF5F3FF);

  // Text — Softer than pure black
  static const textPrimary = Color(0xFF2D2B42);
  static const textSecondary = Color(0xFF6B6889);
  static const textTertiary = Color(0xFF9E9BB5);

  // Semantic — NO RED ANYWHERE (warm coral for error)
  static const success = Color(0xFF6BCB77);
  static const warning = Color(0xFFFFB84D);
  static const info = Color(0xFF5CB8FF);
  static const error = Color(0xFFFF8C6B); // Warm coral, NEVER red

  // Energy Colors
  static const energyHigh = Color(0xFFFFB84D);
  static const energyMedium = Color(0xFF6BCB77);
  static const energyLow = Color(0xFF5CB8FF);
  static const energyDrained = Color(0xFFD4D2E0);

  // Mood Colors
  static const moodGreat = Color(0xFF6BCB77);
  static const moodGood = Color(0xFF8DD88E);
  static const moodOkay = Color(0xFFFFB84D);
  static const moodLow = Color(0xFF5CB8FF);
  static const moodRough = Color(0xFFD4D2E0);

  // Focus Timer
  static const focusActive = Color(0xFF7C5CFC);
  static const focusPaused = Color(0xFFFFB84D);
  static const focusComplete = Color(0xFF6BCB77);

  // Reward Tiers
  static const rewardQuick = Color(0xFFFFD93D);
  static const rewardMedium = Color(0xFFFF8C6B);
  static const rewardBig = Color(0xFF7C5CFC);
}

// Backward compatibility alias

/// Section A2 — Dark Mode
class EkagraDarkColors {
  EkagraDarkColors._();

  static const background = Color(0xFF1A1825);
  static const surface = Color(0xFF252336);
  static const surfaceElevated = Color(0xFF2F2D42);
  static const textPrimary = Color(0xFFF0EEFF);
  static const textSecondary = Color(0xFF9E9BB5);
  static const primary = Color(0xFF9B85FC);
}


/// Section A3 — Typography (Inter via Google Fonts)
class EkagraTypography {
  EkagraTypography._();

  static TextStyle get h1 => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
        color: EkagraColors.textPrimary,
      );

  static TextStyle get h2 => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.3,
        color: EkagraColors.textPrimary,
      );

  static TextStyle get h3 => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: EkagraColors.textPrimary,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: EkagraColors.textPrimary,
      );

  static TextStyle get bodyBold => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: EkagraColors.textPrimary,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: EkagraColors.textSecondary,
      );

  static TextStyle get tiny => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: EkagraColors.textTertiary,
      );

  static TextStyle get encouragement => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: EkagraColors.textSecondary,
        fontStyle: FontStyle.italic,
      );
}


/// Section A4 — Spacing & Radius
class EkagraSpacing {
  EkagraSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double screen = 20;
}


class EkagraRadius {
  EkagraRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;
}


class EkagraTheme {
  EkagraTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: EkagraColors.primary,
        onPrimary: Colors.white,
        secondary: EkagraColors.primaryLight,
        surface: EkagraColors.surface,
        error: EkagraColors.error,
        onError: Colors.white,
        onSurface: EkagraColors.textPrimary,
      ),
      scaffoldBackgroundColor: EkagraColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: EkagraColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: EkagraTypography.h3,
        iconTheme: const IconThemeData(color: EkagraColors.textPrimary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: EkagraColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: EkagraColors.surface,
        selectedItemColor: EkagraColors.primary,
        unselectedItemColor: EkagraColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: EkagraColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EkagraRadius.lg),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: EkagraColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: EkagraSpacing.xl,
            vertical: EkagraSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EkagraRadius.lg),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: EkagraColors.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: EkagraColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EkagraRadius.lg),
          borderSide: BorderSide(
            color: EkagraColors.primaryLight.withValues(alpha: 0.4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EkagraRadius.lg),
          borderSide: BorderSide(
            color: EkagraColors.primaryLight.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EkagraRadius.lg),
          borderSide: const BorderSide(color: EkagraColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.all(EkagraSpacing.lg),
        hintStyle: EkagraTypography.body.copyWith(
          color: EkagraColors.textTertiary,
        ),
      ),
      dividerColor: EkagraColors.primaryLight.withValues(alpha: 0.2),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: EkagraColors.textPrimary,
        displayColor: EkagraColors.textPrimary,
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: EkagraDarkColors.primary,
        onPrimary: EkagraDarkColors.background,
        secondary: EkagraColors.primaryLight,
        surface: EkagraDarkColors.surface,
        error: EkagraColors.error,
        onError: Colors.white,
        onSurface: EkagraDarkColors.textPrimary,
      ),
      scaffoldBackgroundColor: EkagraDarkColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: EkagraDarkColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: EkagraTypography.h3.copyWith(
          color: EkagraDarkColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: EkagraDarkColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: EkagraDarkColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EkagraRadius.lg),
        ),
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: EkagraDarkColors.textPrimary,
        displayColor: EkagraDarkColors.textPrimary,
      ),
    );
  }
}

