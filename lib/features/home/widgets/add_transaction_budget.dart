import 'package:flutter/material.dart';

import 'package:walt/providers/budget_provider.dart';
import 'package:walt_ui/walt_ui.dart';

/// The optional "Budget" row of the add-transaction form.
///
/// Only budgets that include the selected category are offered, so the choice
/// can never book an expense against something unrelated. "No budget" is the
/// default and keeps the legacy category-based attribution.
class AddTransactionBudgetSection extends StatelessWidget {
  const AddTransactionBudgetSection({
    super.key,
    required this.budgets,
    required this.selectedBudgetId,
    required this.currency,
    required this.onChanged,
  });

  final List<BudgetProgress> budgets;
  final int? selectedBudgetId;
  final String currency;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (budgets.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Budget', style: theme.textTheme.labelLarge),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Optional',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: budgets.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _BudgetChip(
                  label: 'No budget',
                  selected: selectedBudgetId == null,
                  accent: scheme.primary,
                  onTap: () => onChanged(null),
                );
              }

              final progress = budgets[index - 1];
              final accent =
                  CategoryAvatar.parseHex(progress.budget.accentColor) ??
                  scheme.primary;
              final remaining = progress.remaining;
              final detail = remaining < 0
                  ? 'Over by ${_money(-remaining, currency)}'
                  : '${_money(remaining, currency)} left';

              return _BudgetChip(
                label: progress.displayName,
                detail: detail,
                selected: selectedBudgetId == progress.budget.id,
                accent: accent,
                isOver: progress.isOverBudget,
                onTap: () => onChanged(progress.budget.id),
              );
            },
          ),
        ),
      ],
    );
  }

  static String _money(double value, String currency) {
    final amount = MoneyFormat.digits(value, fractionDigits: 0);
    return currency.isEmpty ? amount : '$amount $currency';
  }
}

class _BudgetChip extends StatelessWidget {
  const _BudgetChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.detail,
    this.isOver = false,
  });

  final String label;
  final String? detail;
  final bool selected;
  final Color accent;
  final bool isOver;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final walt = WaltColors.of(context);
    final detailColor = isOver ? walt.expense : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: detail == null ? label : '$label, $detail',
      excludeSemantics: true,
      child: Material(
        color: selected
            ? Color.alphaBlend(accent.withValues(alpha: 0.16), scheme.surface)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? accent : Colors.transparent,
            width: 1.2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOver ? walt.expense : accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '· $detail',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: detailColor,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
