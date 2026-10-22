import 'package:flutter/material.dart';

import '../tokens/radius.dart';
import '../utils/haptics.dart';
import 'app_button_spec.dart';

/// The filled variants of [AppButton]: a solid action and its outlined twin.
///
/// They live together because they are the same decision with a different
/// emphasis — one fills the surface, the other only outlines it.
class AppButtonFilled {
  const AppButtonFilled._();

  /// The primary action: a solid surface with the label on top of it.
  static Widget primary(AppButtonSpec spec) {
    final onPressed = spec.onPressed;
    return ElevatedButton(
      onPressed: onPressed == null
          ? null
          : () {
              Haptics.light();
              onPressed();
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: spec.fill,
        foregroundColor: spec.onFill,
        elevation: 0,
        padding: spec.metrics.padding(spec.context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
        textStyle: spec.labelStyle(),
        minimumSize: spec.minimumSize,
      ),
      child: spec.isLoading ? spec.spinner(spec.onFill) : Text(spec.label!),
    );
  }

  /// The secondary action: an outline instead of a fill.
  static Widget secondary(AppButtonSpec spec) {
    final onPressed = spec.onPressed;
    return OutlinedButton(
      onPressed: onPressed == null
          ? null
          : () {
              Haptics.light();
              onPressed();
            },
      style: OutlinedButton.styleFrom(
        foregroundColor: spec.accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
        side: BorderSide(color: spec.accent),
        padding: spec.metrics.padding(spec.context),
        textStyle: spec.labelStyle(weight: FontWeight.w500),
        minimumSize: spec.minimumSize,
      ),
      child: spec.isLoading ? spec.spinner(spec.accent) : Text(spec.label!),
    );
  }
}
