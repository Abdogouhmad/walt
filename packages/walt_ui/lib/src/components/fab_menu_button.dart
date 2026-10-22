import 'package:flutter/material.dart';

import '../tokens/motion.dart';
import 'fab_surface.dart';

/// The primary "add" button of a FAB menu, anchored above the navigation bar.
///
/// It slides away when the menu is hidden and rotates into its open state
/// while the action stack unfolds.
class FabMenuButton extends StatelessWidget {
  final bool visible;
  final bool open;
  final ColorScheme scheme;
  final Animation<double>? turns;
  final String semanticsLabel;
  final double size;
  final double bottom;
  final double right;
  final bool reduceMotion;
  final VoidCallback onTap;

  const FabMenuButton({
    super.key,
    required this.visible,
    required this.open,
    required this.scheme,
    required this.turns,
    required this.semanticsLabel,
    required this.size,
    required this.bottom,
    required this.right,
    required this.reduceMotion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 1.6),
          duration: reduceMotion ? Duration.zero : AppMotion.medium,
          curve: AppMotion.emphasized,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: reduceMotion ? Duration.zero : AppMotion.short,
            child: FabSurface(
              size: size,
              scheme: scheme,
              open: open,
              turns: turns,
              semanticsLabel: semanticsLabel,
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }
}
