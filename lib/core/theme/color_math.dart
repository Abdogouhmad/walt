import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Contrast maths, kept next to the theme so the palette that produces a colour
/// and the test that certifies it cannot disagree about how contrast is
/// measured.
abstract final class ColorMath {
  /// WCAG 2.1 relative luminance of [color].
  static double luminance(Color color) {
    double channel(double c) =>
        c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4) as double;

    return 0.2126 * channel(color.r) +
        0.7152 * channel(color.g) +
        0.0722 * channel(color.b);
  }

  /// WCAG 2.1 contrast ratio between [a] and [b], from 1.0 to 21.0.
  static double contrastRatio(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    final lighter = math.max(la, lb);
    final darker = math.min(la, lb);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Rotates [color]'s hue a fraction of the way toward [target]'s hue.
  ///
  /// This is `Color.harmonizeWith`, which the pinned SDK does not expose. Doing
  /// it in HSL is enough for a fixed-hue semantic accent: what has to survive
  /// harmonisation is the *meaning* (green = income, red = expense), so the
  /// amount is deliberately small and the hue is re-asserted afterwards.
  ///
  /// [amount] is clamped to `0..1`, where 0 leaves [color] untouched and 1
  /// adopts [target]'s hue exactly.
  static Color harmonize(Color color, Color target, double amount) {
    if (amount <= 0) return color;
    final t = amount.clamp(0.0, 1.0);
    if (t >= 1) return target;

    final source = HSLColor.fromColor(color);
    final anchor = HSLColor.fromColor(target);

    // Shortest path around the hue circle, so 350° never rotates the long way
    // through green.
    var delta = anchor.hue - source.hue;
    if (delta > 180) {
      delta -= 360;
    } else if (delta < -180) {
      delta += 360;
    }

    return source.withHue((source.hue + delta * t) % 360).toColor();
  }

  /// [color] lightened or darkened until it clears [minRatio] against
  /// [background] and is not a near-duplicate of anything in [avoid] — or, if
  /// no lightness in the ramp manages both, the best compromise.
  ///
  /// This is how a semantic accent is made legible: the *hue* is fixed by
  /// meaning, the *tone* is solved for the surface it lands on. That is why
  /// income stays readable on a dark OLED black and on a white sheet without
  /// either palette needing its own copy of the colour.
  ///
  /// [avoid] exists because legibility alone is not enough when solving a whole
  /// set at once. Two roles that both start too pale get pushed down the same
  /// ramp and can land on the same fill, which turns two chart series into one.
  /// Pass the colours already accepted and the walk steps past them.
  static Color ensureContrast(
    Color color,
    Color background, {
    double minRatio = 4.5,
    Iterable<Color> avoid = const <Color>[],
  }) {
    bool usable(Color candidate) {
      if (contrastRatio(candidate, background) < minRatio) return false;
      for (final used in avoid) {
        if (deltaE(used, candidate) < minSeparation) return false;
      }
      return true;
    }

    if (usable(color)) return color;

    final hsl = HSLColor.fromColor(color);
    final towardsDark = luminance(background) > 0.5;
    // Walk away from the background first, then past it, so the ramp stays
    // monotonic instead of sampling the same tones twice.
    final ramp = <double>[
      for (var step = 1; step <= 8; step++)
        towardsDark ? hsl.lightness - step * 0.09 : hsl.lightness + step * 0.09,
      for (var step = 1; step <= 4; step++)
        towardsDark ? hsl.lightness + step * 0.09 : hsl.lightness - step * 0.09,
    ];

    Color? best;
    var bestScore = _score(color, background, avoid, minRatio);
    for (final lightness in ramp) {
      if (lightness <= 0.02 || lightness >= 0.98) continue;
      final candidate = hsl.withLightness(lightness).toColor();
      if (usable(candidate)) return candidate;
      final score = _score(candidate, background, avoid, minRatio);
      if (score > bestScore) {
        best = candidate;
        bestScore = score;
      }
    }
    return best ?? color;
  }

  /// Smallest ΔE two generated series may sit apart.
  ///
  /// Far below the ~25 at which two colours read as unrelated, because the goal
  /// is only "not the same colour" — a chart wants nine series that look like
  /// one palette, not nine that look like a fruit bowl.
  static const double minSeparation = 8;

  /// Ranks a candidate when nothing fully acceptable exists: legibility first,
  /// separation as a tiebreak that never lets an illegible colour win outright.
  static double _score(
    Color candidate,
    Color background,
    Iterable<Color> avoid,
    double minRatio,
  ) {
    final legibility = (contrastRatio(candidate, background) / minRatio).clamp(
      0.0,
      2.0,
    );
    if (avoid.isEmpty) return legibility;

    var closest = double.infinity;
    for (final used in avoid) {
      closest = math.min(closest, deltaE(used, candidate));
    }
    return legibility * (closest / minSeparation).clamp(0.0, 1.0);
  }

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
  static double deltaE(Color a, Color b) {
    final labA = _toLab(a);
    final labB = _toLab(b);
    final dl = labA.$1 - labB.$1;
    final da = labA.$2 - labB.$2;
    final db = labA.$3 - labB.$3;
    return math.sqrt(dl * dl + da * da + db * db);
  }

  /// sRGB → linear-light RGB → CIE XYZ (D65) → CIE Lab.
  static (double, double, double) _toLab(Color color) {
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
}
