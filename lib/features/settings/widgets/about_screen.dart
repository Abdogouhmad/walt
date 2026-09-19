import 'package:flutter/material.dart';

import 'package:walt/core/design/spacing.dart';
import 'package:walt/features/settings/services/appinfo.dart';
import 'package:walt/features/settings/widgets/socialmedia.dart';
import 'package:walt/shared/m3e_card.dart';
import 'package:walt/shared/text_ui.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          UiText(
            text: 'About',
            type: UiTextType.headlineLarge,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          UiText(
            text: Appinfo.appname,
            type: UiTextType.bodyMedium,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),

          /// App info card
          M3Ecard(
            variant: M3ECardVariant.outlined,
            data: AppCardData(
              colorCard: colors.surface,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: colors.primaryContainer,
                    foregroundImage: const AssetImage('assets/icons/wallet.png'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UiText(
                          text: Appinfo.appname,
                          type: UiTextType.titleLarge,
                          style: TextStyle(fontWeight: FontWeight.w600),
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
          ),

          const SizedBox(height: AppSpacing.md),

          /// Developer card
          M3Ecard(
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
                        backgroundImage: const AssetImage('assets/cat.jpeg'),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            UiText(
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
                                  url: "https://github.com/Abdogouhmad",
                                ),
                                SizedBox(width: AppSpacing.sm),
                                SocialBubble(
                                  icon: Icons.message,
                                  url: "mailto:gouhmad@hotmail.com",
                                ),
                                SizedBox(width: AppSpacing.sm),
                                SocialBubble(
                                  icon: Icons.web_asset_rounded,
                                  url: "https://agouhmad.vercel.app/",
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
          ),

          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}