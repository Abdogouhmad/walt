import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/features/settings/widgets/settings_leading.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt_ui/walt_ui.dart';

/// The security section: the biometric unlock switch.
class FingerprintSection extends ConsumerWidget {
  const FingerprintSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Security'),
        GroupedList(
          children: [
            GroupedListTile(
              leading: const SettingsLeading(icon: Icons.fingerprint_rounded),
              title: const Text('Fingerprint'),
              subtitle: const Text('Use biometrics to unlock'),
              trailing: Switch(
                value: settings.isFingerprintEnabled,
                onChanged: (value) async {
                  final success = await notifier.toggleFingerprint();
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Authentication failed or not available'),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
