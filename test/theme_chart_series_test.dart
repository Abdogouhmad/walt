import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:walt_ui/walt_ui.dart';

import 'support/contrast.dart';

void main() {
  group('chart series', () {
    for (final palette in WaltPalette.values) {
      for (final brightness in Brightness.values) {
        final label = '${palette.name}/${brightness.name}';
        final charts = WaltChartColors.fromScheme(
          AppColorSchemes.forPalette(palette, brightness: brightness),
        );

        test('$label keeps adjacent series distinguishable', () {
          // A donut whose neighbouring slices collapse is the one place a
          // palette change destroys information rather than taste, so this is
          // checked per adjacent pair and not just across the whole list.
          final series = charts.categorical;
          for (var i = 0; i < series.length; i++) {
            // Modulo, because a donut wraps: the last wedge touches the first.
            final next = series[(i + 1) % series.length];
            final distance = ColorMath.deltaE(series[i], next);
            expect(
              distance,
              greaterThan(10),
              reason:
                  '$label: series $i and ${(i + 1) % series.length} are only '
                  'ΔE ${distance.toStringAsFixed(1)} apart',
            );
          }
        });

        test('$label never repeats a series colour outright', () {
          expect(
            charts.categorical.toSet().length,
            charts.categorical.length,
            reason: '$label: two slots resolved to the same colour',
          );
        });

        test('$label draws series on every surface role', () {
          final scheme = AppColorSchemes.forPalette(
            palette,
            brightness: brightness,
          );
          for (final color in charts.categorical) {
            expectContrast(
              label,
              color,
              scheme.surface,
              aaLargeTextOrGraphics,
              'series ${color.toARGB32().toRadixString(16)} on surface',
            );
          }
        });

        test('$label points positive and negative at the semantic accents', () {
          final scheme = AppColorSchemes.forPalette(
            palette,
            brightness: brightness,
          );
          final semantic = WaltColors.fromScheme(scheme);

          expect(charts.positive, semantic.income);
          expect(charts.negative, semantic.expense);
        });
      }
    }
  });
}
