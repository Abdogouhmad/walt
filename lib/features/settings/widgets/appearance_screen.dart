import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/features/settings/widgets/brightness_section.dart';
import 'package:walt/features/settings/widgets/custom_color_sheet.dart';
import 'package:walt/features/settings/widgets/feedback_section.dart';
import 'package:walt/features/settings/widgets/palette_grid.dart';
import 'package:walt/features/settings/widgets/surface_section.dart';
import 'package:walt/features/settings/widgets/theme_preview_card.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/providers/theme_provider.dart';
import 'package:walt_ui/walt_ui.dart';

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
                    BrightnessSection(
                      mode: settings.mode,
                      amoled: settings.amoled,
                      isDark: isDark,
                      onModeChanged: controller.setMode,
                      onAmoledChanged: controller.setAmoled,
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
                    PaletteGrid(
                      selected: settings.palette,
                      isCustom: settings.isCustom,
                      brightness: brightness,
                      onSelect: (palette) {
                        Haptics.selection();
                        controller.setPalette(palette);
                      },
                      onSelectCustom: () {
                        Haptics.selection();
                        showCustomColorSheet(context);
                      },
                    ),

                    // ── Surfaces ────────────────────────────────────────────
                    SurfaceSection(
                      reduceTransparency: appearance.reduceTransparency,
                      onReduceTransparencyChanged: ref
                          .read(settingsProvider.notifier)
                          .setReduceTransparency,
                    ),

                    // ── Feedback ────────────────────────────────────────────
                    const FeedbackSection(),

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
