import 'package:flutter/material.dart';

import '../tokens/radius.dart';
import '../tokens/spacing.dart';

/// The one card surface the app uses: a single elevation level, tonal
/// `surfaceContainer` fill, no border and no drop shadow.
/// The app's one and only card elevation, as tonal steps of `surfaceContainer`.
///
/// A single enum rather than a pile of booleans: "tonal" and "highlight" were
/// two independent flags describing one axis, which is how a screen ends up
/// asking for both at once.
enum AppCardLevel {
  /// Recessed: grouped-list rows and inline detail.
  lowest,

  /// The default resting surface.
  low,

  /// Raised one step, for a panel that needs to sit above its neighbours.
  high,

  /// The screen's single hero, tinted with the primary container.
  primary,
}

/// A tonal card: the app's single card surface.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadius.card,
    this.level = AppCardLevel.low,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Which of the app's single card elevation the surface sits at.
  ///
  /// One level of nesting, never two: a card inside a card reads as a card
  /// inside a card, not as hierarchy. [AppCardLevel.primary] is reserved for
  /// the one hero per screen — two heroes is the same as none.
  final AppCardLevel level;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = BorderRadius.circular(radius);

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: switch (level) {
          AppCardLevel.primary => scheme.primaryContainer,
          AppCardLevel.high => scheme.surfaceContainerHigh,
          AppCardLevel.low => scheme.surfaceContainerLow,
          AppCardLevel.lowest => scheme.surfaceContainerLowest,
        },
        borderRadius: shape,
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}
