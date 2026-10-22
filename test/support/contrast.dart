import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:walt_ui/walt_ui.dart';

/// WCAG 2.1 minimum contrast for body text.
const double aaText = 4.5;

/// WCAG 2.1 minimum contrast for large text and meaningful graphics.
const double aaLargeTextOrGraphics = 3.0;

/// Asserts that [foreground] drawn on [background] clears the WCAG AA
/// minimum of [minimum].
///
/// [label] identifies the palette/brightness pair under test and [pair] names
/// the two roles being compared, so a failure says which combination broke.
void expectContrast(
  String label,
  Color foreground,
  Color background,
  double minimum,
  String pair,
) {
  final ratio = ColorMath.contrastRatio(foreground, background);
  expect(
    ratio,
    greaterThanOrEqualTo(minimum),
    reason:
        '$label: $pair is ${ratio.toStringAsFixed(2)}:1 '
        '(fg ${foreground.toARGB32().toRadixString(16)}, '
        'bg ${background.toARGB32().toRadixString(16)}), needs '
        '${minimum.toStringAsFixed(1)}:1',
  );
}
