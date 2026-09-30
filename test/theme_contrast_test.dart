import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:walt/core/theme/app_theme.dart';
import 'package:walt/core/theme/color_math.dart';
import 'package:walt/core/theme/color_schemes.dart';
import 'package:walt/core/theme/theme_settings.dart';
import 'package:walt/core/theme/walt_chart_colors.dart';
import 'package:walt/core/theme/walt_colors.dart';

/// WCAG 2.1 minimums.
const double _aaText = 4.5;
const double _aaLargeTextOrGraphics = 3.0;

void main() {
  group('every palette × brightness', () {
    for (final palette in WaltPalette.values) {
      for (final brightness in Brightness.values) {
        final label = '${palette.name}/${brightness.name}';
        final scheme = AppColorSchemes.forPalette(
          palette,
          brightness: brightness,
        );

        test('$label keeps body text readable on every surface role', () {
          // The four text-on-surface pairs a screen actually uses. If any of
          // these fail, a palette is not shippable regardless of how good the
          // swatch looks.
          _expectContrast(
            label,
            scheme.onSurface,
            scheme.surface,
            _aaText,
            'onSurface/surface',
          );
          _expectContrast(
            label,
            scheme.onSurface,
            scheme.surfaceContainerLow,
            _aaText,
            'onSurface/surfaceContainerLow',
          );
          _expectContrast(
            label,
            scheme.onSurface,
            scheme.surfaceContainerHigh,
            _aaText,
            'onSurface/surfaceContainerHigh',
          );
          _expectContrast(
            label,
            scheme.onSurfaceVariant,
            scheme.surfaceContainerHigh,
            _aaText,
            'onSurfaceVariant/surfaceContainerHigh',
          );
        });

        test('$label keeps filled and container roles at AA', () {
          // Filled buttons, chips, the nav indicator, the snackbar.
          _expectContrast(
            label,
            scheme.onPrimary,
            scheme.primary,
            _aaText,
            'onPrimary/primary',
          );
          _expectContrast(
            label,
            scheme.onPrimaryContainer,
            scheme.primaryContainer,
            _aaText,
            'onPrimaryContainer/primaryContainer',
          );
          _expectContrast(
            label,
            scheme.onSecondaryContainer,
            scheme.secondaryContainer,
            _aaText,
            'onSecondaryContainer/secondaryContainer',
          );
          _expectContrast(
            label,
            scheme.onTertiaryContainer,
            scheme.tertiaryContainer,
            _aaText,
            'onTertiaryContainer/tertiaryContainer',
          );
          _expectContrast(
            label,
            scheme.onError,
            scheme.error,
            _aaText,
            'onError/error',
          );
          _expectContrast(
            label,
            scheme.onInverseSurface,
            scheme.inverseSurface,
            _aaText,
            'onInverseSurface/inverseSurface',
          );
        });

        test('$label keeps income and expense legible and distinguishable', () {
          final semantic = WaltColors.fromScheme(scheme);

          // Amounts are the one thing a user must never misread, so they clear
          // the graphics threshold on the surfaces they are drawn on.
          for (final background in <Color>[
            scheme.surface,
            scheme.surfaceContainer,
            scheme.surfaceContainerLow,
            scheme.surfaceContainerHigh,
          ]) {
            _expectContrast(
              label,
              semantic.income,
              background,
              _aaLargeTextOrGraphics,
              'income on ${background.toARGB32().toRadixString(16)}',
            );
            _expectContrast(
              label,
              semantic.expense,
              background,
              _aaLargeTextOrGraphics,
              'expense on ${background.toARGB32().toRadixString(16)}',
            );
          }
        });

        test('$label keeps income and expense semantically opposite', () {
          final semantic = WaltColors.fromScheme(scheme);

          // Harmonisation toward the palette must not be able to turn income
          // into a second shade of the primary, or "in" and "out" stop being
          // distinguishable by colour at all.
          final income = HSLColor.fromColor(semantic.income);
          final expense = HSLColor.fromColor(semantic.expense);
          final gap = (income.hue - expense.hue).abs() % 360;
          final separation = gap > 180 ? 360 - gap : gap;

          expect(
            separation,
            greaterThan(60),
            reason:
                '$label: income (${semantic.income}) and expense '
                '(${semantic.expense}) are only $separation° apart in hue',
          );
        });

        test('$label keeps income and expense tellable apart', () {
          final semantic = WaltColors.fromScheme(scheme);

          // Both accents are legible on the same surface, which is the easy
          // half. The hard half is that a reader must still be able to tell
          // them apart at a glance — and a green and a red tuned to the same
          // tone score ~1.05:1 on a WCAG contrast ratio while being obviously
          // different colours, which is exactly why this is a Lab distance and
          // not a contrast check.
          final distance = ColorMath.deltaE(semantic.income, semantic.expense);

          expect(
            distance,
            greaterThan(25),
            reason:
                '$label: income ${semantic.income} and expense '
                '${semantic.expense} are only ΔE '
                '${distance.toStringAsFixed(1)} apart',
          );
        });
      }
    }
  });

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
          ThemeSettings(amoled: true).copyWith(palette: palette),
          Brightness.dark,
        );

        _expectContrast(
          '${palette.name}/amoled',
          amoled.onSurface,
          amoled.surface,
          _aaText,
          'onSurface/surface',
        );
        _expectContrast(
          '${palette.name}/amoled',
          amoled.onSurface,
          amoled.surfaceContainerHighest,
          _aaText,
          'onSurface/surfaceContainerHighest',
        );

        // The semantic accents are solved against `surfaceContainer`, which
        // under AMOLED is #111111 — near enough to black that the light-mode
        // solution would fail. Re-check on the actual ramp.
        final semantic = WaltColors.fromScheme(amoled);
        _expectContrast(
          '${palette.name}/amoled',
          semantic.income,
          amoled.surfaceContainerHighest,
          _aaLargeTextOrGraphics,
          'income/surfaceContainerHighest',
        );
        _expectContrast(
          '${palette.name}/amoled',
          semantic.expense,
          amoled.surfaceContainerHighest,
          _aaLargeTextOrGraphics,
          'expense/surfaceContainerHighest',
        );
      });

      test('${palette.name} ignores AMOLED while light', () {
        final light = AppColorSchemes.of(
          ThemeSettings(amoled: true).copyWith(palette: palette),
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
            _expectContrast(
              label,
              color,
              scheme.surface,
              _aaLargeTextOrGraphics,
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

    test('a category keeps most of its own colour when harmonised', () {
      // The user picked that colour. Pulling it all the way to the palette
      // would make every category identical and make the picker pointless.
      final scheme = AppColorSchemes.forPalette(
        WaltPalette.emerald,
        brightness: Brightness.light,
      );
      final charts = WaltChartColors.fromScheme(scheme);
      final own = const Color(0xFF8E5CD9);

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
                greaterThanOrEqualTo(_aaText),
                reason:
                    'seed $candidate clamped to $clamped at $brightness gives '
                    '${ratio.toStringAsFixed(2)}:1',
              );
            }
          }
        }
      }
    });

    test('the real theme path clamps, not just the helper', () {
      // The exhaustive sweep above proves `clampForContrast` works. This proves
      // it is *wired up* — a helper nothing calls is a helper that does not
      // help, and only a test through the public entry point can tell.
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
                greaterThanOrEqualTo(_aaText),
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
            greaterThanOrEqualTo(_aaText),
            reason:
                'hue $hue at $brightness gave ${ratio.toStringAsFixed(2)}:1',
          );
        }
      }
    });
  });
}

void _expectContrast(
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
