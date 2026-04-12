import 'package:flutter/material.dart';
//import 'package:dynamic_color/dynamic_color.dart';

class AppTheme {
  // Your brand primary color
  static const Color brandColor = Color(0xFF1F2937);

  // Light Theme
  static ThemeData lightTheme(ColorScheme? dynamicLight) {
    final colorScheme =
        dynamicLight ??
        ColorScheme.fromSeed(
          seedColor: brandColor,
          brightness: Brightness.light,
        );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
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
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        elevation: 8,
      ),
    );
  }

  // Dark Theme
  static ThemeData darkTheme(ColorScheme? dynamicDark) {
    final colorScheme =
        dynamicDark ??
        ColorScheme.fromSeed(
          seedColor: brandColor,
          brightness: Brightness.dark,
        );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: Brightness.dark,
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
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        elevation: 8,
      ),
    );
  }

  // Helper to get theme based on system + dynamic color
  static ThemeData getTheme(
    Brightness brightness,
    ColorScheme? lightDynamic,
    ColorScheme? darkDynamic,
  ) {
    if (brightness == Brightness.light) {
      return lightTheme(lightDynamic);
    } else {
      return darkTheme(darkDynamic);
    }
  }
}
