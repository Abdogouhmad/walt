import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The painter behind [WavyProgressIndicator]: an undulating stroke over a
/// flat track.
class WavyPainter extends CustomPainter {
  final double? progress;
  final double phase;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  WavyPainter({
    required this.progress,
    required this.phase,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final amplitude = (size.height - strokeWidth) / 2;
    // One wavelength per ~28px, but never finer than the stroke itself.
    final wavelength = math.max(28.0, strokeWidth * 4);

    Path wave(double startX, double endX) {
      final path = Path();
      var first = true;
      for (var x = startX; x <= endX; x += 1.0) {
        final y =
            centerY +
            math.sin((x / wavelength) * 2 * math.pi + phase) * amplitude;
        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
      }
      return path;
    }

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawLine(
      Offset(strokeWidth / 2, centerY),
      Offset(size.width - strokeWidth / 2, centerY),
      trackPaint,
    );

    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    final value = progress;
    if (value == null) {
      canvas.drawPath(wave(0, size.width), wavePaint);
    } else {
      canvas.save();
      canvas.clipRect(
        Rect.fromLTWH(0, 0, size.width * value.clamp(0.0, 1.0), size.height),
      );
      canvas.drawPath(wave(0, size.width), wavePaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant WavyPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.phase != phase ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
