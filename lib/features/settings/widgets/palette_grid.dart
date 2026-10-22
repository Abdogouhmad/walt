import 'package:flutter/material.dart';
import 'package:walt/features/settings/widgets/palette_swatch.dart';
import 'package:walt_ui/walt_ui.dart';

/// The wrapping grid of palettes.
///
/// A `Wrap` rather than a `GridView`: nine fixed-width discs of [PaletteSwatch]
/// plus one "Custom" tile flow to as many rows as the width allows, which is the
/// only layout that works on a 320dp phone and a 600dp tablet without a
/// breakpoint.
class PaletteGrid extends StatelessWidget {
  const PaletteGrid({
    super.key,
    required this.selected,
    required this.isCustom,
    required this.brightness,
    required this.onSelect,
    required this.onSelectCustom,
  });

  final WaltPalette selected;
  final bool isCustom;
  final Brightness brightness;
  final ValueChanged<WaltPalette> onSelect;
  final VoidCallback onSelectCustom;

  @override
  Widget build(BuildContext context) {
    final appScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: AppRadius.sm,
      runSpacing: AppSpacing.md,
      alignment: WrapAlignment.center,
      children: [
        // Generated per palette, at the brightness on screen: each disc needs
        // the scheme *its own* seed produces, not a copy of the active one.
        for (final palette in WaltPalette.values)
          PaletteSwatch(
            label: palette.label,
            scheme: AppColorSchemes.forPalette(palette, brightness: brightness),
            selected: !isCustom && palette == selected,
            onTap: () => onSelect(palette),
          ),
        PaletteSwatch(
          label: 'Custom',
          scheme: appScheme,
          selected: isCustom,
          custom: true,
          onTap: onSelectCustom,
        ),
      ],
    );
  }
}
