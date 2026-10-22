import 'package:flutter/material.dart';
import 'package:walt/features/settings/widgets/settings_leading.dart';
import 'package:walt_ui/walt_ui.dart';

/// The surfaces section: the one switch that swaps blurred surfaces for solid
/// ones.
class SurfaceSection extends StatelessWidget {
  const SurfaceSection({
    super.key,
    required this.reduceTransparency,
    required this.onReduceTransparencyChanged,
  });

  final bool reduceTransparency;
  final ValueChanged<bool> onReduceTransparencyChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Surfaces'),
        GroupedList(
          children: [
            GroupedListTile(
              leading: const SettingsLeading(icon: Icons.blur_on_rounded),
              title: const Text('Reduce transparency'),
              subtitle: const Text('Replace blurred surfaces with solid ones'),
              trailing: Switch(
                value: reduceTransparency,
                onChanged: onReduceTransparencyChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
