import 'package:flutter/material.dart';

import 'package:walt/core/design/radius.dart';
import 'package:walt/core/design/spacing.dart';
import 'package:walt/shared/text_ui.dart';

/// Semantic variants for [StatusBadge], each mapped to the matching
/// [ColorScheme] container / on-container pair.
///
/// Consolidates Walt's badge-like UI (spending-category tags, budget/over
/// budget states, "update available") into one shared pill (spec §1.3).
enum StatusBadgeVariant {
  /// Success / positive outcome (e.g. "Up to date", "Spent within budget").
  success,

  /// Warning / attention needed (e.g. "Approaching limit").
  warning,

  /// Error / critical state (e.g. "Over budget").
  error,

  /// Informational / neutral (e.g. category tag, flat delta).
  info,

  /// Accent / brand-colored variant (e.g. "Update available").
  accent,
}

/// Consistent status pill used across the app.
///
/// Uses the current [ColorScheme]'s container/on-container pairs so it
/// automatically adapts to dynamic color and dark/light mode.
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeVariant variant;
  final IconData? icon;
  final bool outlined;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = StatusBadgeVariant.info,
    this.icon,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (:foreground, :background) = _resolveColors(colorScheme);

    final shape = BoxDecoration(
      color: outlined ? background.withValues(alpha: 0.12) : background,
      borderRadius: BorderRadius.circular(AppRadius.full),
      border: outlined
          ? Border.all(color: foreground.withValues(alpha: 0.45))
          : null,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: shape,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          UiText(
            text: label,
            type: UiTextType.labelSmall,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  ({Color foreground, Color background}) _resolveColors(ColorScheme scheme) =>
      switch (variant) {
        StatusBadgeVariant.success => (
          foreground: scheme.onPrimaryContainer,
          background: scheme.primaryContainer,
        ),
        StatusBadgeVariant.warning => (
          foreground: scheme.onTertiaryContainer,
          background: scheme.tertiaryContainer,
        ),
        StatusBadgeVariant.error => (
          foreground: scheme.onErrorContainer,
          background: scheme.errorContainer,
        ),
        StatusBadgeVariant.info => (
          foreground: scheme.onSecondaryContainer,
          background: scheme.secondaryContainer,
        ),
        StatusBadgeVariant.accent => (
          foreground: scheme.onPrimaryContainer,
          background: scheme.primaryContainer,
        ),
      };
}

/// A live/idle dot indicator — used for update status, on/offline states, etc.
class LiveDot extends StatelessWidget {
  final Color color;
  final double size;

  const LiveDot({super.key, required this.color, this.size = 10});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}