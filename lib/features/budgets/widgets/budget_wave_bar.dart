import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:walt/features/budgets/widgets/budget_wave_painter.dart';

/// Animated budget progress bar with a sine leading edge.
///
/// Respects [MediaQuery.disableAnimations]: the wave freezes at its current
/// phase rather than stopping mid-stroke, and the fill animates at reduced
/// speed.
class BudgetWaveBar extends StatefulWidget {
  const BudgetWaveBar({
    super.key,
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.todayFraction,
    this.markerColor,
    this.height = 14,
    this.duration = const Duration(milliseconds: 900),
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double todayFraction;
  final Color? markerColor;
  final double height;
  final Duration duration;

  @override
  State<BudgetWaveBar> createState() => _BudgetWaveBarState();
}

class _BudgetWaveBarState extends State<BudgetWaveBar>
    with TickerProviderStateMixin {
  late final AnimationController _fillController = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final AnimationController _waveController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  late Animation<double> _fill =
      Tween<double>(begin: 0, end: widget.progress.clamp(0.0, 1.0)).animate(
        CurvedAnimation(parent: _fillController, curve: Curves.easeOutCubic),
      );

  bool _disableAnimations = false;

  double get _clamped => widget.progress.clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _fillController.forward();
    _waveController.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disabled == _disableAnimations) return;
    _disableAnimations = disabled;

    if (disabled) {
      // Stop the ticker instead of merely painting a frozen phase: an
      // animation that keeps scheduling frames but always draws the same thing
      // is pure battery drain.
      _waveController.stop();
      _fillController.value = 1;
    } else {
      _waveController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant BudgetWaveBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _fill = Tween<double>(begin: _fill.value, end: _clamped).animate(
        CurvedAnimation(parent: _fillController, curve: Curves.easeOutCubic),
      );
      if (_disableAnimations) {
        _fillController.value = 1;
      } else {
        _fillController
          ..reset()
          ..forward();
      }
    }
    if (oldWidget.duration != widget.duration) {
      _fillController.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _fillController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final marker =
        widget.markerColor ?? scheme.onSurface.withValues(alpha: 0.5);

    Widget painter(double phase) {
      return CustomPaint(
        painter: BudgetWavePainter(
          progress: _fill.value,
          phase: phase,
          color: widget.color,
          trackColor: widget.trackColor,
          todayFraction: widget.todayFraction,
          markerColor: marker,
        ),
      );
    }

    return SizedBox(
      height: widget.height + 10,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: Listenable.merge([_fillController, _waveController]),
        builder: (context, _) {
          final phase = disabled ? 0.0 : _waveController.value * 2 * math.pi;
          return painter(phase);
        },
      ),
    );
  }
}
