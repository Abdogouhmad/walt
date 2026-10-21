import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:walt/core/theme/color_schemes.dart';
import 'package:walt/core/theme/theme_settings.dart';
import 'package:walt/core/utils/bounded_memo.dart';

void main() {
  group('BoundedMemo', () {
    test('builds once and reuses the value afterwards', () {
      final memo = BoundedMemo<String, int>(4);
      var builds = 0;

      final first = memo.getOrPut('a', () {
        builds++;
        return 1;
      });
      final second = memo.getOrPut('a', () {
        builds++;
        return 2;
      });

      expect(first, 1);
      expect(second, 1);
      expect(builds, 1);
    });

    test('a hit keeps the entry cached instead of dropping it', () {
      // The regression: the hit removed the entry and never put it back, so
      // the *next* request for the same key rebuilt it from scratch — the
      // memo did no memoising at all for keys that were asked for twice.
      final memo = BoundedMemo<String, int>(4);
      var builds = 0;

      memo.getOrPut('a', () => ++builds);
      memo.getOrPut('a', () => ++builds);
      memo.getOrPut('a', () => ++builds);

      expect(builds, 1);
      expect(memo.length, 1);
    });

    test('evicts the least recently used entry once the cap is passed', () {
      final memo = BoundedMemo<String, int>(2);
      var builds = 0;

      memo.getOrPut('a', () => ++builds); // 1
      memo.getOrPut('b', () => ++builds); // 2
      // Touch 'a' so 'b' becomes the least recently used entry.
      memo.getOrPut('a', () => ++builds);
      memo.getOrPut('c', () => ++builds); // 3, evicts 'b'

      expect(memo.length, 2);
      expect(builds, 3);

      // 'b' was evicted, so it has to be built again.
      memo.getOrPut('b', () => ++builds);
      expect(builds, 4);
    });

    test('never holds more than the capacity', () {
      final memo = BoundedMemo<int, int>(8);

      for (var i = 0; i < 100; i++) {
        memo.getOrPut(i, () => i);
        expect(memo.length, lessThanOrEqualTo(8));
      }
    });

    test('rejects a capacity of zero or less', () {
      expect(() => BoundedMemo<String, int>(0), throwsAssertionError);
      expect(() => BoundedMemo<String, int>(-1), throwsAssertionError);
    });
  });

  group('colour-scheme memo', () {
    test('the same seed returns the same scheme instance', () {
      const settings = ThemeSettings();

      final first = AppColorSchemes.of(settings, Brightness.light);
      final second = AppColorSchemes.of(settings, Brightness.light);

      expect(identical(first, second), isTrue);
    });

    test('a different brightness is a different scheme', () {
      const settings = ThemeSettings();

      final light = AppColorSchemes.of(settings, Brightness.light);
      final dark = AppColorSchemes.of(settings, Brightness.dark);

      expect(identical(light, dark), isFalse);
      expect(dark.brightness, Brightness.dark);
    });

    test('a free-form seed is memoised on its own key', () {
      // Custom seeds are the reason the cache needed a cap: the colour picker
      // produces a distinct seed per pointer move.
      const settings = ThemeSettings(customSeed: Color(0xFF8E5CD9));

      final first = AppColorSchemes.of(settings, Brightness.light);
      final second = AppColorSchemes.of(settings, Brightness.light);

      expect(identical(first, second), isTrue);
    });
  });
}
