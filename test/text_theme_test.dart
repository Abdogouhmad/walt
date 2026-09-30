import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walt/core/theme/text_theme.dart';

void main() {
  group('AppTextTheme', () {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.teal);
    final light = AppTextTheme.build(scheme);
    final dark = AppTextTheme.build(
      ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
    );

    test('every slot is bound to the bundled variable family', () {
      final slots = <TextStyle?>[
        light.displayLarge,
        light.displayMedium,
        light.displaySmall,
        light.headlineLarge,
        light.headlineMedium,
        light.headlineSmall,
        light.titleLarge,
        light.titleMedium,
        light.titleSmall,
        light.bodyLarge,
        light.bodyMedium,
        light.bodySmall,
        light.labelLarge,
        light.labelMedium,
        light.labelSmall,
      ];
      for (final style in slots) {
        expect(style, isNotNull);
        expect(
          style!.fontFamily,
          AppTextTheme.fontFamily,
          reason: 'a slot fell back to the platform default',
        );
      }
    });

    test('weight is driven by the wght axis, not just fontWeight', () {
      // `fontWeight` alone is a hint; `fontVariations` is what a variable font
      // actually honours, so both must be set or the axis stays at its default.
      expect(
        light.displayMedium!.fontVariations,
        contains(const FontVariation('wght', 700)),
      );
      expect(
        light.bodyMedium!.fontVariations,
        contains(const FontVariation('wght', 400)),
      );
      expect(light.displayMedium!.fontWeight, FontWeight.w700);
      expect(light.bodyMedium!.fontWeight, FontWeight.w400);
    });

    test('optical size tracks the rendered size, largest to smallest', () {
      double opsz(TextStyle? s) =>
          s!.fontVariations!.firstWhere((v) => v.axis == 'opsz').value;

      expect(opsz(light.displayLarge), greaterThan(opsz(light.displayMedium)));
      expect(opsz(light.displayMedium), greaterThan(opsz(light.titleMedium)));
      expect(opsz(light.titleMedium), greaterThan(opsz(light.bodyMedium)));
      expect(opsz(light.bodyMedium), greaterThan(opsz(light.labelSmall)));
    });

    test('the scale matches the spec table exactly', () {
      // Phase 6 pins size/weight per role. A silent drift here is invisible on
      // one screen and glaring when two screens disagree.
      void role(String name, TextStyle? s, double size, int weight) {
        expect(s!.fontSize, size, reason: '$name size');
        expect(
          s.fontVariations!.firstWhere((v) => v.axis == 'wght').value,
          weight.toDouble(),
          reason: '$name weight',
        );
        expect(
          s.fontVariations!.firstWhere((v) => v.axis == 'opsz').value,
          size,
          reason: '$name optical size must track its rendered size',
        );
      }

      role('displayMedium', light.displayMedium, 44, 700);
      role('displaySmall', light.displaySmall, 36, 700);
      role('headlineMedium', light.headlineMedium, 28, 600);
      role('headlineSmall', light.headlineSmall, 24, 600);
      role('titleLarge', light.titleLarge, 22, 600);
      role('titleMedium', light.titleMedium, 16, 600);
      role('bodyLarge', light.bodyLarge, 16, 400);
      role('bodyMedium', light.bodyMedium, 14, 400);
      role('labelLarge', light.labelLarge, 14, 600);
      role('labelMedium', light.labelMedium, 12, 500);
    });

    test('no role is below the 12pt floor', () {
      final smallest = [
        light.labelMedium,
        light.labelSmall,
        light.bodySmall,
      ].map((s) => s!.fontSize);
      for (final size in smallest) {
        expect(size, greaterThanOrEqualTo(12));
      }
    });

    test('the display tier is the heaviest and the body tier the quietest', () {
      double wght(TextStyle? s) =>
          s!.fontVariations!.firstWhere((v) => v.axis == 'wght').value;

      expect(wght(light.displayLarge), greaterThanOrEqualTo(700));
      expect(wght(light.bodyMedium), 400);
      expect(wght(light.bodySmall), 400);
    });

    test('display and headline tiers are tracked tighter than the body', () {
      // Negative tracking at large sizes is what stops big text from looking
      // airy and loose; the body must stay at its natural spacing.
      expect(light.displayLarge!.letterSpacing, lessThan(0));
      expect(light.headlineLarge!.letterSpacing, lessThan(0));
    });

    test('tabular figures are available for money', () {
      expect(AppTextTheme.tabular, isNotEmpty);
    });

    test('light and dark build the same scale', () {
      expect(dark.displayMedium!.fontFamily, light.displayMedium!.fontFamily);
      expect(
        dark.displayMedium!.fontVariations,
        light.displayMedium!.fontVariations,
      );
    });

    test('the wordmark is a tracked all-caps lockup', () {
      final mark = AppTextTheme.wordmark(light)!;
      expect(mark.fontWeight, FontWeight.w700);
      // Spec pins the lockup at +1.
      expect(mark.letterSpacing, 1);
      expect(mark.fontVariations, contains(const FontVariation('wght', 700)));
    });
  });
}
