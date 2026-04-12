import 'package:flutter/material.dart';

extension BuildContextExtension on BuildContext {
  /// Easily access the ThemeData from the current BuildContext.
  ThemeData get theme => Theme.of(this);

  /// Easily access the ColorScheme from the current BuildContext.
  ColorScheme get colorAppScheme => Theme.of(this).colorScheme;

  /// Easily access the Brightness from the current BuildContext.
  Brightness get brightness => Theme.of(this).brightness;

  /// Check if the current theme is dark.
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Easily access the TextTheme from the current BuildContext.
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get the current screen width.
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get the current screen height.
  double get screenHeight => MediaQuery.of(this).size.height;
  // You can add more theme-related extensions here, e0.g., media query sizes:
  // Size get mediaQuerySize => MediaQuery.of(this).size;
  // double get screenWidth => MediaQuery.of(this).size.width;
  // double get screenHeight => MediaQuery.of(this).size.height;
}