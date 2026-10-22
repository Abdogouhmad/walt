import 'package:flutter/material.dart';

import 'app_button_spec.dart';
import 'button_type.dart';

/// The floating variant of [AppButton]: the app's action button, in the four
/// sizes Material offers.
class AppButtonFab {
  const AppButtonFab._();

  /// Builds the FAB for the preset in [spec].
  ///
  /// The extended FAB is the only variant that carries a label; the others are
  /// icon-only, and the label (if there is one) becomes the tooltip.
  static Widget build(AppButtonSpec spec) {
    final child = spec.isLoading
        ? spec.spinner(spec.onFill)
        : Icon(spec.icon, size: spec.metrics.iconSize(spec.context));

    return switch (spec.metrics.size) {
      ButtonSize.small => FloatingActionButton.small(
        onPressed: spec.onPressed,
        backgroundColor: spec.fill,
        foregroundColor: spec.onFill,
        tooltip: spec.tooltip,
        child: child,
      ),
      ButtonSize.large => FloatingActionButton.large(
        onPressed: spec.onPressed,
        backgroundColor: spec.fill,
        foregroundColor: spec.onFill,
        tooltip: spec.tooltip,
        child: child,
      ),
      ButtonSize.extended => FloatingActionButton.extended(
        onPressed: spec.onPressed,
        backgroundColor: spec.fill,
        foregroundColor: spec.onFill,
        tooltip: spec.tooltip,
        icon: spec.isLoading
            ? spec.spinner(spec.onFill)
            : Icon(spec.icon, size: spec.metrics.iconSize(spec.context)),
        label: Text(spec.label!, style: spec.labelStyle()),
      ),
      ButtonSize.medium => FloatingActionButton(
        onPressed: spec.onPressed,
        backgroundColor: spec.fill,
        foregroundColor: spec.onFill,
        tooltip: spec.tooltip,
        child: child,
      ),
    };
  }
}
