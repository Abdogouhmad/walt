import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/core/design/spacing.dart';
import 'package:walt/core/widgets/grouped_list.dart';
import 'package:walt/core/widgets/section_header.dart';
import 'package:walt/core/widgets/walt_chrome.dart';
import 'package:walt/data/services/notification_preferences.dart';
import 'package:walt/features/settings/services/appinfo.dart';
import 'package:walt/features/settings/widgets/about_info_dialog.dart';
import 'package:walt/features/settings/widgets/appearance_screen.dart';
import 'package:walt/features/settings/widgets/currency_selection_screen.dart';
import 'package:walt/features/settings/widgets/profile/header.dart';
import 'package:walt/features/settings/widgets/settings_leading.dart';
import 'package:walt/features/settings/widgets/update_section.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
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
                        _ActionTile(
                          icon: Icons.palette_rounded,
                          title: 'Appearance',
                          // Names the actual choice, so the row answers "is my
                          // colour still set?" without a trip down the stack.
                          subtitle:
                              '${theme.label} · ${_modeLabel(theme.mode)}',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AppearanceScreen(),
                            ),
                          ),
                        ),
                        _ActionTile(
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

                    const SectionHeader(title: 'Security'),
                    GroupedList(
                      children: [
                        GroupedListTile(
                          leading: const SettingsLeading(
                            icon: Icons.fingerprint_rounded,
                          ),
                          title: const Text('Fingerprint'),
                          subtitle: const Text('Use biometrics to unlock'),
                          trailing: Switch(
                            value: settings.isFingerprintEnabled,
                            onChanged: (value) async {
                              final success = await settingsNotifier
                                  .toggleFingerprint();
                              if (!success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Authentication failed or not available',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SectionHeader(title: 'Notifications'),
                    GroupedList(
                      children: [
                        GroupedListTile(
                          leading: const SettingsLeading(
                            icon: Icons.account_balance_wallet_rounded,
                          ),
                          title: const Text('Budget alerts'),
                          subtitle: const Text(
                            'Notify when you reach 80% or pass a limit',
                          ),
                          trailing: Switch(
                            value: settings.budgetAlertsEnabled,
                            onChanged: (value) async {
                              // Ask in context: the OS prompt is far more likely
                              // to be granted when it follows a deliberate tap
                              // than when it appears unprompted at startup.
                              if (value) await requestNotificationPermission();
                              await settingsNotifier.setBudgetAlertsEnabled(
                                value,
                              );
                              await evaluateBudgetAlertsNow(ref);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SectionHeader(title: 'Others'),
                    GroupedList(
                      children: [
                        _ActionTile(
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

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GroupedListTile(
      leading: SettingsLeading(icon: icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

/// The `ThemeMode` as it is written on screen.
String _modeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'System',
  ThemeMode.light => 'Light',
  ThemeMode.dark => 'Dark',
};
