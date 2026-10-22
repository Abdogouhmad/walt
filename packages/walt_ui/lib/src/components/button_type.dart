import 'package:flutter/material.dart';

import '../utils/context.dart';

/// Visual treatment for [AppButton].
enum ButtonType { primary, secondary, text, textIcon, iconOnly, fab }

/// Sizing presets for [AppButton].
enum ButtonSize { small, medium, large, extended }

/// The measurements of one [ButtonSize] preset.
///
/// Sizes are expressed through `sp`/`w`/`h` so they scale with the user's font
/// and display settings instead of being pinned to physical pixels.
class AppButtonMetrics {
  const AppButtonMetrics(this.size);

  final ButtonSize size;

  /// The label's font size.
  double fontSize(BuildContext context) => switch (size) {
    ButtonSize.small => context.sp(13),
    ButtonSize.medium => context.sp(15),
    ButtonSize.large => context.sp(17),
    ButtonSize.extended => context.sp(15),
  };

  /// The padding around the label.
  EdgeInsets padding(BuildContext context) => switch (size) {
    ButtonSize.small => EdgeInsets.symmetric(
      horizontal: context.w(12),
      vertical: context.h(8),
    ),
    ButtonSize.medium => EdgeInsets.symmetric(
      horizontal: context.w(20),
      vertical: context.h(12),
    ),
    ButtonSize.large => EdgeInsets.symmetric(
      horizontal: context.w(28),
      vertical: context.h(16),
    ),
    ButtonSize.extended => EdgeInsets.symmetric(
      horizontal: context.w(20),
      vertical: context.h(12),
    ),
  };

  /// The icon's edge length.
  double iconSize(BuildContext context) => switch (size) {
    ButtonSize.small => context.w(16),
    ButtonSize.medium => context.w(20),
    ButtonSize.large => context.w(24),
    ButtonSize.extended => context.w(24),
  };

  /// The loading spinner's edge length.
  double spinnerSize(BuildContext context) => switch (size) {
    ButtonSize.small => context.w(14),
    ButtonSize.medium => context.w(18),
    ButtonSize.large => context.w(22),
    ButtonSize.extended => context.w(18),
  };
}
