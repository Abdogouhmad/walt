import 'package:flutter/material.dart';

/// The icon of a single [FloatingNavBar] destination.
///
/// Swaps between the outlined and the filled glyph with a scale-and-fade
/// transition, and carries the optional count badge.
class FloatingNavIcon extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final Color color;
  final Duration springDuration;
  final Curve spring;
  final int badgeCount;

  const FloatingNavIcon({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.color,
    required this.springDuration,
    required this.spring,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final glyph = AnimatedSwitcher(
      duration: springDuration,
      switchInCurve: spring,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: Icon(
        isSelected ? selectedIcon : icon,
        key: ValueKey<bool>(isSelected),
        size: 24,
        color: color,
      ),
    );

    if (badgeCount <= 0) return glyph;

    return Badge(
      isLabelVisible: true,
      label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
      child: glyph,
    );
  }
}
