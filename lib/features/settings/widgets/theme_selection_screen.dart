import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/core/constants/app_colors.dart';
import 'package:walt/core/utils/context.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/text_ui.dart';

class ThemeSelectionScreen extends ConsumerWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UiText(
              text: 'Theme',
              type: UiTextType.headlineLarge,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 4),

            UiText(
              text: "Select your preferred Theme",
              type: UiTextType.bodyMedium,
              style: TextStyle(color: context.colorAppScheme.onSurfaceVariant),
            ),

            const SizedBox(height: 20),

            _buildThemeOption(
              context,
              ref,
              'Light Mode',
              ThemeMode.light,
              settings.themeMode == ThemeMode.light,
            ),
            const SizedBox(height: 12),
            _buildThemeOption(
              context,
              ref,
              'Dark Mode',
              ThemeMode.dark,
              settings.themeMode == ThemeMode.dark,
            ),
            const SizedBox(height: 12),
            _buildThemeOption(
              context,
              ref,
              'System Default',
              ThemeMode.system,
              settings.themeMode == ThemeMode.system,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    String title,
    ThemeMode mode,
    bool isSelected,
  ) {
    IconData icon;

    switch (mode) {
      case ThemeMode.light:
        icon = Icons.light_mode;
        break;

      case ThemeMode.dark:
        icon = Icons.dark_mode;
        break;

      case ThemeMode.system:
        icon = Icons.brightness_auto;
        break;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        if (!isSelected) {
          ref.read(settingsProvider.notifier).setThemeMode(mode);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: isSelected
              ? context.primary.withAlpha(20)
              : context.surfaceContainer,

          // Reduced radius
          borderRadius: BorderRadius.circular(12),

          border: Border.all(
            color: isSelected
                ? context.primary
                : context.colorAppScheme.outline,
            width: 1.5,
          ),
        ),

        child: Row(
          children: [
            // Icon background
            Container(
              padding: const EdgeInsets.all(10),

              decoration: BoxDecoration(
                color: isSelected
                    ? context.primary.withAlpha(30)
                    : context.colorAppScheme.surface,

                borderRadius: BorderRadius.circular(10),
              ),

              child: Icon(
                icon,
                size: 22,
                color: isSelected ? context.primary : context.textSecondary,
              ),
            ),

            const SizedBox(width: 14),

            UiText(
              text: title,
              type: UiTextType.bodyMedium,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),

            const Spacer(),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? Icon(
                      Icons.check_circle,
                      key: const ValueKey("selected"),
                      color: context.primary,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
