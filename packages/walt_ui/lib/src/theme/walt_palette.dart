import 'package:flutter/material.dart';

/// The built-in colour palettes offered in Settings → Appearance.
///
/// Each entry is a *seed*, not a finished scheme: the same tonal-spot
/// generator that Material uses for Material You turns it into the full
/// `ColorScheme`, so every palette exposes identical roles and no downstream
/// screen has to know which one is active.
///
/// Adding a palette is therefore a one-line change — add an entry here. The
/// settings grid, the preview card, the persistence layer and every test that
/// iterates `WaltPalette.values` pick it up for free.
enum WaltPalette {
  /// The default. Matches the launcher icon.
  emerald('Emerald', Color(0xFF1B9E77)),
  ocean('Ocean', Color(0xFF1E88E5)),
  indigo('Indigo', Color(0xFF5C6BC0)),
  violet('Violet', Color(0xFF8E5CD9)),
  rose('Rose', Color(0xFFE25577)),
  amber('Amber', Color(0xFFF0A020)),
  terracotta('Terracotta', Color(0xFFC8664A)),
  teal('Teal', Color(0xFF00897B)),
  graphite('Graphite', Color(0xFF607D8B));

  const WaltPalette(this.label, this.seed);

  /// Human-readable name, shown under the swatch in Settings.
  final String label;

  /// The colour the whole scheme is generated from.
  final Color seed;

  /// The palette used when nothing is stored, when the stored value is
  /// unrecognised, and when a former Material You preference is migrated away.
  static const WaltPalette fallback = WaltPalette.emerald;

  /// Resolves a stored enum [name], falling back to [fallback].
  ///
  /// Storage outlives the code that wrote it: a palette can be removed or
  /// renamed in a later release, and a stale value must never be a crash or a
  /// silently blank scheme.
  static WaltPalette fromName(String? name) {
    if (name == null) return fallback;
    for (final palette in values) {
      if (palette.name == name) return palette;
    }
    return fallback;
  }
}
