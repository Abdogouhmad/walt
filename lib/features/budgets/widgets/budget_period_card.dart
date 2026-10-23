import 'package:flutter/material.dart';

import 'package:walt/data/models/budget_period.dart';
import 'package:walt/features/budgets/widgets/budget_history_chart.dart';
import 'package:walt_ui/walt_ui.dart';

/// One period row in a budget's history: a progress ring, the dates, and what
/// was spent against that period's snapshotted limit.
class BudgetPeriodCard extends StatelessWidget {
  const BudgetPeriodCard({
    super.key,
    required this.summary,
    required this.currency,
    required this.onTap,
  });

  final BudgetPeriodSummary summary;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final walt = WaltColors.of(context);

    final over = summary.isOver;
    final ringColor = over
        ? walt.expense
        : (summary.isCurrent ? scheme.primary : scheme.secondary);
    final percent = (summary.rawRatio * 100).clamp(0, 999);
    final title = budgetPeriodTitle(
      summary.window.period,
      summary.window.start,
    );

    return Semantics(
      button: true,
      label:
          '$title, ${percent.toStringAsFixed(0)} percent used, '
          '${MoneyFormat.withCode(summary.spent, currency: currency)} of '
          '${MoneyFormat.withCode(summary.limit, currency: currency)}',
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                SizedBox(
                  width: 54,
                  height: 54,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 54,
                        height: 54,
                        child: CircularProgressIndicator(
                          value: summary.ratio,
                          strokeWidth: 5,
                          strokeCap: StrokeCap.round,
                          color: ringColor,
                          backgroundColor: scheme.surfaceContainerHighest,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '${percent.toStringAsFixed(0)}%',
                            maxLines: 1,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: over ? walt.expense : scheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (summary.isCurrent) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                                child: Text(
                                  'Current',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${MoneyFormat.withCode(summary.spent, currency: currency)} '
                        'of ${MoneyFormat.withCode(summary.limit, currency: currency)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (over) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Over by ${MoneyFormat.withCode(summary.spent - summary.limit, currency: currency)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: walt.expense,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
