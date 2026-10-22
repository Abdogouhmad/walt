import 'package:flutter/material.dart';

/// One destination in [FloatingNavBar].
@immutable
class WaltDestination {
  /// Outlined icon, shown when the destination is not selected.
  final IconData icon;

  /// Filled icon, shown inside the active pill.
  final IconData selectedIcon;

  /// Accessibility label; also the text revealed inside the active pill.
  final String label;

  /// Optional badge count (0 / null hides the badge).
  final int? badgeCount;

  const WaltDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount,
  });
}
