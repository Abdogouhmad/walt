import 'package:flutter/material.dart';

import 'package:walt/core/constants/app_colors.dart';
import 'package:walt/core/design/radius.dart';
import 'package:walt/core/design/spacing.dart';
import 'package:walt/shared/text_ui.dart';

enum ListStyle { plain, card, outlined }

class AppListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ListStyle style;
  final bool isDestructive;
  final bool dense;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? subtitleColor;
  final EdgeInsetsGeometry? padding;

  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.style = ListStyle.plain,
    this.isDestructive = false,
    this.dense = false,
    this.backgroundColor,
    this.titleColor,
    this.subtitleColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final effectiveTitleColor =
        titleColor ?? (isDestructive ? cs.error : cs.onSurface);

    Widget content = InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(AppRadius.field),
      child: Padding(
        padding:
            padding ??
            const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // This is key
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: AppSpacing.md)],

            // TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  UiText(
                    text: title,
                    type: UiTextType.bodyLarge,
                    style: TextStyle(
                      color: effectiveTitleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    UiText(
                      text: subtitle!,
                      type: UiTextType.bodyMedium,
                      style: TextStyle(
                        color: subtitleColor ?? cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // TRAILING
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ] else if (onTap != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
            ],
          ],
        ),
      ),
    );

    // Style wrapper (unchanged)
    switch (style) {
      case ListStyle.plain:
        return Material(
          color: backgroundColor ?? Colors.transparent,
          child: content,
        );

      case ListStyle.card:
        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: backgroundColor ?? cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
          child: Material(color: Colors.transparent, child: content),
        );

      case ListStyle.outlined:
        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(color: cs.outlineVariant, width: 0.5),
          ),
          child: Material(color: Colors.transparent, child: content),
        );
    }
  }
}

class AppListSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final Widget? trailing;
  final bool showDivider;
  final EdgeInsetsGeometry? margin;

  const AppListSection({
    super.key,
    this.title,
    required this.children,
    this.trailing,
    this.showDivider = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title!.toUpperCase(),
                  style: textTheme.labelMedium?.copyWith(
                    color: context.listTitle,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        Container(
          margin: margin,
          child: Column(
            children: List.generate(children.length, (index) {
              return Column(
                children: [
                  children[index],
                  if (showDivider && index < children.length - 1)
                    Divider(
                      height: 1,
                      indent: AppSpacing.md,
                      endIndent: AppSpacing.md,
                      color: cs.outlineVariant.withAlpha(80),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class AppListAvatar extends StatelessWidget {
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const AppListAvatar({
    super.key,
    required this.icon,
    this.backgroundColor,
    this.iconColor,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? context.listContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: iconColor ?? context.listIconBk,
        size: size * 0.5,
      ),
    );
  }
}

class AppListGroup extends StatelessWidget {
  final List<Widget> children;
  final bool useCard;
  final Color? backgroundColor;

  const AppListGroup({
    super.key,
    required this.children,
    this.useCard = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget content = Column(mainAxisSize: MainAxisSize.min, children: children);

    if (useCard) {
      return Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        color: backgroundColor ?? context.listContainer.withAlpha(60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          side: BorderSide(color: cs.outlineVariant.withAlpha(80)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.field),
          child: content,
        ),
      );
    }

    return content;
  }
}
