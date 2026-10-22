import 'package:flutter/material.dart';

/// One action inside [ExpressiveFabMenu].
@immutable
class FabAction {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? foregroundColor;
  final Color? backgroundColor;

  const FabAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.foregroundColor,
    this.backgroundColor,
  });
}
