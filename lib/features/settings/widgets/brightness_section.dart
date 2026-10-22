import 'package:flutter/material.dart';
import 'package:walt/features/settings/widgets/settings_leading.dart';
import 'package:walt_ui/walt_ui.dart';

/// The brightness section: light / dark / system, plus the pure-black switch.
class BrightnessSection extends StatelessWidget {
  const BrightnessSection({
    super.key,
    required this.mode,
    required this.amoled,
    required this.isDark,
    required this.onModeChanged,
    required this.onAmoledChanged,
  });

  final ThemeMode mode;
  final bool amoled;
  final bool isDark;
  final ValueChanged<ThemeMode> onModeChanged;
  final ValueChanged<bool> onAmoledChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Brightness'),
        GroupedList(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_rounded),
                    label: Text('System'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_rounded),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_rounded),
                    label: Text('Dark'),
                  ),
                ],
                selected: {mode},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) return;
                  Haptics.selection();
                  onModeChanged(selection.first);
                },
              ),
            ),
            // Disabled in light mode rather than hidden: a switch that vanishes
            // is a switch whose state the user cannot remember. The preference
            // itself is kept, so switching back to dark brings AMOLED with them.
            GroupedListTile(
              leading: const SettingsLeading(icon: Icons.contrast_rounded),
              title: const Text('Pure black'),
              subtitle: Text(
                isDark
                    ? 'True black surfaces for OLED panels'
                    : 'Available in dark mode',
              ),
              trailing: Switch(
                value: amoled,
                onChanged: isDark ? onAmoledChanged : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
