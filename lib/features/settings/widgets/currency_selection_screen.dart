import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/core/constants/app_colors.dart';
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
      appBar: AppBar(
        title: const UiText(
          text: 'Currency Selection',
          type: UiTextType.titleMedium,
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: currencies.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final currency = currencies[index];
          final isSelected = settings.currency == currency['code'];

          return InkWell(
            onTap: () {
              ref
                  .read(settingsProvider.notifier)
                  .setCurrency(currency['code'] as String);
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
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: UiText(
                      text: currency['symbol'] as String,
                      type: UiTextType.bodyMedium,
                      style: TextStyle(
                        color: context.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UiText(
                          text: currency['name'] as String,
                          type: UiTextType.bodyMedium,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        UiText(
                          text: currency['code'] as String,
                          type: UiTextType.bodySmall,
                          style: TextStyle(color: context.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: context.primary,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
