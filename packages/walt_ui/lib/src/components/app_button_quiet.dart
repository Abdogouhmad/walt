import 'package:flutter/material.dart';

import '../utils/context.dart';
import '../utils/haptics.dart';
import 'app_button_spec.dart';

/// The quiet variants of [AppButton]: text, text-with-icon and icon-only.
///
/// Nothing here fills a surface except the icon button's ripple, so they are
/// the right choice for a tertiary action that must not compete with the
/// primary one.
class AppButtonQuiet {
  const AppButtonQuiet._();

  /// A bare text action, optionally followed by a small icon.
  static Widget text(AppButtonSpec spec) {
    final onPressed = spec.onPressed;
    return TextButton(
      onPressed: onPressed == null
          ? null
          : () {
              Haptics.light();
              onPressed();
            },
      style: TextButton.styleFrom(
        foregroundColor: spec.accent,
        padding: spec.metrics.padding(spec.context),
        textStyle: spec.labelStyle(weight: FontWeight.w500),
        minimumSize: spec.minimumSize,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(spec.label!),
          if (spec.isLoading || spec.icon != null) ...[
            SizedBox(width: spec.context.w(5)),
            spec.isLoading
                ? spec.spinner(spec.accent)
                : Icon(spec.icon, size: spec.metrics.iconSize(spec.context)),
          ],
        ],
      ),
    );
  }

  /// A text action with an outlined pill around it.
  static Widget textIcon(AppButtonSpec spec) {
    final onPressed = spec.onPressed;
    return TextButton.icon(
      onPressed: onPressed == null
          ? null
          : () {
              Haptics.light();
              onPressed();
            },
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: spec.accent.withValues(alpha: 0.4), width: 1),
        ),
        foregroundColor: spec.accent,
        padding: spec.metrics.padding(spec.context),
        textStyle: spec.labelStyle(weight: FontWeight.w500),
        minimumSize: spec.minimumSize,
      ),
      label: Text(spec.label!),
      icon: spec.isLoading
          ? spec.spinner(spec.accent)
          : Icon(spec.icon, size: spec.metrics.iconSize(spec.context)),
    );
  }

  /// A square, icon-only action. The label is only ever a tooltip.
  static Widget iconOnly(AppButtonSpec spec) {
    final onPressed = spec.onPressed;
    return IconButton(
      onPressed: onPressed == null
          ? null
          : () {
              Haptics.light();
              onPressed();
            },
      icon: spec.isLoading
          ? spec.spinner(spec.iconColor)
          : Icon(spec.icon, size: spec.metrics.iconSize(spec.context)),
      color: spec.iconColor,
      padding: spec.metrics.padding(spec.context),
      tooltip: spec.tooltip,
      style: IconButton.styleFrom(foregroundColor: spec.iconColor),
    );
  }
}
