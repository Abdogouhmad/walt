import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:walt/core/theme/color_math.dart';
import 'package:walt/core/theme/walt_colors.dart';

/// The colours charts are allowed to use.
///
/// Charts are the one place where a palette change is immediately visible as a
/// *loss of information* rather than as a change of taste: a donut whose slices
/// collapse into one hue stops identifying anything. So the series colours are
/// generated from the scheme rather than picked by hand — a fixed eight-colour
/// list would look identical across all nine palettes and would clash with four
/// of them.
@immutable
class WaltChartColors extends ThemeExtension<WaltChartColors> {
  /// Ordered series colours. Cycles when a chart has more series than entries.
  final List<Color> categorical;

  /// Fills for "money in" series.
  final Color positive;

  /// Fills for "money out" series.
  final Color negative;

  /// The empty track behind a value that has not happened yet.
  final Color track;

  /// Gridlines and axis furniture.
  final Color grid;

  const WaltChartColors({
    required this.categorical,
    required this.positive,
    required this.negative,
    required this.track,
    required this.grid,
  });

  /// The scheme's accent family, made legible on this scheme's surface and
  /// ordered so no two neighbouring series look alike.
  ///
  /// Both steps matter, and neither is something a hand-picked colour list can
  /// do. Tonal-spot hands out a `*Container` role that is deliberately a pale
  /// tint — fine as a chip background, invisible as a chart fill on a light
  /// surface. And the tone-shifted variants sit one small step from the accent
  /// they were derived from, so a naive order puts a wedge next to its own
  /// parent.
  factory WaltChartColors.fromScheme(ColorScheme scheme) {
    final semantic = WaltColors.fromScheme(scheme);
    final isDark = scheme.brightness == Brightness.dark;

    final primary = HSLColor.fromColor(scheme.primary);
    final secondary = HSLColor.fromColor(scheme.secondary);
    final tertiary = HSLColor.fromColor(scheme.tertiary);

    // Light surfaces need deeper fills and dark surfaces need lifted ones, so
    // the shifted variants move in opposite directions in the two modes.
    double shift(double value) =>
        (value + (isDark ? 0.16 : -0.12)).clamp(0.08, 0.92);

    // Shifted variants first, containers last: the order below is only a
    // starting set, but the accents have the most colour in them and so make
    // the best seeds for the legibility pass.
    final candidates = <Color>[
      scheme.primary,
      scheme.secondary,
      scheme.tertiary,
      primary.withLightness(shift(primary.lightness)).toColor(),
      secondary.withLightness(shift(secondary.lightness)).toColor(),
      tertiary.withLightness(shift(tertiary.lightness)).toColor(),
      scheme.primaryContainer,
      scheme.secondaryContainer,
      scheme.tertiaryContainer,
    ];

    // A slice has to be visible against the surface it is drawn on. 3:1 is the
    // WCAG non-text threshold, and the containers routinely arrive far below
    // it in light mode. Solving them one at a time, each told about the ones
    // already accepted, is what keeps two roles from both being pushed down the
    // same ramp onto the same fill.
    final legible = <Color>[];
    for (final candidate in candidates) {
      legible.add(
        ColorMath.ensureContrast(
          candidate,
          scheme.surface,
          minRatio: 3,
          avoid: legible,
        ),
      );
    }

    return WaltChartColors(
      categorical: spreadOut(legible),
      positive: semantic.income,
      negative: semantic.expense,
      track: scheme.surfaceContainerHighest,
      grid: scheme.outlineVariant,
    );
  }

  /// Reorders [colors] so the biggest perceptual gap sits between neighbours.
  ///
  /// A pie or donut is read by *adjacency* — the eye compares a wedge to the one
  /// touching it, and the list wraps, so the last and first are neighbours too.
  /// A greedy walk from a fixed start optimises the first `n - 1` gaps and says
  /// nothing about the closing one, so every start is tried and the order with
  /// the largest worst-case neighbour gap wins.
  static List<Color> spreadOut(List<Color> colors) {
    if (colors.length < 3) return List<Color>.unmodifiable(colors);

    List<Color>? best;
    var bestWorstGap = -1.0;

    for (var start = 0; start < colors.length; start++) {
      final remaining = List<Color>.of(colors)..removeAt(start);
      final order = <Color>[colors[start]];
      var worstGap = double.infinity;

      while (remaining.isNotEmpty) {
        final previous = order.last;
        var pick = 0;
        var pickDistance = -1.0;
        for (var i = 0; i < remaining.length; i++) {
          final distance = ColorMath.deltaE(previous, remaining[i]);
          if (distance > pickDistance) {
            pickDistance = distance;
            pick = i;
          }
        }
        worstGap = math.min(worstGap, pickDistance);
        order.add(remaining.removeAt(pick));
      }

      // The list wraps in a donut, so the closing gap counts too — and it is
      // the one gap the greedy walk never got to look at.
      worstGap = math.min(worstGap, ColorMath.deltaE(order.last, order.first));

      if (worstGap > bestWorstGap) {
        bestWorstGap = worstGap;
        best = order;
      }
    }

    return List<Color>.unmodifiable(best!);
  }

  /// The chart extension for [context], or a scheme-derived fallback.
  static WaltChartColors of(BuildContext context) =>
      Theme.of(context).extension<WaltChartColors>() ??
      WaltChartColors.fromScheme(Theme.of(context).colorScheme);

  /// The series colour for slot [index], wrapping around.
  Color at(int index) {
    if (categorical.isEmpty) return grid;
    return categorical[index % categorical.length];
  }

  /// Reconciles a category's own colour with the active palette.
  ///
  /// Categories store a colour the user picked when they created them, and a
  /// free palette of user-chosen colours can be a rainbow. Pulling each one
  /// most of the way toward [at]'s base keeps the set reading as one palette
  /// while still letting categories that share a colour be told apart by
  /// position and the breakdown list.
  Color harmonizeCategory(Color? tint, int index) {
    final base = at(index);
    if (tint == null) return base;
    return Color.lerp(base, tint, 0.72) ?? base;
  }

  @override
  WaltChartColors copyWith({
    List<Color>? categorical,
    Color? positive,
    Color? negative,
    Color? track,
    Color? grid,
  }) {
    return WaltChartColors(
      categorical: categorical ?? this.categorical,
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      track: track ?? this.track,
      grid: grid ?? this.grid,
    );
  }

  @override
  WaltChartColors lerp(ThemeExtension<WaltChartColors>? other, double t) {
    if (other is! WaltChartColors) return this;
    Color blend(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return WaltChartColors(
      categorical: <Color>[
        for (var i = 0; i < categorical.length; i++)
          blend(categorical[i], other.at(i)),
      ],
      positive: blend(positive, other.positive),
      negative: blend(negative, other.negative),
      track: blend(track, other.track),
      grid: blend(grid, other.grid),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WaltChartColors &&
      _listEquals(other.categorical, categorical) &&
      other.positive == positive &&
      other.negative == negative &&
      other.track == track &&
      other.grid == grid;

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(categorical), positive, negative, track, grid);

  static bool _listEquals(List<Color> a, List<Color> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
