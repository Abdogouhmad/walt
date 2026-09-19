import 'package:flutter/material.dart';

import 'package:walt/core/design/motion.dart';
import 'package:walt/core/design/radius.dart';
import 'package:walt/core/design/spacing.dart';

/// The app's single sheet component: always a **bottom sheet** (Walt is
/// Android-only, so there is deliberately no desktop dialog variant — spec
/// §1.2). Every action sheet, add/edit form and update prompt in the app
/// flows through here so they share one visual shape: draggable, 28dp
/// rounded top corners, animated with the M3 expressive curves.
///
/// ```dart
/// await showWaltModal<void>(
///   context,
///   content: const _MyForm(),
///   heightFactor: 0.92,
/// );
/// ```
Future<T?> showWaltModal<T>(
  BuildContext context, {
  required Widget content,
  double heightFactor = 0.92,
  bool showDragHandle = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: showDragHandle,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.surface),
      ),
    ),
    // Smoother open/close: a touch slower going up (feels deliberate),
    // snappier coming back down (feels responsive on dismiss).
    sheetAnimationStyle: const AnimationStyle(
      duration: AppMotion.medium,
      reverseDuration: AppMotion.short,
      curve: AppMotion.standard,
      reverseCurve: AppMotion.exit,
    ),
    builder: (_) => FractionallySizedBox(heightFactor: heightFactor, child: content),
  );
}

/// Padding for form bodies inside [showWaltModal] content. The extra bottom
/// clearance keeps the on-screen keyboard from covering the submit button.
EdgeInsets waltModalPadding(BuildContext context) {
  final bottom = MediaQuery.of(context).viewInsets.bottom +
      MediaQuery.paddingOf(context).bottom +
      AppSpacing.lg;
  return EdgeInsets.fromLTRB(
    AppSpacing.lg,
    AppSpacing.lg,
    AppSpacing.lg,
    bottom,
  );
}