import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:walt/core/theme/theme_settings.dart';
import 'package:walt/core/theme/walt_palette.dart';

void main() {
  group('ThemeSettings defaults', () {
    test('start on Emerald, follow the system, no AMOLED, no custom seed', () {
      const settings = ThemeSettings.defaults;

      expect(settings.palette, WaltPalette.emerald);
      expect(settings.mode, ThemeMode.system);
      expect(settings.amoled, isFalse);
      expect(settings.customSeed, isNull);
      expect(settings.isCustom, isFalse);
      expect(settings.seedColor, WaltPalette.emerald.seed);
    });

    test('WaltPalette.fallback is emerald, matching the launcher icon', () {
      expect(WaltPalette.fallback, WaltPalette.emerald);
      expect(WaltPalette.fromName(null), WaltPalette.emerald);
    });
  });

  group('serialization round trip', () {
    test('survives every field, custom seed included', () {
      const original = ThemeSettings(
        palette: WaltPalette.violet,
        mode: ThemeMode.dark,
        amoled: true,
        customSeed: Color(0xFF8E5CD9),
      );

      final restored = ThemeSettings.fromMap(original.toMap());

      expect(restored, original);
      expect(restored.palette, WaltPalette.violet);
      expect(restored.mode, ThemeMode.dark);
      expect(restored.amoled, isTrue);
      expect(restored.customSeed, const Color(0xFF8E5CD9));
    });

    test('a custom seed is stored as a 32-bit ARGB int', () {
      // Hive has no Color adapter, so the only storable form is the int. If
      // this ever changes, a saved custom colour silently becomes null.
      final map = const ThemeSettings(customSeed: Color(0xFF1B9E77)).toMap();

      expect(map[ThemeSettings.keyCustomSeed], isA<int>());
      expect(map[ThemeSettings.keyCustomSeed], 0xFF1B9E77);
    });

    test('an absent custom seed is stored as null, not dropped', () {
      final map = ThemeSettings.defaults.toMap();

      expect(map.containsKey(ThemeSettings.keyCustomSeed), isTrue);
      expect(map[ThemeSettings.keyCustomSeed], isNull);
    });
  });

  group('invalid stored values fall back', () {
    test('an unknown palette name falls back to emerald', () {
      // A palette can be renamed or removed in a later release; a stale name
      // must never crash the theme or blank the screen.
      final settings = ThemeSettings.fromMap({
        ThemeSettings.keyPalette: 'chartreuse',
        ThemeSettings.keyMode: 'dark',
      });

      expect(settings.palette, WaltPalette.emerald);
      // The rest of the map is still honoured — one bad key must not discard
      // the user's other choices.
      expect(settings.mode, ThemeMode.dark);
    });

    test('an unknown mode falls back to system', () {
      final settings = ThemeSettings.fromMap({ThemeSettings.keyMode: 'sepia'});

      expect(settings.mode, ThemeMode.system);
    });

    test('wrongly typed values fall back rather than throw', () {
      final settings = ThemeSettings.fromMap({
        ThemeSettings.keyPalette: 42,
        ThemeSettings.keyMode: <String>['light'],
        ThemeSettings.keyAmoled: 'yes',
        ThemeSettings.keyCustomSeed: <int>[1],
      });

      expect(settings, ThemeSettings.defaults);
    });

    test('a corrupt custom seed is dropped, the palette survives', () {
      final settings = ThemeSettings.fromMap({
        ThemeSettings.keyPalette: 'ocean',
        ThemeSettings.keyCustomSeed: 'not-a-colour',
      });

      expect(settings.palette, WaltPalette.ocean);
      expect(settings.customSeed, isNull);
    });

    test('a numeric-string custom seed is accepted', () {
      final settings = ThemeSettings.fromMap({
        ThemeSettings.keyCustomSeed: '4294901760',
      });

      expect(settings.customSeed, const Color(0xFFFF0000));
    });

    test('an entirely empty map yields the defaults', () {
      expect(ThemeSettings.fromMap(const {}), ThemeSettings.defaults);
    });
  });

  group('migration from the removed Material You setting', () {
    test('a leftover dynamic-colour flag does not survive', () {
      // Dynamic colour is gone from the app. Its stored flag has nowhere to be
      // read, and the palette defaults to emerald.
      final settings = ThemeSettings.fromMap({
        'dynamicColor': true,
        'useDynamicColor': false,
      });

      expect(settings, ThemeSettings.defaults);
      expect(settings.palette, WaltPalette.emerald);
    });
  });

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
