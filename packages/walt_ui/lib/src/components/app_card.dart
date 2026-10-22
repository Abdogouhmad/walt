import 'package:flutter/material.dart';

import '../tokens/motion.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';
import './app_card_data.dart';
import './state_views.dart';
import './ui_text.dart';

// ─── Variants ────────────────────────────────────────────────────────────────

enum M3ECardVariant { elevated, filled, outlined }

// ─── Widget ──────────────────────────────────────────────────────────────────

class M3Ecard extends StatelessWidget {
  const M3Ecard({
    super.key,
    required this.data,
    this.variant = M3ECardVariant.elevated,
    this.onTap,
    this.padding,
  });

  final AppCardData data;
  final M3ECardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context);
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row — only rendered when there is something to put in it;
          // title-less cards (budget rows, about cards) must not add an empty
          // header band above their body.
          if (data.title != null || data.leading != null)
            Row(
              children: [
                if (data.leading != null) ...[
                  data.leading!,
                  const SizedBox(width: AppSpacing.lg),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UiText(
                        text: data.title ?? '',
                        type: UiTextType.titleMedium,
                        style: TextStyle(
                          color: scheme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (data.subtitle != null)
                        UiText(
                          text: data.subtitle!,
                          type: UiTextType.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),

          // Body
          if (data.body != null) ...[
            const SizedBox(height: AppSpacing.lg),
            UiText(text: data.body!, type: UiTextType.bodyMedium),
          ],

          if (data.child != null) ...[
            if (data.title != null || data.leading != null)
              const SizedBox(height: AppSpacing.md),
            data.child!,
          ],
          // Actions
          if (data.actions != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: data.actions!,
            ),
          ],
        ],
      ),
    );

    final surfaceRadius =
        data.shape ??
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.surface),
          side: BorderSide(color: scheme.colorScheme.outlineVariant, width: 1),
        );

    // The ripple should follow the card's shape; only RoundedRectangleBorder
    // exposes a borderRadius, so fall back to the surfaced radius otherwise.
    final inkRadius = surfaceRadius is RoundedRectangleBorder
        ? (surfaceRadius.borderRadius as BorderRadius)
        : BorderRadius.circular(AppRadius.surface);

    final card = switch (variant) {
      M3ECardVariant.elevated => Card(
        color: data.colorCard,
        shape: surfaceRadius,
        elevation: 1,
        child: InkWell(onTap: onTap, borderRadius: inkRadius, child: content),
      ),
      M3ECardVariant.filled => Card.filled(
        color: data.colorCard,
        shape: surfaceRadius,
        child: InkWell(onTap: onTap, borderRadius: inkRadius, child: content),
      ),
      M3ECardVariant.outlined => Card.outlined(
        borderOnForeground: true,
        color: data.colorCard,
        shape: surfaceRadius,
        elevation: 0,
        child: InkWell(onTap: onTap, borderRadius: inkRadius, child: content),
      ),
    };

    // Tactile scale/fill transition on press (spec §1.1 "M3 Expressive").
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.short,
        curve: AppMotion.standard,
        child: card,
      ),
    );
  }
}
