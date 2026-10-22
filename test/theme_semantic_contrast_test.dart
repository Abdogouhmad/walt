import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:walt_ui/walt_ui.dart';

import 'support/contrast.dart';

void main() {
  group('every palette × brightness — semantic accents', () {
    for (final palette in WaltPalette.values) {
      for (final brightness in Brightness.values) {
        final label = '${palette.name}/${brightness.name}';
        final scheme = AppColorSchemes.forPalette(
          palette,
          brightness: brightness,
        );
        final semantic = WaltColors.fromScheme(scheme);

        test('$label keeps income and expense legible and distinguishable', () {
          // Amounts are the one thing a user must never misread, so they clear
          // the graphics threshold on the surfaces they are drawn on.
          for (final background in <Color>[
            scheme.surface,
            scheme.surfaceContainer,
            scheme.surfaceContainerLow,
            scheme.surfaceContainerHigh,
          ]) {
            expectContrast(
              label,
              semantic.income,
              background,
              aaLargeTextOrGraphics,
              'income on ${background.toARGB32().toRadixString(16)}',
            );
            expectContrast(
              label,
              semantic.expense,
              background,
              aaLargeTextOrGraphics,
              'expense on ${background.toARGB32().toRadixString(16)}',
            );
          }
        });

        test('$label keeps income and expense semantically opposite', () {
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
}
