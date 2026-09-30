import 'package:flutter/material.dart';

import 'package:walt/core/theme/walt_chart_colors.dart';
import 'package:walt/core/utils/category_icon.dart';

/// Category icons are drawn inside a tonal container so they read as a set
/// rather than as loose glyphs (spec §3 "Icons").
///
/// The container is a soft squircle by default; pass [circular] for list
/// avatars. The tone is taken from the category itself when available, else
/// from the scheme's `secondaryContainer`.
class CategoryAvatar extends StatelessWidget {
  /// Category icon key as stored in the database (mapped by [CategoryIcons]).
  final String icon;

  /// Optional per-category colour (`#RRGGBB`) used for the tonal wash.
  final String? color;

  /// Series slot this avatar stands for, used only when [color] is absent: two
  /// categories with no colour of their own must not collapse to the same wash
  /// in a legend. Pass the same index the corresponding chart entry uses.
  final int seriesIndex;

  final double size;
  final bool circular;
  final bool filled;

  const CategoryAvatar({
    super.key,
    required this.icon,
    this.color,
    this.seriesIndex = 0,
    this.size = 40,
    this.circular = true,
    this.filled = true,
  });

  /// Parses a `#RRGGBB` string, returning null when malformed.
  static Color? parseHex(String? hex) {
    if (hex == null) return null;
    final cleaned = hex.replaceAll('#', '');
    final value = int.tryParse('FF$cleaned', radix: 16);
    return value == null ? null : Color(value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A category's own colour is harmonized toward the active series palette
    // rather than pasted in raw, so a legend picked under Amber does not stay
    // frozen in Material orange after the user switches to Ocean.
    final tint = WaltChartColors.of(
      context,
    ).harmonizeCategory(parseHex(color), seriesIndex);

    final background = filled
        ? tint.withValues(alpha: 0.14)
        : Colors.transparent;
    final foreground = Color.alphaBlend(
      tint.withValues(alpha: 0.85),
      scheme.surface,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular ? null : BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        CategoryIcons.getIcon(icon),
        size: size * 0.5,
        color: foreground,
      ),
    );
  }
}
