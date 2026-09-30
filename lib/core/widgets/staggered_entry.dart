import 'package:flutter/material.dart';

import 'package:walt/core/theme/motion.dart';

/// Fades and slides a list row into place on first build, staggered by its
/// [index] (spec §5). The whole cascade is capped at ~300 ms so it never feels
/// like a loading animation.
class StaggeredEntry extends StatefulWidget {
  final int index;
  final Widget child;

  /// Vertical travel at the start of the animation.
  final double slideOffset;

  const StaggeredEntry({
    super.key,
    required this.index,
    required this.child,
    this.slideOffset = 12,
  });

  @override
  State<StaggeredEntry> createState() => _StaggeredEntryState();
}

class _StaggeredEntryState extends State<StaggeredEntry>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 180);
  static const int _stepMillis = 35;
  static const int _maxDelayMillis = 120;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
  );

  @override
  void initState() {
    super.initState();
    final delay = (widget.index * _stepMillis).clamp(0, _maxDelayMillis);
    Future<void>.delayed(Duration(milliseconds: delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppSpring.isDisabled(context)) {
      return widget.child;
    }

    final curved = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.standard,
    );

    return FadeTransition(
      opacity: curved,
      child: AnimatedBuilder(
        animation: curved,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, (1 - curved.value) * widget.slideOffset),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
