import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A circle with [lobes] soft bumps — the "cookie" silhouette used by the
/// empty state. It gently morphs between two amplitudes unless the user has
/// disabled animations.
class ScallopedContainer extends StatefulWidget {
  final Widget child;
  final double size;
  final int lobes;
  final Color? color;

  const ScallopedContainer({
    super.key,
    required this.child,
    this.size = 104,
    this.lobes = 12,
    this.color,
  });

  @override
  State<ScallopedContainer> createState() => _ScallopedContainerState();
}

class _ScallopedContainerState extends State<ScallopedContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honour the platform reduced-motion switch, including live changes.
    final disabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disabled) {
      if (_controller.isAnimating) _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.color ?? Theme.of(context).colorScheme.secondaryContainer;
    // Amplitude in pixels; the two ends of the breathe cycle.
    final minAmp = widget.size * 0.015;
    final maxAmp = widget.size * 0.04;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_controller.value);
          final amplitude = minAmp + (maxAmp - minAmp) * t;
          return ClipPath(
            clipper: _ScallopedClipper(
              lobes: widget.lobes,
              amplitude: amplitude,
            ),
            child: ColoredBox(color: color, child: child),
          );
        },
        child: Center(child: widget.child),
      ),
    );
  }
}

class _ScallopedClipper extends CustomClipper<Path> {
  final int lobes;
  final double amplitude;

  const _ScallopedClipper({required this.lobes, required this.amplitude});

  @override
  Path getClip(Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - amplitude - 1;
    const steps = 240;
    final path = Path();

    for (var i = 0; i <= steps; i++) {
      final angle = i / steps * 2 * math.pi;
      final r = radius + amplitude * math.sin(angle * lobes);
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _ScallopedClipper oldClipper) =>
      oldClipper.lobes != lobes || oldClipper.amplitude != amplitude;
}
