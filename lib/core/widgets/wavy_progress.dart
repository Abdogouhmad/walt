import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A wavy progress indicator, reserved for **loading states only** (spec §3).
///
/// This is the app's deliberately small expressive accent for "something is
/// happening": a rounded stroke that undulates while indeterminate. It is a
/// custom painter rather than a package so there is no fragile dependency and
/// no extra glyphs.
class WavyProgressIndicator extends StatefulWidget {
  /// 0.0–1.0 for a determinate wave, or null to undulate indefinitely.
  final double? value;

  final double height;
  final Color? color;
  final Color? trackColor;

  const WavyProgressIndicator({
    super.key,
    this.value,
    this.height = 8,
    this.color,
    this.trackColor,
  });

  @override
  State<WavyProgressIndicator> createState() => _WavyProgressIndicatorState();
}

class _WavyProgressIndicatorState extends State<WavyProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  bool get _indeterminate => widget.value == null;

  @override
  void initState() {
    super.initState();
    if (_indeterminate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant WavyProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_indeterminate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!_indeterminate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final waveColor = widget.color ?? scheme.primary;
    final trackColor = widget.trackColor ?? scheme.surfaceContainerHighest;

    final disabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _WavyPainter(
              progress: widget.value,
              phase: disabled ? 0 : _controller.value * 2 * math.pi,
              color: waveColor,
              trackColor: trackColor,
              strokeWidth: widget.height * 0.55,
            ),
          );
        },
      ),
    );
  }
}

class _WavyPainter extends CustomPainter {
  final double? progress;
  final double phase;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _WavyPainter({
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
  bool shouldRepaint(covariant _WavyPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.phase != phase ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
