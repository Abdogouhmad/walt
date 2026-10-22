import 'package:flutter/material.dart';

/// Height that [text] will occupy once laid out with [style].
///
/// Uses the ambient [TextScaler], so a 200% system text scale is measured
/// as 200% rather than being silently ignored.
double measureTextHeight(BuildContext context, String text, TextStyle? style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  return painter.height;
}
