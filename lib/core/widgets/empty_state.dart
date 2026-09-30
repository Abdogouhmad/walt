import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:walt/core/design/spacing.dart';

/// One visual treatment for "there is nothing here yet" (spec §3).
///
/// The icon sits inside a softly scalloped "cookie" shape that breathes
/// gently, then a short title, an optional body and a single action. Screens
/// must use this instead of inventing their own empty state.
class WaltEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const WaltEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ScallopedContainer(
              size: 104,
              color: scheme.secondaryContainer.withValues(alpha: 0.75),
              child: Icon(icon, size: 44, color: scheme.onSecondaryContainer),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// A circle with [lobes] soft bumps — the "cookie" silhouette used by
/// [WaltEmptyState]. It gently morphs between two amplitudes unless the user
/// has disabled animations.
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
