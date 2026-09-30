import 'package:flutter/material.dart';

/// Screen-proportional sizing, derived from a 375×812 reference window.
///
/// Only the scale-to-width helpers survive here. The `colorAppScheme` /
/// `textTheme` / `isDarkMode` accessors this used to carry are gone: they were
/// one indirection in front of `Theme.of(context)`, and every call site reads
/// better — and one build cheaper — saying so directly.
extension BuildContextExtension on BuildContext {
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
}
