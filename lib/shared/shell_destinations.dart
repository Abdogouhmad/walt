import 'package:flutter/material.dart';
import 'package:walt_ui/walt_ui.dart';

/// The nav pill's four destinations, in order.
///
/// Settings is *not* a tab — it is pushed as a normal route from the profile
/// avatar in each top-level screen's app bar.
const List<WaltDestination> shellDestinations = [
  WaltDestination(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    label: 'Home',
  ),
  WaltDestination(
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long_rounded,
    label: 'Activity',
  ),
  WaltDestination(
    icon: Icons.savings_outlined,
    selectedIcon: Icons.savings_rounded,
    label: 'Budget',
  ),
  WaltDestination(
    icon: Icons.donut_large_outlined,
    selectedIcon: Icons.donut_large_rounded,
    label: 'Reports',
  ),
];
