import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/core/design/spacing.dart';
import 'package:walt/core/theme/walt_colors.dart';
import 'package:walt/core/widgets/amount_text.dart';
import 'package:walt/core/widgets/pill_switcher.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/providers/transaction_provider.dart';

/// The home hero: the single highest-emphasis element on the screen.
///
/// The balance is set past the type scale, with tabular figures inside a
/// `FittedBox` so a long amount shrinks instead of overflowing. Income and
/// expenses sit below as one tonal pill each, coloured from the `WaltColors`
/// theme extension rather than a hardcoded green/red.
class BalanceHero extends ConsumerWidget {
  const BalanceHero({super.key});

  /// Rendered size of the hero balance, in logical pixels.
  ///
  /// Chosen deliberately rather than taken from a role. It sits between
  /// `displaySmall` (36) and `displayLarge` (72), so no one else on the
  /// screen competes with the number — the balance is the only thing the
  /// Home screen is for.
  static const double _heroBalanceSize = 56;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(summaryProvider);
    final currency = ref.watch(settingsProvider.select((s) => s.currency));

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final walt = WaltColors.of(context);

    // `primaryContainer` is what makes this the hero: the one filled surface
    // on the screen, against which every other card recedes. Text therefore
    // moves to `onPrimaryContainer` — using `onSurface` here would sit at the
    // wrong contrast against a filled container.
    return AppCard(
      level: AppCardLevel.primary,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Total balance',
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onPrimaryContainer.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AmountText(
            amount: summary.balance,
            currency: currency,
            hero: true,
            showSign: false,
            color: scheme.onPrimaryContainer,
            animate: true,
            // Past the largest role in the type scale, deliberately.
            //
            // The balance is the one number on this screen that should win, and
            // the scale tops out at 44pt for `displayMedium` — which reads as a
            // title rather than a figure. A fixed 56pt keeps the rendered size
            // consistent between a short balance and a long one; the
            // `FittedBox` inside `AmountText` then only engages for genuinely
            // long amounts, instead of scaling every number to fill the card.
            fontSize: _heroBalanceSize,
            style: theme.textTheme.displayMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: StatPill(
                  label: 'Income',
                  amount: _amount(summary.income, currency),
                  icon: Icons.south_west_rounded,
                  foreground: walt.income,
                  background: walt.incomeContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatPill(
                  label: 'Expenses',
                  amount: _amount(summary.expenses, currency),
                  icon: Icons.north_east_rounded,
                  foreground: walt.expense,
                  background: walt.expenseContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _amount(double value, String currency) {
    final text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    return currency.isEmpty ? text : '$text $currency';
  }
}
