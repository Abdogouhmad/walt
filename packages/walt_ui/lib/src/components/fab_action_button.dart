import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/motion.dart';
import 'fab_action.dart';

/// One labelled action in the expanded FAB menu.
///
/// It slides up and fades in behind the FAB, staggered by [index] so the
/// action nearest the FAB leads.
class FabActionButton extends StatelessWidget {
  final FabAction action;
  final AnimationController controller;
  final int index;
  final double right;
  final double bottom;
  final bool reduceMotion;
  final VoidCallback onDismiss;

  const FabActionButton({
    super.key,
    required this.action,
    required this.controller,
    required this.index,
    required this.right,
    required this.bottom,
    required this.reduceMotion,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // Stagger: the action closest to the FAB leads, the rest trail by 80 ms.
    final begin = (index * 0.08).clamp(0.0, 0.4);
    final end = (begin + 0.55).clamp(0.0, 1.0);

    final animation = reduceMotion
        ? const AlwaysStoppedAnimation<double>(1)
        : CurvedAnimation(
            parent: controller,
            curve: Interval(begin, end, curve: AppSpring.spatialCurve),
            reverseCurve: Interval(0, end, curve: Curves.easeIn),
          );

    final scheme = Theme.of(context).colorScheme;
    final fg = action.foregroundColor ?? scheme.onSurface;
    final bg = action.backgroundColor ?? scheme.surfaceContainerHigh;

    return Positioned(
      right: right,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final t = animation.value.clamp(0.0, 1.2);
          return Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 24),
              child: Transform.scale(
                scale: 0.85 + 0.15 * t,
                alignment: AlignmentDirectional.bottomEnd,
                child: child,
              ),
            ),
          );
        },
        child: Semantics(
          button: true,
          label: action.label,
          child: Material(
            color: bg,
            elevation: 2,
            shadowColor: scheme.shadow,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onDismiss();
                action.onPressed();
              },
              customBorder: const StadiumBorder(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      action.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(action.icon, size: 20, color: fg),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
