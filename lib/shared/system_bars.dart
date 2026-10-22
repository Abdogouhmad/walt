import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:walt_ui/walt_ui.dart';

/// Keeps the system bars' icon brightness in step with the effective theme.
///
/// The bars themselves stay transparent — the app draws edge to edge — so the
/// only thing that has to track the palette is whether the icons should be light
/// or dark. Driven from the resolved `ColorScheme` inside the app rather than
/// from the raw `ThemeMode`, so "system in dark mode" is handled by the same
/// code path as an explicit dark selection.
class SystemBars extends StatelessWidget {
  const SystemBars({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(Theme.of(context).colorScheme),
      child: child,
    );
  }
}
