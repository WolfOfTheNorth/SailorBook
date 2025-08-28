import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _primaryColor = Color(0xFF4F46E5);
  static const Color _accentColor = Color(0xFF10B981);
  
  // Light theme colors
  static const Color _lightBackground = Color(0xFFFFFFFF);
  static const Color _lightSurface = Color(0xFFF8FAFC);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightText = Color(0xFF1E293B);
  static const Color _lightTextSecondary = Color(0xFF64748B);
  
  // Dark theme colors
  static const Color _darkBackground = Color(0xFF0B1015);
  static const Color _darkSurface = Color(0xFF0F172A);
  static const Color _darkCard = Color(0xFF111827);
  static const Color _darkText = Color(0xFFE5E7EB);
  static const Color _darkTextSecondary = Color(0xFF94A3B8);

  static ThemeData get light => _buildTheme(
    brightness: Brightness.light,
    backgroundColor: _lightBackground,
    surfaceColor: _lightSurface,
    cardColor: _lightCard,
    textColor: _lightText,
    textSecondaryColor: _lightTextSecondary,
  );

  static ThemeData get dark => _buildTheme(
    brightness: Brightness.dark,
    backgroundColor: _darkBackground,
    surfaceColor: _darkSurface,
    cardColor: _darkCard,
    textColor: _darkText,
    textSecondaryColor: _darkTextSecondary,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color backgroundColor,
    required Color surfaceColor,
    required Color cardColor,
    required Color textColor,
    required Color textSecondaryColor,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: brightness,
      surface: surfaceColor,
      background: backgroundColor,
      onBackground: textColor,
      onSurface: textColor,
    );

    final textTheme = GoogleFonts.interTextTheme().apply(
      bodyColor: textColor,
      displayColor: textColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: backgroundColor,
      
      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Cards
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColor,
          side: const BorderSide(color: _primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      
      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: _primaryColor.withOpacity(0.2),
        labelStyle: textTheme.bodySmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      
      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: _primaryColor,
        inactiveTrackColor: textSecondaryColor.withOpacity(0.3),
        thumbColor: _primaryColor,
        overlayColor: _primaryColor.withOpacity(0.2),
        trackHeight: 4,
      ),
    );
  }
}