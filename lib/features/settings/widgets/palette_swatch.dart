import 'package:flutter/material.dart';

import 'package:walt/core/design/radius.dart';
import 'package:walt/core/design/spacing.dart';
import 'package:walt/core/theme/motion.dart';

/// One palette in the Appearance grid.
///
/// The swatch is a 48dp circle of the palette's own `primary`, with a
/// `tertiary` half-circle peeking out of the bottom-right. The two-tone disc is
/// what makes nine solid circles tellable apart at a glance: a single flat
/// colour tells you the hue and nothing about the palette's character, and two
/// adjacent seeds (`indigo` / `violet`, `teal` / `emerald`) are nearly
/// indistinguishable as one tone.
///
/// The circle is built from [scheme] alone, so it is correct in light, dark and
/// AMOLED without knowing anything about the current theme.
class PaletteSwatch extends StatelessWidget {
  const PaletteSwatch({
    super.key,
    required this.label,
    required this.scheme,
    required this.selected,
    required this.onTap,
    this.custom = false,
  });

  /// Palette name, shown under the disc.
  final String label;

  /// The palette's own scheme, generated at the current brightness.
  final ColorScheme scheme;

  /// Whether this palette is the active one.
  final bool selected;

  /// Applies the palette. Fired on tap, not on a separate confirm button.
  final VoidCallback onTap;

  /// Renders the "Custom" affordance instead of a two-tone disc.
  final bool custom;

  static const double diameter = 48;
  static const double accentDiameter = 26;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The ring is the *app's* primary, not the swatch's, so a selected swatch
    // reads as selected in a palette it is not itself.
    final ring = theme.colorScheme.primary;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label theme',
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: AppRadius.lg,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                // The spring, not a fade: the disc has physical presence on a
                // screen of nine peers, and a scale that overshoots says
                // "picked" before the app-wide recolour has even started.
                scale: selected ? 1 : 0.88,
                duration: AppSpring.isDisabled(context)
                    ? Duration.zero
                    : AppMotion.medium,
                curve: AppSpring.curve(AppSpring.spatial),
                child: AnimatedContainer(
                  duration: AppSpring.isDisabled(context)
                      ? Duration.zero
                      : AppMotion.short,
                  curve: AppMotion.standard,
                  width: diameter,
                  height: diameter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: custom
                        ? scheme.surfaceContainerHighest
                        : scheme.primary,
                    border: selected ? Border.all(color: ring, width: 3) : null,
                  ),
                  child: ClipOval(
                    child: custom
                        ? Icon(
                            Icons.color_lens_rounded,
                            color: scheme.onSurfaceVariant,
                          )
                        : Stack(
                            children: [
                              Positioned.fill(
                                child: ColoredBox(color: scheme.primary),
                              ),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: SizedBox(
                                  width: accentDiameter,
                                  height: accentDiameter,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: scheme.tertiary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                              if (selected)
                                Center(
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 22,
                                    color: scheme.onPrimary,
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                width: diameter + AppSpacing.md,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
