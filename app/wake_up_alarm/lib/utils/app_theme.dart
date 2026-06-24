// lib/utils/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF101012);
  static const Color surface = Color(0xFF18181C);
  static const Color surfaceElevated = Color(0xFF222228);
  static const Color accent = Color(0xFFB8C9D9);
  static const Color accentSecondary = Color(0xFF8FA3B8);
  static const Color danger = Color(0xFFE07A7A);
  static const Color success = Color(0xFF7BC4A4);
  static const Color textPrimary = Color(0xFFF4F4F6);
  static const Color textSecondary = Color(0xFF9A9AA3);
  static const Color textMuted = Color(0xFF5E5E68);
  static const Color border = Color(0xFF2E2E36);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: accent,
        secondary: accentSecondary,
        error: danger,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w300,
          color: textPrimary,
          letterSpacing: -1.5,
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textSecondary,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textSecondary, size: 22),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 0.5,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        hintStyle: const TextStyle(color: textMuted, fontSize: 16),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentSecondary, width: 1),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent.withValues(alpha: 0.25);
          }
          return border;
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: textPrimary,
          foregroundColor: background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: textPrimary,
        foregroundColor: background,
        elevation: 0,
        shape: CircleBorder(),
      ),
    );
  }
}

class AppConstants {
  static const List<Map<String, dynamic>> alarmItems = [
    {
      'name': 'Laptop',
      'emoji': '💻',
      'mlLabel': 'computer',
      'altLabels': <String>[],
    },
    {
      'name': 'Phone',
      'emoji': '📱',
      'mlLabel': 'mobile phone',
      'altLabels': <String>[],
    },
    {
      'name': 'Coffee Mug',
      'emoji': '☕',
      'mlLabel': 'cup',
      'altLabels': ['coffee', 'cappuccino'],
    },
    {
      'name': 'Chair',
      'emoji': '🪑',
      'mlLabel': 'chair',
      'altLabels': <String>[],
    },
    {
      'name': 'TV',
      'emoji': '📺',
      'mlLabel': 'television',
      'altLabels': <String>[],
    },
    {
      'name': 'Houseplant',
      'emoji': '🌱',
      'mlLabel': 'plant',
      'altLabels': ['flower', 'flowerpot'],
    },
    {
      'name': 'Glasses',
      'emoji': '👓',
      'mlLabel': 'glasses',
      'altLabels': ['sunglasses'],
    },
    {
      'name': 'Sneakers',
      'emoji': '👟',
      'mlLabel': 'shoe',
      'altLabels': ['sneakers'],
    },
    {
      'name': 'Bag',
      'emoji': '👜',
      'mlLabel': 'bag',
      'altLabels': ['handbag'],
    },
    {
      'name': 'Pillow',
      'emoji': '🛏️',
      'mlLabel': 'pillow',
      'altLabels': ['cushion'],
    },
  ];

  static const double detectionConfidenceThreshold = 0.40;
  static const int maxDetectionAttempts = 3;
}
