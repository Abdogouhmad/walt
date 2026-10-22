import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:walt_ui/walt_ui.dart';

void main() {
  group('chart series harmonisation', () {
    test('a category keeps most of its own colour when harmonised', () {
      // The user picked that colour. Pulling it all the way to the palette
      // would make every category identical and make the picker pointless.
      final scheme = AppColorSchemes.forPalette(
        WaltPalette.emerald,
        brightness: Brightness.light,
      );
      final charts = WaltChartColors.fromScheme(scheme);
      const own = Color(0xFF8E5CD9);

      final harmonized = charts.harmonizeCategory(own, 0);

      expect(harmonized, isNot(own));
      expect(ColorMath.deltaE(harmonized, own), greaterThan(5));
    });

    test('a category with no colour of its own takes the series colour', () {
      final scheme = AppColorSchemes.forPalette(
        WaltPalette.ocean,
        brightness: Brightness.light,
      );
      final charts = WaltChartColors.fromScheme(scheme);

      expect(charts.harmonizeCategory(null, 2), charts.at(2));
    });

    test('series slots wrap instead of running out', () {
      final scheme = AppColorSchemes.forPalette(
        WaltPalette.violet,
        brightness: Brightness.light,
      );
      final charts = WaltChartColors.fromScheme(scheme);

      expect(charts.at(0), charts.at(charts.categorical.length));
      expect(charts.at(9999), charts.at(9999 % charts.categorical.length));
    });
  });

  group('buildTheme', () {
    test('registers both theme extensions', () {
      final theme = buildTheme(ThemeSettings.defaults, Brightness.light);

      expect(theme.extension<WaltColors>(), isNotNull);
      expect(theme.extension<WaltChartColors>(), isNotNull);
    });

    test('different palettes produce different primaries', () {
      final primaries = {
        for (final palette in WaltPalette.values)
          buildTheme(
            ThemeSettings(palette: palette),
            Brightness.light,
          ).colorScheme.primary,
      };

      expect(primaries.length, WaltPalette.values.length);
    });

    test('a custom seed takes over from the palette', () {
      final theme = buildTheme(
        const ThemeSettings(
          palette: WaltPalette.emerald,
          customSeed: Color(0xFF8E5CD9),
        ),
        Brightness.light,
      );

      expect(
        theme.colorScheme.primary,
        AppColorSchemes.fromSeedColor(
          const Color(0xFF8E5CD9),
          Brightness.light,
        ).primary,
      );
    });

    test('the bundled font and both brightnesses share one builder', () {
      for (final brightness in Brightness.values) {
        final theme = buildTheme(ThemeSettings.defaults, brightness);

        expect(theme.textTheme.bodyLarge?.fontFamily, 'RobotoFlex');
        expect(theme.brightness, brightness);
        expect(theme.cardTheme.color, theme.colorScheme.surfaceContainerLow);
      }
    });
  });
}
