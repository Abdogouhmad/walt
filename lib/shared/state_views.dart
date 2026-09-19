import 'package:flutter/material.dart';

import 'package:walt/core/design/motion.dart';
import 'package:walt/core/design/radius.dart';
import 'package:walt/core/design/spacing.dart';
import 'package:walt/shared/text_ui.dart';

/// One visual treatment for "there is nothing here yet" (empty expenses,
/// empty budgets, …) so no screen invents its own (spec §1.1).
class EmptyStateView extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  const EmptyStateView({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 44,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            UiText(
              text: title,
              type: UiTextType.titleMedium,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              UiText(
                text: message!,
                type: UiTextType.bodyMedium,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
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

/// One loading treatment — a centered, scheme-coloured spinner.
class LoadingStateView extends StatelessWidget {
  final String? label;

  const LoadingStateView({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          if (label != null) ...[
            const SizedBox(height: AppSpacing.md),
            UiText(
              text: label!,
              type: UiTextType.bodyMedium,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One inline error treatment, e.g. for a failed network check or a failed
/// data load — the consistent "something broke, tap to retry" row.
class InlineErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const InlineErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colorScheme.error),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: UiText(
              text: message,
              type: UiTextType.bodyMedium,
              style: TextStyle(color: colorScheme.onErrorContainer),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onRetry != null)
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

/// Tactile press "sink" micro-motion (M3 Expressive): tappable surfaces scale
/// down slightly while pressed. Used by the shared cards and update UI.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PressableScale({super.key, required this.child, this.onTap});

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _pressed = false),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: AppMotion.short,
        curve: AppMotion.standard,
        child: widget.child,
      ),
    );
  }
}