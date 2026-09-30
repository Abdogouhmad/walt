import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/core/design/radius.dart';
import 'package:walt/core/design/spacing.dart';
import 'package:walt/core/theme/color_schemes.dart';
import 'package:walt/core/theme/walt_palette.dart';
import 'package:walt/core/widgets/grouped_list.dart';
import 'package:walt/core/widgets/section_header.dart';
import 'package:walt/core/widgets/walt_chrome.dart';
import 'package:walt/features/settings/widgets/custom_color_sheet.dart';
import 'package:walt/features/settings/widgets/palette_swatch.dart';
import 'package:walt/features/settings/widgets/settings_leading.dart';
import 'package:walt/features/settings/widgets/theme_preview_card.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/providers/theme_provider.dart';

/// Settings → Preferences → Appearance.
///
/// Three decisions, in the order they are usually made: how bright, then what
/// colour, then the fine print. The palette grid is the reason this screen
/// exists; everything else on it is a switch.
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);
    final appearance = ref.watch(settingsProvider);

    // Resolved, not requested: with mode `system` the effective brightness is
    // whatever the platform says, and the AMOLED switch has to describe the
    // screen the user is actually looking at.
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(title: Text('Appearance')),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: WaltChrome.constrain(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Brightness ──────────────────────────────────────────
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
                            selected: {settings.mode},
                            showSelectedIcon: false,
                            onSelectionChanged: (selection) {
                              if (selection.isEmpty) return;
                              HapticFeedback.selectionClick();
                              controller.setMode(selection.first);
                            },
                          ),
                        ),
                        // Disabled in light mode rather than hidden: a switch
                        // that vanishes is a switch whose state the user cannot
                        // remember. The preference itself is kept, so switching
                        // back to dark brings AMOLED with them.
                        GroupedListTile(
                          leading: const SettingsLeading(
                            icon: Icons.contrast_rounded,
                          ),
                          title: const Text('Pure black'),
                          subtitle: Text(
                            isDark
                                ? 'True black surfaces for OLED panels'
                                : 'Available in dark mode',
                          ),
                          trailing: Switch(
                            value: settings.amoled,
                            onChanged: isDark ? controller.setAmoled : null,
                          ),
                        ),
                      ],
                    ),

                    // ── Colour ──────────────────────────────────────────────
                    SectionHeader(
                      title: 'Colour',
                      trailing: Text(
                        settings.label,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                    ThemePreviewCard(settings: settings),
                    const SizedBox(height: AppSpacing.md),
                    _PaletteGrid(
                      selected: settings.palette,
                      isCustom: settings.isCustom,
                      brightness: brightness,
                      onSelect: (palette) {
                        HapticFeedback.selectionClick();
                        controller.setPalette(palette);
                      },
                      onSelectCustom: () {
                        HapticFeedback.selectionClick();
                        showCustomColorSheet(context, ref);
                      },
                    ),

                    // ── Surfaces ────────────────────────────────────────────
                    const SectionHeader(title: 'Surfaces'),
                    GroupedList(
                      children: [
                        GroupedListTile(
                          leading: const SettingsLeading(
                            icon: Icons.blur_on_rounded,
                          ),
                          title: const Text('Reduce transparency'),
                          subtitle: const Text(
                            'Replace blurred surfaces with solid ones',
                          ),
                          trailing: Switch(
                            value: appearance.reduceTransparency,
                            onChanged: ref
                                .read(settingsProvider.notifier)
                                .setReduceTransparency,
                          ),
                        ),
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

/// The wrapping grid of palettes.
///
/// A `Wrap` rather than a `GridView`: nine fixed-width discs of [PaletteSwatch]
/// plus one "Custom" tile flow to as many rows as the width allows, which is the
/// only layout that works on a 320dp phone and a 600dp tablet without a
/// breakpoint.
class _PaletteGrid extends StatelessWidget {
  const _PaletteGrid({
    required this.selected,
    required this.isCustom,
    required this.brightness,
    required this.onSelect,
    required this.onSelectCustom,
  });

  final WaltPalette selected;
  final bool isCustom;
  final Brightness brightness;
  final ValueChanged<WaltPalette> onSelect;
  final VoidCallback onSelectCustom;

  @override
  Widget build(BuildContext context) {
    final appScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: AppRadius.sm,
      runSpacing: AppSpacing.md,
      alignment: WrapAlignment.center,
      children: [
        // Generated per palette, at the brightness on screen: each disc needs
        // the scheme *its own* seed produces, not a copy of the active one.
        for (final palette in WaltPalette.values)
          PaletteSwatch(
            label: palette.label,
            scheme: AppColorSchemes.forPalette(palette, brightness: brightness),
            selected: !isCustom && palette == selected,
            onTap: () => onSelect(palette),
          ),
        PaletteSwatch(
          label: 'Custom',
          scheme: appScheme,
          selected: isCustom,
          custom: true,
          onTap: onSelectCustom,
        ),
      ],
    );
  }
}
