import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/features/settings/services/appinfo.dart';
import 'package:walt/features/settings/widgets/about_screen.dart';
import 'package:walt/features/settings/widgets/currency_selection_screen.dart';
import 'package:walt/features/settings/widgets/ota_update_screen.dart';
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

    const Widget divider = SizedBox(height: 2);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const ProfileApp(),
              const SizedBox(height: 32),

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
                        subtitle: settings.currency,
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

              /// 🔹 SECURITY
              AppListSection(
                title: 'Security',
                children: [
                  AppListGroup(
                    useCard: false,
                    children: [
                      AppListTile(
                        style: ListStyle.outlined,
                        title: 'Fingerprint',
                        subtitle: 'Use biometrics to unlock',
                        leading: const AppListAvatar(icon: Icons.fingerprint),
                        trailing: Switch(
                          value: settings.isFingerprintEnabled,
                          onChanged: (val) async {
                            final success = await settingsNotifier
                                .toggleFingerprint(ref);
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
                ],
              ),

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
                        subtitle: 'about Walt v${Appinfo.version}',

                        leading: const AppListAvatar(icon: Icons.info),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AboutScreen(),
                            ),
                          );
                        },
                      ),
                      divider,
                      AppListTile(
                        style: ListStyle.outlined,
                        title: 'Update',
                        subtitle: 'Check for updates',
                        leading: const AppListAvatar(icon: Icons.update),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OtaUpdateScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
