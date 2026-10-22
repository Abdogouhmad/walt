import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:walt_ui/walt_ui.dart';

void main() {
  group('copyWith', () {
    test('leaves omitted fields alone', () {
      const original = ThemeSettings(
        palette: WaltPalette.rose,
        mode: ThemeMode.light,
        amoled: true,
        customSeed: Color(0xFFE25577),
      );

      final next = original.copyWith(amoled: false);

      expect(next.palette, WaltPalette.rose);
      expect(next.mode, ThemeMode.light);
      expect(next.amoled, isFalse);
      expect(next.customSeed, const Color(0xFFE25577));
    });

    test('an explicit null clears the custom seed', () {
      const original = ThemeSettings(customSeed: Color(0xFFE25577));

      expect(original.copyWith(customSeed: null).customSeed, isNull);
      // Omitting it entirely must *not* clear it — that asymmetry is the whole
      // reason copyWith needs a sentinel.
      expect(original.copyWith(amoled: true).customSeed, isNotNull);
    });

    test('setting a palette does not clear a custom seed on its own', () {
      // The controller decides that; copyWith stays a dumb value copy.
      const original = ThemeSettings(customSeed: Color(0xFFE25577));
      final next = original.copyWith(palette: WaltPalette.ocean);

      expect(next.palette, WaltPalette.ocean);
      expect(next.customSeed, isNotNull);
    });
  });

  group('equality', () {
    test('is by value', () {
      expect(
        const ThemeSettings(palette: WaltPalette.teal, amoled: true),
        const ThemeSettings(palette: WaltPalette.teal, amoled: true),
      );
      expect(
        const ThemeSettings(palette: WaltPalette.teal).hashCode,
        const ThemeSettings(palette: WaltPalette.teal).hashCode,
      );
    });

    test('distinguishes every field', () {
      const base = ThemeSettings();

      expect(base.copyWith(palette: WaltPalette.rose), isNot(base));
      expect(base.copyWith(mode: ThemeMode.dark), isNot(base));
      expect(base.copyWith(amoled: true), isNot(base));
      expect(base.copyWith(customSeed: const Color(0xFF000000)), isNot(base));
    });
  });

  group('seed resolution', () {
    test('a custom seed overrides the palette', () {
      const settings = ThemeSettings(
        palette: WaltPalette.emerald,
        customSeed: Color(0xFF00BCD4),
      );

      expect(settings.seedColor, const Color(0xFF00BCD4));
      expect(settings.isCustom, isTrue);
      expect(settings.label, 'Custom');
      // The palette is retained so clearing the custom seed returns the user to
      // where they were rather than to emerald.
      expect(settings.palette, WaltPalette.emerald);
    });

    test('without a custom seed the palette seed wins', () {
      for (final palette in WaltPalette.values) {
        expect(ThemeSettings(palette: palette).seedColor, palette.seed);
        expect(ThemeSettings(palette: palette).label, palette.label);
      }
    });
  });
}
