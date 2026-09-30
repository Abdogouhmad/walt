import 'package:flutter/material.dart';

import 'package:walt/core/design/spacing.dart';
import 'package:walt/core/theme/shapes.dart';

/// A Material 3 Expressive "grouped list": [children] are laid out as one
/// container where the first and last rows keep the large
/// [AppShape.large] silhouette and the rows in between tuck into
/// [AppShape.small], separated by [gap].
///
/// Each row is wrapped in a [Material] so ripples are clipped to its corners.
class GroupedList extends StatelessWidget {
  final List<Widget> children;

  /// Background of each row. Defaults to `surfaceContainerLow`.
  final Color? color;

  /// Gap between rows.
  final double gap;

  /// Padding around the whole group.
  final EdgeInsetsGeometry? padding;

  const GroupedList({
    super.key,
    required this.children,
    this.color,
    // Spec §3 "Lists" calls for 2dp. On device that reads as a hairline seam
    // rather than as separation — the rows merged into a single slab and the
    // list looked like it had no spacing at all. These are individually
    // rounded, filled cards, so they need enough air to be seen as rows.
    this.gap = AppSpacing.sm,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final bg = color ?? scheme.surfaceContainerLow;
    final count = children.length;

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == count - 1 ? 0 : gap),
              child: Material(
                color: bg,
                borderRadius: GroupedRadii.forIndex(i, count),
                clipBehavior: Clip.antiAlias,
                child: children[i],
              ),
            ),
        ],
      ),
    );
  }
}

/// A row inside a [GroupedList], sized and padded to match Walt's spacing
/// rhythm. Prefer this over a raw [ListTile] so leading avatars, titles and
/// trailing amounts line up across every screen.
class GroupedListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;

  const GroupedListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding:
            padding ??
            const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + AppSpacing.xs,
            ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DefaultTextStyle.merge(
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: title,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    DefaultTextStyle.merge(
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
