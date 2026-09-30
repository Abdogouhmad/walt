import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/core/design/radius.dart';
import 'package:walt/core/design/spacing.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/text_ui.dart';

class CurrencySelectionScreen extends ConsumerWidget {
  const CurrencySelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final scheme = Theme.of(context).colorScheme;

    final currencies = [
      {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
      {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
      {'code': 'MAD', 'name': 'Moroccan Dirham', 'symbol': 'DH'},
      {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
      {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
      ),

      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Header like AboutScreen
          UiText(
            text: 'Currency',
            type: UiTextType.headlineLarge,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 4),

          UiText(
            text: "Select your preferred currency",
            type: UiTextType.bodyMedium,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Currency cards
          ...List.generate(currencies.length, (index) {
            final currency = currencies[index];

            final isSelected = settings.currency == currency['code'];

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),

              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.sm),

                onTap: () {
                  ref
                      .read(settingsProvider.notifier)
                      .setCurrency(currency['code'] as String);
                },

                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),

                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: isSelected
                        ? scheme.primary.withValues(alpha: 0.08)
                        : scheme.surfaceContainerHighest,

                    borderRadius: BorderRadius.circular(AppRadius.sm),

                    border: Border.all(
                      color: isSelected
                          ? scheme.primary
                          : scheme.outline.withValues(alpha: 0.4),

                      width: 1.5,
                    ),
                  ),

                  child: Row(
                    children: [
                      // Currency symbol container
                      Container(
                        width: 48,
                        height: 48,

                        decoration: BoxDecoration(
                          color: isSelected
                              ? scheme.primary.withValues(alpha: 0.12)
                              : scheme.surface,

                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),

                        alignment: Alignment.center,

                        child: UiText(
                          text: currency['symbol'] as String,

                          type: UiTextType.bodyMedium,

                          style: TextStyle(
                            color: isSelected
                                ? scheme.primary
                                : scheme.onSurfaceVariant,

                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Currency info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            UiText(
                              text: currency['name'] as String,

                              type: UiTextType.bodyMedium,

                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 2),

                            UiText(
                              text: currency['code'] as String,

                              type: UiTextType.bodySmall,

                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),

                      // Selected icon
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),

                        child: isSelected
                            ? Icon(
                                Icons.check_circle,
                                key: const ValueKey("selected"),
                                color: scheme.primary,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
