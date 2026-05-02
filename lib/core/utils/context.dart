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

  /// Scale width based on design width (375).
  double w(double width) => (width / 375) * screenWidth;

  /// Scale height based on design height (812).
  double h(double height) => (height / 812) * screenHeight;

  /// Scale font size based on screen width.
  double sp(double fontSize) => (fontSize / 375) * screenWidth;

  /// Scale radius based on screen width.
  double r(double radius) => (radius / 375) * screenWidth;
}
