import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../tokens/motion.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';
import './sheet_signal.dart';

/// The app's single sheet component: always a **bottom sheet** (Walt is
/// Android-only, so there is deliberately no desktop dialog variant — spec
/// §1.2). Every action sheet, add/edit form and update prompt in the app
/// flows through here so they share one visual shape: draggable, 28dp
/// rounded top corners, animated with the M3 expressive curves.
///
/// The sheet resizes above the on-screen keyboard, so a form's scroll view
/// always ends at the top of the keyboard and focused fields scroll into view.
///
/// Opening a sheet also raises [modalSheetOpenProvider], which is how the app
/// shell gets its floating chrome out of the way: a sheet is pushed on the
/// root navigator and would otherwise be painted over the nav pill and the
/// FAB, leaving both dimmed and half-covered underneath it.
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
}) async {
  final signal = _sheetSignal(context);
  signal?.open();
  try {
    return await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: showDragHandle,
      shape: const RoundedRectangleBorder(
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
      builder: (ctx) => AnimatedPadding(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: FractionallySizedBox(heightFactor: heightFactor, child: content),
      ),
    );
  } finally {
    signal?.close();
  }
}

/// The signal that records "a sheet is open", if there is a container to
/// record it in.
///
/// A widget test can mount a sheet without a [ProviderScope] above it; there
/// the sheet still opens, it just cannot tell the shell to step aside.
ModalSheetSignal? _sheetSignal(BuildContext context) {
  try {
    return ProviderScope.containerOf(
      context,
      listen: false,
    ).read(modalSheetOpenProvider.notifier);
  } on StateError {
    return null;
  }
}

/// Padding for form bodies inside [showWaltModal] content.
///
/// The keyboard inset is NOT added here: [showWaltModal] already lifts the
/// whole sheet above the keyboard. This only adds the system-bar clearance
/// and a comfortable gap below the last widget (e.g. the submit button).
EdgeInsets waltModalPadding(BuildContext context) {
  final bottom = MediaQuery.paddingOf(context).bottom + AppSpacing.lg;
  return EdgeInsets.fromLTRB(
    AppSpacing.lg,
    AppSpacing.lg,
    AppSpacing.lg,
    bottom,
  );
}
