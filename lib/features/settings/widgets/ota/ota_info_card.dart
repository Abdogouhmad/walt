import 'package:flutter/material.dart';
import 'package:walt_ui/walt_ui.dart';

/// The shared outlined card shell for the update screen's info sections.
class OtaInfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const OtaInfoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.surface),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.field),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              UiText(
                text: title,
                type: UiTextType.titleMedium,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

/// One `icon | label | value` line inside an [OtaInfoCard].
class OtaInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const OtaInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 24, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          UiText(
            text: label,
            type: UiTextType.bodyMedium,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const Spacer(),
          UiText(
            text: value,
            type: UiTextType.bodyMedium,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: highlight ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// The hairline between two [OtaInfoRow]s.
Widget otaDivider(BuildContext context) => Divider(
  height: 1,
  color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6),
);
