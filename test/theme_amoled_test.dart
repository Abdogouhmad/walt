import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:walt_ui/walt_ui.dart';

import 'support/contrast.dart';

void main() {
  group('AMOLED', () {
    for (final palette in WaltPalette.values) {
      test('${palette.name} flattens only the surface ramp', () {
        final plain = AppColorSchemes.fromSeedColor(
          palette.seed,
          Brightness.dark,
        );
        final amoled = AppColorSchemes.of(
          ThemeSettings(palette: palette, amoled: true),
          Brightness.dark,
        );

        expect(amoled.surface, Colors.black);
        expect(amoled.surfaceContainerLowest, Colors.black);
        expect(amoled.surfaceContainerLow, const Color(0xFF0A0A0A));
        expect(amoled.surfaceContainer, const Color(0xFF111111));
        expect(amoled.surfaceContainerHigh, const Color(0xFF181818));
        expect(amoled.surfaceContainerHighest, const Color(0xFF202020));

        // Accents must not move: AMOLED is about how dark the app is, not what
        // the colours mean.
        expect(amoled.primary, plain.primary);
        expect(amoled.error, plain.error);
        expect(amoled.tertiary, plain.tertiary);
      });

      test('${palette.name} keeps text readable on pure black', () {
        final amoled = AppColorSchemes.of(
          const ThemeSettings(amoled: true).copyWith(palette: palette),
          Brightness.dark,
        );

        expectContrast(
          '${palette.name}/amoled',
          amoled.onSurface,
          amoled.surface,
          aaText,
          'onSurface/surface',
        );
        expectContrast(
          '${palette.name}/amoled',
          amoled.onSurface,
          amoled.surfaceContainerHighest,
          aaText,
          'onSurface/surfaceContainerHighest',
        );

        // The semantic accents are solved against `surfaceContainer`, which
        // under AMOLED is #111111 — near enough to black that the light-mode
        // solution would fail. Re-check on the actual ramp.
        final semantic = WaltColors.fromScheme(amoled);
        expectContrast(
          '${palette.name}/amoled',
          semantic.income,
          amoled.surfaceContainerHighest,
          aaLargeTextOrGraphics,
          'income/surfaceContainerHighest',
        );
        expectContrast(
          '${palette.name}/amoled',
          semantic.expense,
          amoled.surfaceContainerHighest,
          aaLargeTextOrGraphics,
          'expense/surfaceContainerHighest',
        );
      });

      test('${palette.name} ignores AMOLED while light', () {
        final light = AppColorSchemes.of(
          const ThemeSettings(amoled: true).copyWith(palette: palette),
          Brightness.light,
        );
        final plain = AppColorSchemes.fromSeedColor(
          palette.seed,
          Brightness.light,
        );

        expect(light, plain);
      });
    }
  });
}
