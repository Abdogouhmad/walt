import 'package:flutter/material.dart';

/// The content model of a card: an optional header, an optional body, an
/// optional custom child and optional trailing actions.
class AppCardData {
  final String? title;
  final String? subtitle;
  final Color? colorCard;
  final String? body;
  final Widget? leading;
  final Widget? child;
  final List<Widget>? actions;
  final ShapeBorder? shape;

  const AppCardData({
    this.title,
    this.subtitle,
    this.colorCard,
    this.body,
    this.leading,
    this.child,
    this.actions,
    this.shape,
  });
}
