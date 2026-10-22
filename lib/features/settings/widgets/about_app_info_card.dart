import 'package:flutter/material.dart';

import 'package:walt/core/widgets/walt_logo.dart';
import 'package:walt/features/settings/services/appinfo.dart';
import 'package:walt_ui/walt_ui.dart';

/// The app info card on the About screen.
class AboutAppInfoCard extends StatelessWidget {
  const AboutAppInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return M3Ecard(
      variant: M3ECardVariant.outlined,
      data: AppCardData(
        colorCard: colors.surface,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const WaltLogo(size: 32, semanticLabel: null),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UiText(
                    text: Appinfo.appname,
                    type: UiTextType.titleLarge,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  UiText(
                    text: 'v${Appinfo.version}',
                    type: UiTextType.labelMedium,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
