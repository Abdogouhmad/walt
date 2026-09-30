import 'package:flutter/material.dart';
import 'package:walt/core/theme/color_math.dart';
import 'package:walt/core/theme/theme_settings.dart';
import 'package:walt/core/theme/walt_palette.dart';

/// Generation of [ColorScheme]s from a seed.
///
/// Walt has no Material You: the scheme comes from the palette the user picked
/// (or a custom seed), not from the wallpaper. Everything downstream — screens,
/// charts, `WaltColors` — reads roles from the resulting scheme, so a palette
/// swap is a swap of a handful of values rather than a re-skin.
abstract final class AppColorSchemes {
  const AppColorSchemes._();

  /// One variant for every palette. Tonal spot keeps a visible chroma ramp
  /// (vibrant) while holding contrast; the alternatives read as either washed
  /// out or neon depending on the seed.
  static const DynamicSchemeVariant variant = DynamicSchemeVariant.tonalSpot;

  /// The scheme for [settings] at [brightness], including the AMOLED override
  /// when dark mode is in effect.
  ///
  /// The seed is passed through [clampForContrast] first, which is what makes an
  /// arbitrary user-picked colour safe. Tonal spot does not guarantee that the
  /// `onPrimary` it picks can be read on the `primary` it picks — for some
  /// seeds the two come out within a hair of each other — and a filled button
  /// whose label has vanished is a much worse outcome than a seed that came
  /// back a shade less saturated than the one that was tapped.
  ///
  /// Built-in palette seeds are already vetted and clamp to themselves, so this
  /// costs nothing for them.
  static ColorScheme of(ThemeSettings settings, Brightness brightness) {
    final amoled = brightness == Brightness.dark && settings.amoled;
    return _memo(settings.seedColor, brightness, amoled, () {
      var scheme = fromSeedColor(
        clampForContrast(settings.seedColor, brightness),
        brightness,
      );
      if (amoled) scheme = applyAmoled(scheme);
      return scheme;
    });
  }

  /// The scheme for a single palette, ignoring mode and AMOLED.
  ///
  /// Used by the appearance screen to render a swatch and a live preview in the
  /// brightness the user is looking at right now.
  ///
  /// Memoised: `fromSeed` runs a full HCT solve, and the appearance grid needs
  /// one scheme per palette on every rebuild — which, on that screen, is every
  /// tap.
  static ColorScheme forPalette(
    WaltPalette palette, {
    Brightness brightness = Brightness.light,
  }) => _memo(palette.seed, brightness, false, () {
    return fromSeedColor(palette.seed, brightness);
  });

  /// One scheme per distinct input, forever.
  ///
  /// Keyed by a record rather than a combined `hashCode` so two different inputs
  /// cannot collide into one cached scheme — the cache is permanent, so a
  /// collision would be a wrong colour for the rest of the process.
  static ColorScheme _memo(
    Color seed,
    Brightness brightness,
    bool amoled,
    ColorScheme Function() build,
  ) => _cache.putIfAbsent((seed, brightness, amoled), build);

  static final Map<(Color, Brightness, bool), ColorScheme> _cache =
      <(Color, Brightness, bool), ColorScheme>{};

  /// The scheme for an arbitrary seed.
  static ColorScheme fromSeedColor(Color seedColor, Brightness brightness) =>
      ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
        dynamicSchemeVariant: variant,
      );

  /// Flattens the dark surface ramp to black.
  ///
  /// Only the *surface* roles move. Every accent role (`primary`, `error`,
  /// the container tones) is left exactly where Material put it, so switching
  /// AMOLED on changes how dark the app is without changing what any of the
  /// colours mean.
  static ColorScheme applyAmoled(ColorScheme scheme) => scheme.copyWith(
    surface: Colors.black,
    surfaceContainerLowest: Colors.black,
    surfaceContainerLow: const Color(0xFF0A0A0A),
    surfaceContainer: const Color(0xFF111111),
    surfaceContainerHigh: const Color(0xFF181818),
    surfaceContainerHighest: const Color(0xFF202020),
  );

  /// The nearest usable seed to [seed] at [brightness].
  ///
  /// A user can pick any colour at all, including ones that generate a scheme
  /// whose `onPrimary` cannot be read on its `primary`. Chroma is reduced first
  /// (it is the dimension that costs contrast) and tone second, so the colour
  /// the user chose survives as far as possible. Nothing is ever rejected: a
  /// colour picker that says "no" is a colour picker that cannot finish the
  /// job.
  static Color clampForContrast(Color seed, Brightness brightness) {
    if (_passes(seed, brightness)) return seed;

    final hsl = HSLColor.fromColor(seed);

    for (var step = 1; step <= 10; step++) {
      final candidate = hsl
          .withSaturation(hsl.saturation * (1 - step * 0.1))
          .toColor();
      if (_passes(candidate, brightness)) return candidate;
    }

    // Still failing at zero chroma is a tone problem, not a hue problem.
    for (final lightness in <double>[0.2, 0.3, 0.4, 0.6, 0.7, 0.8]) {
      final candidate = hsl
          .withSaturation(0)
          .withLightness(lightness)
          .toColor();
      if (_passes(candidate, brightness)) return candidate;
    }

    return seed;
  }

  static bool _passes(Color candidate, Brightness brightness) {
    final scheme = fromSeedColor(candidate, brightness);
    return ColorMath.contrastRatio(scheme.primary, scheme.onPrimary) >= 4.5;
  }
}
