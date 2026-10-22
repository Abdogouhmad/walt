import 'package:flutter/material.dart';

import './chart_series.dart';
import './chart_series_builder.dart';

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

  /// The chart colours for [scheme].
  factory WaltChartColors.fromScheme(ColorScheme scheme) =>
      buildChartColors(scheme);

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
      chartListEquals(other.categorical, categorical) &&
      other.positive == positive &&
      other.negative == negative &&
      other.track == track &&
      other.grid == grid;

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(categorical), positive, negative, track, grid);
}
