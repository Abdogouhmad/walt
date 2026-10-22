import 'package:flutter/material.dart';

/// At most one soft shadow, applied uniformly on both sides so light and dark
/// mode read the same.
class SurfaceShadow extends StatelessWidget {
  const SurfaceShadow({
    super.key,
    required this.child,
    required this.radius,
    required this.enabled,
  });

  final Widget child;
  final double radius;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            // The scheme's own `shadow` role rather than a literal black: on a
            // dark surface a pure-black drop shadow is invisible, so the alpha
            // carries the whole difference, and the role is what M3 exposes for
            // exactly this.
            color: Theme.of(
              context,
            ).colorScheme.shadow.withValues(alpha: isDark ? 0.45 : 0.10),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
