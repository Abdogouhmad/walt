import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Perceptual distance between [a] and [b] in CIE Lab (CIE76 ΔE).
///
/// Contrast ratio is the wrong tool for asking "can you tell these two apart".
/// It only knows luminance, so a green and a red tuned to the same tone score
/// about 1.05:1 while looking obviously different — and two greys that are
/// *not* meaningfully different can score 1.4:1. Lab distance is the metric
/// that answers the question the chart palette actually has to answer: is
/// there enough colour between two series that a reader can tell them apart at
/// a glance?
///
/// Roughly: below 2.3 is "not distinguishable", 2.3–10 is a weak difference,
/// and above 25 two colours read as different colours.
double perceptualDeltaE(Color a, Color b) {
  final labA = toLab(a);
  final labB = toLab(b);
  final dl = labA.$1 - labB.$1;
  final da = labA.$2 - labB.$2;
  final db = labA.$3 - labB.$3;
  return math.sqrt(dl * dl + da * da + db * db);
}

/// sRGB → linear-light RGB → CIE XYZ (D65) → CIE Lab.
(double, double, double) toLab(Color color) {
  double linear(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4) as double;

  final r = linear(color.r);
  final g = linear(color.g);
  final b = linear(color.b);

  final x = (0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / 0.95047;
  final y = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b;
  final z = (0.0193339 * r + 0.1191920 * g + 0.9503041 * b) / 1.08883;

  double f(double t) =>
      t > 0.008856 ? math.pow(t, 1 / 3) as double : (7.787 * t) + (16 / 116);

  final fx = f(x);
  final fy = f(y);
  final fz = f(z);

  return (116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz));
}
