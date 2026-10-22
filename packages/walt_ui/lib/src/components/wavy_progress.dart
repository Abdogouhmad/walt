import 'dart:math' as math;

import 'package:flutter/material.dart';

import './wavy_painter.dart';

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
            painter: WavyPainter(
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
