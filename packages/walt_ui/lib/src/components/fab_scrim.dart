import 'package:flutter/material.dart';

/// The dimming layer behind an open FAB menu.
///
/// Always mounted so its opacity can animate out, but it only intercepts
/// pointers while the menu is open.
class FabScrim extends StatelessWidget {
  final Animation<double> opacity;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const FabScrim({
    super.key,
    required this.opacity,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !active,
      child: FadeTransition(
        opacity: opacity,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ColoredBox(color: color.withValues(alpha: 0.32)),
        ),
      ),
    );
  }
}
