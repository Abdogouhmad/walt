import 'package:flutter/material.dart';

import 'package:walt/features/settings/widgets/socialmedia.dart';
import 'package:walt_ui/walt_ui.dart';

/// The developer card on the About screen.
class AboutDeveloperCard extends StatelessWidget {
  const AboutDeveloperCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return M3Ecard(
      variant: M3ECardVariant.outlined,
      data: AppCardData(
        colorCard: colors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colors.primaryContainer,
                  // Decode at the drawn size (radius 30 → 60 dp) instead
                  // of the full 736×612 source (~1.8 MB decoded).
                  backgroundImage: const ResizeImage(
                    AssetImage('assets/cat.jpeg'),
                    width: 120,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const UiText(
                        text: 'Abdogouhmad',
                        type: UiTextType.titleLarge,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      UiText(
                        text: 'Developer',
                        type: UiTextType.bodySmall,
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Row(
                        children: [
                          SocialBubble(
                            icon: Icons.code,
                            url: 'https://github.com/Abdogouhmad',
                          ),
                          SizedBox(width: AppSpacing.sm),
                          SocialBubble(
                            icon: Icons.message,
                            url: 'mailto:gouhmad@hotmail.com',
                          ),
                          SizedBox(width: AppSpacing.sm),
                          SocialBubble(
                            icon: Icons.web_asset_rounded,
                            url: 'https://agouhmad.vercel.app/',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
