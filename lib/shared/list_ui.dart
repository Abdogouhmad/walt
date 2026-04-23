import 'package:flutter/material.dart';
import 'package:walt/core/constants/app_colors.dart';
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

    final effectiveSubtitleColor =
        subtitleColor ?? cs.onSurfaceVariant.withOpacity(0.7);

    final verticalPadding = dense ? 10.0 : 14.0;

    Widget content = InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding:
            padding ??
            EdgeInsets.symmetric(horizontal: 16, vertical: verticalPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 14)],

            /// TEXT
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
                    const SizedBox(height: 4),
                    UiText(
                      text: subtitle!,
                      type: UiTextType.bodyMedium,
                      style: TextStyle(color: effectiveSubtitleColor),
                    ),
                  ],
                ],
              ),
            ),

            /// TRAILING
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ] else if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: cs.onSurfaceVariant.withOpacity(0.6),
              ),
            ],
          ],
        ),
      ),
    );

    /// STYLE WRAPPER
    switch (style) {
      case ListStyle.plain:
        return Material(
          color: backgroundColor ?? Colors.transparent,
          child: content,
        );

      case ListStyle.card:
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor ?? cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Material(color: Colors.transparent, child: content),
        );

      case ListStyle.outlined:
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
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
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
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
                if (trailing != null) trailing!,
              ],
            ),
          ),
        Container(
          margin: margin,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: children.length,
            separatorBuilder: (context, index) => showDivider
                ? Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: context.listSubLabel.withOpacity(0.2),
                  )
                : const SizedBox.shrink(),
            itemBuilder: (context, index) => children[index],
          ),
        ),
      ],
    );
  }
}

class AppListHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const AppListHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.listTitle,
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onActionPressed,
              child: Text(
                actionLabel!,
                style: TextStyle(color: context.listColorLinks),
              ),
            ),
        ],
      ),
    );
  }
}

class AppListEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const AppListEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: context.listSubLabel.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: context.listSubLabel),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onActionPressed,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppListActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;
  final Widget? trailing;

  const AppListActionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.textColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor ?? context.listIconBk),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? context.listTitle,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: backgroundColor ?? context.listContainer.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cs.outlineVariant.withOpacity(0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: content,
        ),
      );
    }

    return content;
  }
}
