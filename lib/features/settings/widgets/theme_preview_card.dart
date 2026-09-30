import 'package:flutter/material.dart';

import 'package:walt/core/design/spacing.dart';
import 'package:walt/core/theme/app_theme.dart';
import 'package:walt/core/theme/theme_settings.dart';
import 'package:walt/core/theme/walt_colors.dart';
import 'package:walt/core/widgets/amount_text.dart';
import 'package:walt/core/widgets/pill_switcher.dart';
import 'package:walt/core/widgets/thick_progress.dart';

/// A miniature of the real screens, rendered in the palette the user is
/// choosing.
///
/// Nine coloured circles tell a user nothing about what a palette *does* to the
/// app. This card answers the question they actually have — "what will my home
/// screen look like?" — by composing the five surfaces that carry the theme
/// most: the primary-tinted hero, the semantic income/expense pills, a progress
/// track, a chip and a filled button. All of them come from `ColorScheme` and
/// `WaltColors`, so the mock cannot drift from the real thing.
///
/// The mock is installed as a nested [Theme] rather than *being* the app's
/// theme, so it renders the settings it is given and nothing else on the screen
/// has to follow.
class ThemePreviewCard extends StatelessWidget {
  const ThemePreviewCard({super.key, required this.settings});

  /// The settings to render. In practice the active ones — a palette applies the
  /// instant it is tapped, so "the palette you are about to get" and "the one
  /// you already have" are the same thing.
  final ThemeSettings settings;

  /// Fixed figures. A preview whose numbers moved on every rebuild would pull
  /// the eye off the colour, and randomised ones would make two palettes look
  /// different for the wrong reason.
  static const String _currency = 'MAD';
  static const double _balance = 12480.5;
  static const String _income = '+3,200';
  static const String _expense = '-1,850';

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Theme(
      data: buildTheme(settings, brightness),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;
          final semantic = WaltColors.of(context);

          return AppCard(
            level: AppCardLevel.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total balance',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                AmountText(
                  amount: _balance,
                  currency: _currency,
                  hero: true,
                  showSign: false,
                  color: scheme.onPrimaryContainer,
                  fontSize: 30,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: StatPill(
                        label: 'Income',
                        amount: _income,
                        compact: true,
                        foreground: semantic.income,
                        background: semantic.incomeContainer,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: StatPill(
                        label: 'Expenses',
                        amount: _expense,
                        compact: true,
                        foreground: semantic.expense,
                        background: semantic.expenseContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ThickProgress(
                  value: 0.62,
                  color: scheme.primary,
                  trackColor: scheme.onPrimaryContainer.withValues(alpha: 0.12),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Chip(
                      label: const Text('Groceries'),
                      avatar: Icon(
                        Icons.shopping_basket_rounded,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
