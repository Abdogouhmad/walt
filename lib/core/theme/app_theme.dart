import 'package:flutter/material.dart';

class AppTheme {
  // Your brand primary color
  static const Color brandColor = Color(0xFF1F2937);

  // Light Theme
  static ThemeData lightTheme(ColorScheme? dynamicLight) {
    return _buildTheme(
      dynamicLight ??
          ColorScheme.fromSeed(
            seedColor: brandColor,
            brightness: Brightness.light,
          ),
    );
  }

  // Dark Theme
  static ThemeData darkTheme(ColorScheme? dynamicDark) {
    return _buildTheme(
      dynamicDark ??
          ColorScheme.fromSeed(
            seedColor: brandColor,
            brightness: Brightness.dark,
          ),
      dark: true,
    );
  }

  static ThemeData _buildTheme(ColorScheme colorScheme, {bool dark = false}) {
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: colorScheme.primaryContainer,
        elevation: 0,
      ),
    );
  }
}
