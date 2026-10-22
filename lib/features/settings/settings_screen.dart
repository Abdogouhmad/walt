import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/features/settings/services/appinfo.dart';
import 'package:walt/features/settings/widgets/about_info_dialog.dart';
import 'package:walt/features/settings/widgets/appearance_screen.dart';
import 'package:walt/features/settings/widgets/budget_alerts_section.dart';
import 'package:walt/features/settings/widgets/currency_selection_screen.dart';
import 'package:walt/features/settings/widgets/fingerprint_section.dart';
import 'package:walt/features/settings/widgets/profile/header.dart';
import 'package:walt/features/settings/widgets/settings_action_tile.dart';
import 'package:walt/features/settings/widgets/update_section.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/providers/theme_provider.dart';
import 'package:walt_ui/walt_ui.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = ref.watch(themeControllerProvider);

    return Scaffold(
      // Deliberately *not* transparent, unlike the four tab screens. Settings
      // is pushed on the root navigator, so a transparent Scaffold has nothing
      // of its own behind it and the platform window shows through as black.
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(title: Text('Settings')),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: WaltChrome.constrain(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ProfileApp(),

                    const SectionHeader(title: 'Preferences'),
                    GroupedList(
                      children: [
                        SettingsActionTile(
                          icon: Icons.palette_rounded,
                          title: 'Appearance',
                          // Names the actual choice, so the row answers "is my
                          // colour still set?" without a trip down the stack.
                          subtitle: '${theme.label} · ${modeLabel(theme.mode)}',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AppearanceScreen(),
                            ),
                          ),
                        ),
                        SettingsActionTile(
                          icon: Icons.currency_exchange_rounded,
                          title: 'Currency',
                          subtitle: settings.currency,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CurrencySelectionScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const FingerprintSection(),
                    const BudgetAlertsSection(),

                    const SectionHeader(title: 'Others'),
                    GroupedList(
                      children: [
                        SettingsActionTile(
                          icon: Icons.info_rounded,
                          title: 'About',
                          subtitle: 'about Walt v${Appinfo.version}',
                          onTap: () => AboutInfoDialog.show(context),
                        ),
                        const UpdateSection(),
                      ],
                    ),

                    SizedBox(height: WaltChrome.scrollBottomPadding(context)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The `ThemeMode` as it is written on screen.
String modeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'System',
  ThemeMode.light => 'Light',
  ThemeMode.dark => 'Dark',
};
