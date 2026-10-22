import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/features/settings/services/appinfo.dart';
import 'package:walt/features/settings/widgets/about_app_info_card.dart';
import 'package:walt/features/settings/widgets/about_developer_card.dart';
import 'package:walt/features/settings/widgets/ota_update_screen.dart';
import 'package:walt/features/settings/widgets/update_banner.dart';
import 'package:walt_ui/walt_ui.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          // Soft, dismissible, inline. Never a dialog or a takeover screen.
          UpdateBanner(
            onOpen: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const OtaUpdateScreen())),
            onInstall: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const OtaUpdateScreen())),
          ),
          const UiText(
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
          const AboutAppInfoCard(),

          const SizedBox(height: AppSpacing.md),

          /// Developer card
          const AboutDeveloperCard(),

          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
