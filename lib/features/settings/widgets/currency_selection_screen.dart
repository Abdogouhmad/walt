import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/core/constants/app_colors.dart';
import 'package:walt/core/utils/context.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/text_ui.dart';

class CurrencySelectionScreen extends ConsumerWidget {
  const CurrencySelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    final currencies = [
      {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
      {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
      {'code': 'MAD', 'name': 'Moroccan Dirham', 'symbol': 'DH'},
      {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
      {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
    ];

    return Scaffold(
      backgroundColor: context.colorAppScheme.surfaceContainerLowest,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
      ),

      body: ListView(
        padding: const EdgeInsets.all(15),
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
            style: TextStyle(color: context.colorAppScheme.onSurfaceVariant),
          ),

          const SizedBox(height: 20),

          // Currency cards
          ...List.generate(currencies.length, (index) {
            final currency = currencies[index];

            final isSelected = settings.currency == currency['code'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),

              child: InkWell(
                borderRadius: BorderRadius.circular(12),

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
                        ? context.primary.withAlpha(20)
                        : context.surfaceContainer,

                    borderRadius: BorderRadius.circular(12),

                    border: Border.all(
                      color: isSelected
                          ? context.primary
                          : context.colorAppScheme.outline.withAlpha(40),

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
                              ? context.primary.withAlpha(30)
                              : context.colorAppScheme.surface,

                          borderRadius: BorderRadius.circular(12),
                        ),

                        alignment: Alignment.center,

                        child: UiText(
                          text: currency['symbol'] as String,

                          type: UiTextType.bodyMedium,

                          style: TextStyle(
                            color: isSelected
                                ? context.primary
                                : context.textSecondary,

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

                              style: TextStyle(color: context.textSecondary),
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
                                color: context.primary,
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
