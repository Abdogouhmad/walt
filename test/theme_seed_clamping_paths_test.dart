import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:walt_ui/walt_ui.dart';

import 'support/contrast.dart';

void main() {
  group('custom seed clamping — through the real theme paths', () {
    test('the real theme path clamps, not just the helper', () {
      // The exhaustive sweep in `theme_seed_clamping_test.dart` proves
      // `clampForContrast` works. This proves it is *wired up* — a helper
      // nothing calls is a helper that does not help, and only a test through
      // the public entry point can tell.
      for (int hueStep = 0; hueStep < 360; hueStep += 30) {
        for (int satStep = 0; satStep <= 10; satStep += 5) {
          for (int lightStep = 0; lightStep <= 10; lightStep += 5) {
            final seed = HSLColor.fromAHSL(
              1,
              hueStep.toDouble(),
              satStep / 10,
              lightStep / 10,
            ).toColor();

            for (final brightness in Brightness.values) {
              final scheme = AppColorSchemes.of(
                ThemeSettings(customSeed: seed),
                brightness,
              );
              final ratio = ColorMath.contrastRatio(
                scheme.primary,
                scheme.onPrimary,
              );
              expect(
                ratio,
                greaterThanOrEqualTo(aaText),
                reason:
                    'seed $seed at $brightness produced ${ratio.toStringAsFixed(2)}:1 '
                    'through AppColorSchemes.of',
              );
            }
          }
        }
      }
    });

    test('the app theme path clamps too', () {
      // One level further out again, because `buildTheme` is what the widget
      // tree actually calls.
      for (int hue = 0; hue < 360; hue += 45) {
        for (final brightness in Brightness.values) {
          final theme = buildTheme(
            ThemeSettings(
              customSeed: HSLColor.fromAHSL(
                1,
                hue.toDouble(),
                0.95,
                0.5,
              ).toColor(),
            ),
            brightness,
          );
          final ratio = ColorMath.contrastRatio(
            theme.colorScheme.primary,
            theme.colorScheme.onPrimary,
          );
          expect(
            ratio,
            greaterThanOrEqualTo(aaText),
            reason:
                'hue $hue at $brightness gave ${ratio.toStringAsFixed(2)}:1',
          );
        }
      }
    });
  });
}
