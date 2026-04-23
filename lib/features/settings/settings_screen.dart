import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/features/settings/widgets/currency_selection_screen.dart';
import 'package:walt/features/settings/widgets/theme_selection_screen.dart';
import 'package:walt/features/settings/widgets/profile/header.dart';
import 'package:walt/shared/list_ui.dart';
import 'package:walt/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    Widget divider = SizedBox(height: 2);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const ProfileApp(),
              const SizedBox(height: 24),

              /// 🔹 PREFERENCES
              AppListSection(
                title: 'Preferences',
                children: [
                  AppListGroup(
                    useCard: false,
                    children: [
                      AppListTile(
                        style: ListStyle.outlined,
                        title: 'Theme',
                        subtitle: 'Change theme',
                        leading: const AppListAvatar(
                          icon: Icons.dark_mode_rounded,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ThemeSelectionScreen(),
                            ),
                          );
                        },
                      ),
                      divider,
                      AppListTile(
                        style: ListStyle.outlined,
                        title: 'Currency',
                        subtitle: 'MAD',
                        leading: const AppListAvatar(
                          icon: Icons.currency_exchange,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CurrencySelectionScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// 🔹 SECURITY
              AppListSection(
                title: 'Security',
                children: [
                  AppListGroup(
                    useCard: false,
                    children: [
                      AppListTile(
                        style: ListStyle.outlined,
                        title: 'Password Lock',
                        subtitle: 'Require password to open app',
                        leading: const AppListAvatar(icon: Icons.lock_outline),
                        trailing: Switch(
                          value: settings.isPasswordEnabled,
                          onChanged: (_) => settingsNotifier.togglePassword(),
                        ),
                      ),
                      divider,
                      AppListTile(
                        style: ListStyle.outlined,
                        title: 'Fingerprint',
                        subtitle: 'Use biometrics to unlock',
                        leading: const AppListAvatar(icon: Icons.fingerprint),
                        trailing: Switch(
                          value: settings.isFingerprintEnabled,
                          onChanged: (_) =>
                              settingsNotifier.toggleFingerprint(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// 🔹 Others
              AppListSection(
                title: 'Others',
                children: [
                  AppListGroup(
                    useCard: false,
                    children: [
                      AppListTile(
                        style: ListStyle.outlined,
                        title: 'About',
                        subtitle: 'V1.0.0',
                        leading: const AppListAvatar(icon: Icons.info),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ThemeSelectionScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
