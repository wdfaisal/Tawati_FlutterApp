import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const primary = Color(0xFF044465);
  static const primaryLight = Color(0xFFE7F1F7);
  static const primaryDark = Color(0xFF033A57);
  static const surface = Color(0xFFF8FAFC);
  static const card = Colors.white;
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textHint = Color(0xFF94A3B8);
  static const border = Color(0xFFE2E8F0);
  static const error = Color(0xFFEF4444);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
}

class AppTheme {
  static ThemeData get light {
    return _base(Brightness.light, AppColors.primary);
  }

  static ThemeData get dark {
    return _base(Brightness.dark, AppColors.primary);
  }

  static ThemeData fromSeed(Color seed, {Brightness brightness = Brightness.light}) {
    return _base(brightness, seed);
  }

  static ThemeData _base(Brightness brightness, Color seed) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorSchemeSeed: seed,
      scaffoldBackgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemStatusBarContrastEnforced: false,
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
        titleTextStyle: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? const Color(0xFF1E293B) : AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? const Color(0xFF334155) : AppColors.border, width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', color: AppColors.textHint, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: seed,
          textStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        selectedItemColor: seed,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11),
      ),
      dividerTheme: DividerThemeData(color: isDark ? const Color(0xFF334155) : AppColors.border, thickness: 0.5, space: 1),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w500),
      ),
    );
  }
}
