// lib/utils/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Deep dark with electric accent palette
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF13131A);
  static const Color surfaceElevated = Color(0xFF1C1C28);
  static const Color accent = Color(0xFF00E5FF);
  static const Color accentSecondary = Color(0xFF7B2FFF);
  static const Color danger = Color(0xFFFF3B5C);
  static const Color success = Color(0xFF00E096);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8A8A9A);
  static const Color textMuted = Color(0xFF4A4A5A);
  static const Color border = Color(0xFF2A2A3A);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        background: background,
        surface: surface,
        primary: accent,
        secondary: accentSecondary,
        error: danger,
      ),
      fontFamily: 'Courier',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -2,
        ),
        displayMedium: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -1.5,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textSecondary,
          letterSpacing: 0.2,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 1.5,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class AppConstants {
  // Items that ML Kit reliably detects
  // Labels must match ML Kit's object detection taxonomy
  static const List<Map<String, dynamic>> alarmItems = [
    {'name': 'Water Bottle', 'emoji': '🍶', 'mlLabel': 'bottle'},
    {'name': 'Coffee Mug', 'emoji': '☕', 'mlLabel': 'cup'},
    {'name': 'Book', 'emoji': '📖', 'mlLabel': 'book'},
    {'name': 'Laptop', 'emoji': '💻', 'mlLabel': 'laptop'},
    {'name': 'Plant', 'emoji': '🌱', 'mlLabel': 'plant'},
    {'name': 'Chair', 'emoji': '🪑', 'mlLabel': 'chair'},
    {'name': 'Shoes', 'emoji': '👟', 'mlLabel': 'footwear'},
    {'name': 'Glasses', 'emoji': '👓', 'mlLabel': 'glasses'},
    {'name': 'Bag', 'emoji': '👜', 'mlLabel': 'bag'},
    {'name': 'Pen', 'emoji': '🖊️', 'mlLabel': 'pen'},
    {'name': 'Watch', 'emoji': '⌚', 'mlLabel': 'watch'},
    {'name': 'Pillow', 'emoji': '🛏️', 'mlLabel': 'pillow'},
  ];

  static const double detectionConfidenceThreshold = 0.40;
  static const int maxDetectionAttempts = 3;
}
