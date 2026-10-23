import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The painter behind the budget progress wave.
///
/// The fill is a rounded track clipped to the current progress, but its leading
/// edge is a sine curve rather than a straight cut. [phase] animates that edge,
/// which is what makes the bar feel alive without moving the value itself.
class BudgetWavePainter extends CustomPainter {
  const BudgetWavePainter({
    required this.progress,
    required this.phase,
    required this.color,
    required this.trackColor,
    required this.todayFraction,
    required this.markerColor,
    this.leadingEdgeWidth = 24,
  });

  /// Already clamped to `0..1`.
  final double progress;
  final double phase;
  final Color color;
  final Color trackColor;

  /// Where "today" sits in the period, or null to hide the marker.
  final double? todayFraction;
  final Color markerColor;
  final double leadingEdgeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final barHeight = size.height * 0.58;
    final top = (size.height - barHeight) / 2;
    final radius = Radius.circular(barHeight / 2);
    final trackRect = Rect.fromLTWH(0, top, size.width, barHeight);

    final track = RRect.fromRectAndRadius(trackRect, radius);
    canvas.drawRRect(track, Paint()..color = trackColor);

    final clamped = progress.clamp(0.0, 1.0);
    final fillWidth = size.width * clamped;
    if (fillWidth > 0.5) {
      canvas.save();
      canvas.clipRRect(track);

      final amplitude = math.min(leadingEdgeWidth, barHeight * 0.42);
      final wavelength = math.max(12.0, barHeight * 0.9);
      final edgeX = fillWidth;

      // The path closes around the filled region. Sampling the edge vertically
      // (rather than horizontally) means the undulation reads as the *front* of
      // the fill, not as a ripple across the whole bar.
      final fill = Path()..moveTo(0, top);
      fill.lineTo(edgeX, top);
      for (var y = 0.0; y <= barHeight; y += 1.0) {
        final wave =
            math.sin((y / wavelength) * 2 * math.pi + phase) * amplitude;
        fill.lineTo(edgeX + wave, top + y);
      }
      fill
        ..lineTo(0, top + barHeight)
        ..close();

      canvas.drawPath(fill, Paint()..color = color);

      // A soft crest inside the fill gives the wave depth without introducing a
      // second, unrelated colour.
      canvas.save();
      canvas.translate(-leadingEdgeWidth * 0.55, 0);
      final crest = Path()..moveTo(0, top);
      crest.lineTo(edgeX, top);
      for (var y = 0.0; y <= barHeight; y += 1.0) {
        final wave =
            math.sin((y / wavelength) * 2 * math.pi + phase + 1.4) *
            amplitude *
            0.7;
        crest.lineTo(edgeX + wave, top + y);
      }
      crest
        ..lineTo(0, top + barHeight)
        ..close();
      canvas.drawPath(
        crest,
        Paint()
          ..color = Color.alphaBlend(
            Colors.white.withValues(alpha: 0.22),
            color,
          ),
      );
      canvas.restore();

      canvas.restore();
    }

    final today = todayFraction;
    if (today != null && today.isFinite) {
      final x = (size.width * today.clamp(0.0, 1.0)).clamp(
        1.0,
        size.width - 1.0,
      );
      final paint = Paint()
        ..color = markerColor
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      // Dashed marker, drawn inside the bar's height plus a small overhang.
      const dash = 3.0;
      const gap = 3.0;
      var y = top - 3;
      final end = top + barHeight + 3;
      while (y < end) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, math.min(y + dash, end)),
          paint,
        );
        y += dash + gap;
      }
      canvas.drawCircle(Offset(x, top - 3), 2.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BudgetWavePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.phase != phase ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.todayFraction != todayFraction ||
      oldDelegate.markerColor != markerColor ||
      oldDelegate.leadingEdgeWidth != leadingEdgeWidth;
}
