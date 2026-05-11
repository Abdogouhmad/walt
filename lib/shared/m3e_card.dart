import 'package:flutter/material.dart';
import 'package:walt/core/utils/context.dart';
// import 'package:walt/core/constants/app_colors.dart';
// import 'package:walt/core/utils/context.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class AppCardData {
  final String? title;
  final String? subtitle;
  final Color? colorCard;
  final String? body;
  final Widget? leading;
  final Widget? child; // ← add this
  final List<Widget>? actions;
  final ShapeBorder? shape;

  const AppCardData({
    this.title,
    this.subtitle,
    this.colorCard,
    this.body,
    this.leading,
    this.child, // ← add this
    this.actions,
    this.shape,
  });
}
// ─── Variants ────────────────────────────────────────────────────────────────

enum M3ECardVariant { elevated, filled, outlined }

// ─── Widget ──────────────────────────────────────────────────────────────────

class M3Ecard extends StatelessWidget {
  const M3Ecard({
    super.key,
    required this.data,
    this.variant = M3ECardVariant.elevated,
    this.onTap,
    this.padding,
  });

  final AppCardData data;
  final M3ECardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final content = Padding(
      padding: padding ?? EdgeInsets.all(context.w(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          Row(
            children: [
              if (data.leading != null) ...[
                data.leading!,
                SizedBox(width: context.w(24)),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.title ?? "", style: theme.textTheme.titleMedium),
                    if (data.subtitle != null)
                      Text(
                        data.subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Body
          if (data.body != null) ...[
            SizedBox(height: context.h(24)),
            Text(
              data.body!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          if (data.child != null) ...[
            SizedBox(height: context.h(16)),
            data.child!, // ← add this block
          ],
          // Actions
          if (data.actions != null) ...[
            SizedBox(height: context.h(8)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: data.actions!,
            ),
          ],
        ],
      ),
    );

    return switch (variant) {
      M3ECardVariant.elevated => Card(
        color: data.colorCard,
        shape:
            data.shape ??
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.r(24)),
              side: BorderSide(
                color: context.colorAppScheme.secondary,
                width: context.w(1),
              ),
            ),
        elevation: 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(context.r(24)),
          child: content,
        ),
      ),
      M3ECardVariant.filled => Card.filled(
        color: data.colorCard,
        shape:
            data.shape ??
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.r(24)),
              side: BorderSide(
                color: context.colorAppScheme.secondary,
                width: context.w(1),
              ),
            ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(context.r(24)),
          child: content,
        ),
      ),
      M3ECardVariant.outlined => Card.outlined(
        borderOnForeground: true,
        color: data.colorCard,
        shape:
            data.shape ??
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.r(24)),
              side: BorderSide(
                color: context.colorAppScheme.secondary,
                width: context.w(1),
              ),
            ),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(context.r(24)),
          child: content,
        ),
      ),
    };
  }
}
