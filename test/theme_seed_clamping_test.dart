import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:walt_ui/walt_ui.dart';

import 'support/contrast.dart';

void main() {
  group('custom seed clamping', () {
    test('a usable seed is returned untouched', () {
      expect(
        AppColorSchemes.clampForContrast(
          const Color(0xFF8E5CD9),
          Brightness.light,
        ),
        const Color(0xFF8E5CD9),
      );
    });

    test('the built-in palette seeds all pass unclamped', () {
      // If a palette seed ever needed clamping, the grid would be showing a
      // swatch the user cannot actually select.
      for (final palette in WaltPalette.values) {
        for (final brightness in Brightness.values) {
          expect(
            AppColorSchemes.clampForContrast(palette.seed, brightness),
            palette.seed,
            reason: '${palette.name}/$brightness seed had to be adjusted',
          );
        }
      }
    });

    test('no arbitrary seed produces an unreadable primary in either mode', () {
      // A user can pick any colour. None of them may be rejected outright, and
      // none of them may produce a scheme where the label on a filled button
      // cannot be read.
      for (int hueStep = 0; hueStep < 360; hueStep += 15) {
        for (int satStep = 0; satStep <= 10; satStep++) {
          for (int lightStep = 0; lightStep <= 10; lightStep++) {
            final candidate = HSLColor.fromAHSL(
              1,
              hueStep.toDouble(),
              satStep / 10,
              lightStep / 10,
            ).toColor();

            for (final brightness in Brightness.values) {
              final clamped = AppColorSchemes.clampForContrast(
                candidate,
                brightness,
              );
              final scheme = AppColorSchemes.fromSeedColor(clamped, brightness);
              final ratio = ColorMath.contrastRatio(
                scheme.primary,
                scheme.onPrimary,
              );
              expect(
                ratio,
                greaterThanOrEqualTo(aaText),
                reason:
                    'seed $candidate clamped to $clamped at $brightness gives '
                    '${ratio.toStringAsFixed(2)}:1',
              );
            }
          }
        }
      }
    });
  });
}
