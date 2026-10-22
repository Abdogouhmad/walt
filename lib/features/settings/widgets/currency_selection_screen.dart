import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/features/settings/widgets/currency_catalog.dart';
import 'package:walt/features/settings/widgets/currency_option_tile.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt_ui/walt_ui.dart';

class CurrencySelectionScreen extends ConsumerWidget {
  const CurrencySelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

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
          const UiText(
            text: 'Currency',
            type: UiTextType.headlineLarge,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          UiText(
            text: 'Select your preferred currency',
            type: UiTextType.bodyMedium,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final currency in supportedCurrencies)
            CurrencyOptionTile(
              currency: currency,
              isSelected: settings.currency == currency.code,
              onTap: () => ref
                  .read(settingsProvider.notifier)
                  .setCurrency(currency.code),
            ),
        ],
      ),
    );
  }
}
