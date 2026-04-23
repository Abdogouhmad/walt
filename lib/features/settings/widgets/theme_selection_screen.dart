import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/core/constants/app_colors.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/text_ui.dart';

class ThemeSelectionScreen extends ConsumerWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const UiText(
          text: 'Theme Selection',
          type: UiTextType.titleMedium,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildThemeOption(
              context,
              ref,
              'Light Mode',
              false,
              settings.isDarkMode == false,
            ),
            const SizedBox(height: 12),
            _buildThemeOption(
              context,
              ref,
              'Dark Mode',
              true,
              settings.isDarkMode == true,
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
    bool isDark,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        if (!isSelected) {
          ref.read(settingsProvider.notifier).toggleDarkMode();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? context.primary.withOpacity(0.1)
              : context.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? context.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: isSelected ? context.primary : context.textSecondary,
            ),
            const SizedBox(width: 16),
            UiText(
              text: title,
              type: UiTextType.bodyMedium,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: context.primary,
              ),
          ],
        ),
      ),
    );
  }
}
