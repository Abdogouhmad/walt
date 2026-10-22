import 'package:flutter/material.dart';
import 'package:walt_ui/walt_ui.dart';

import 'ota_info_card.dart';

/// Download progress with a determinate linear bar + percentage.
class OtaDownloadCard extends StatelessWidget {
  final double progress;

  const OtaDownloadCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percent = ((progress * 100).clamp(0, 100)).toStringAsFixed(0);

    return OtaInfoCard(
      title: 'Downloading update',
      icon: Icons.download_rounded,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            UiText(
              text: 'Downloading…',
              type: UiTextType.bodyMedium,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            UiText(
              text: '$percent%',
              type: UiTextType.titleSmall,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 10,
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

/// Ready-to-install success state with the handoff CTA.
class OtaReadyCard extends StatelessWidget {
  final VoidCallback onChangePressed;

  const OtaReadyCard({super.key, required this.onChangePressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 64),
        const SizedBox(height: AppSpacing.md),
        UiText(
          text: 'The update is verified and ready to install.',
          type: UiTextType.bodyMedium,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Install now',
          icon: Icons.download_done_rounded,
          type: ButtonType.textIcon,
          isFullWidth: true,
          size: ButtonSize.large,
          onPressed: onChangePressed,
        ),
      ],
    );
  }
}
