import 'package:flutter/material.dart';

import 'app_button_fab.dart';
import 'app_button_filled.dart';
import 'app_button_quiet.dart';
import 'app_button_spec.dart';
import 'button_type.dart';

/// The app's one button component (spec §1.3) — every tap target in Walt
/// (header actions, sheet submit buttons, the budgets FAB, filter chips)
/// flows through this widget so press feedback, corner radius and type scale
/// stay identical app-wide.
///
/// The widget itself decides nothing about shape: it resolves the colours and
/// the measurements once and hands them to a variant, so a button can change
/// its treatment without any of the variants drifting out of step.
class AppButton extends StatelessWidget {
  final String? label;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isDestructive;
  final bool isFullWidth;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;

  const AppButton({
    super.key,
    this.label,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isDestructive = false,
    this.isFullWidth = false,
    this.iconColor,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
  }) : assert(
         type == ButtonType.iconOnly || type == ButtonType.fab || label != null,
         'label is required unless type is iconOnly or fab',
       ),
       assert(
         type != ButtonType.textIcon ||
             type != ButtonType.iconOnly ||
             type != ButtonType.fab ||
             icon != null,
         'icon is required for textIcon, iconOnly, and fab types',
       ),
       assert(
         type != ButtonType.fab || size != ButtonSize.extended || label != null,
         'label is required for extended FAB',
       );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final metrics = AppButtonMetrics(size);

    // A destructive button borrows the error role; everything else follows the
    // primary role unless the caller says otherwise.
    final accent = foregroundColor ?? (isDestructive ? cs.error : cs.primary);
    final fill = backgroundColor ?? (isDestructive ? cs.error : cs.primary);
    final onFill =
        foregroundColor ?? (isDestructive ? cs.onError : cs.onPrimary);

    final spec = AppButtonSpec(
      context: context,
      label: label,
      icon: icon,
      // A loading button cannot be pressed again.
      onPressed: isLoading ? null : onPressed,
      metrics: metrics,
      accent: accent,
      fill: fill,
      onFill: onFill,
      iconColor:
          iconColor ??
          foregroundColor ??
          (isDestructive ? cs.error : cs.onSurfaceVariant),
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      tooltip: tooltip,
    );

    final button = switch (type) {
      ButtonType.primary => AppButtonFilled.primary(spec),
      ButtonType.secondary => AppButtonFilled.secondary(spec),
      ButtonType.text => AppButtonQuiet.text(spec),
      ButtonType.textIcon => AppButtonQuiet.textIcon(spec),
      ButtonType.iconOnly => AppButtonQuiet.iconOnly(spec),
      ButtonType.fab => AppButtonFab.build(spec),
    };

    if (!isFullWidth) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
