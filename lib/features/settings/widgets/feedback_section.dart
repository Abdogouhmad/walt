import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/features/settings/widgets/settings_leading.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt_ui/walt_ui.dart';

/// Haptics and animations toggles.
class FeedbackSection extends ConsumerWidget {
  const FeedbackSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Feedback'),
        GroupedList(
          children: [
            GroupedListTile(
              leading: const SettingsLeading(icon: Icons.vibration_rounded),
              title: const Text('Haptics'),
              subtitle: const Text('Vibration on taps and actions'),
              trailing: Switch(
                value: appearance.hapticsEnabled,
                onChanged: notifier.setHapticsEnabled,
              ),
            ),
            GroupedListTile(
              leading: const SettingsLeading(icon: Icons.animation_rounded),
              title: const Text('Animations'),
              subtitle: const Text('Transitions and motion effects'),
              trailing: Switch(
                value: appearance.animationsEnabled,
                onChanged: notifier.setAnimationsEnabled,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
