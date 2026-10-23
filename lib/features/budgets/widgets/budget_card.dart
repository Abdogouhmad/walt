import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:walt/features/budgets/widgets/budget_wave_bar.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/shared/widgets/category_artwork.dart';
import 'package:walt_ui/walt_ui.dart';

/// Short date used for the bar's start/end labels.
final _barDate = DateFormat('MMM d');

/// Reusable budget card with gradient header, wave progress, percent pill,
/// today marker, start/end labels and overspent messaging.
///
/// Designed for both the Budgets list and the Home summary.
class BudgetCard extends StatelessWidget {
  const BudgetCard({
    super.key,
    required this.progress,
    required this.currency,
    this.onTap,
    this.onPinToggle,
    this.onHistory,
    this.isPinned = false,
    this.showPin = false,
    this.compact = false,
  });

  final BudgetProgress progress;
  final String currency;
  final VoidCallback? onTap;
  final VoidCallback? onPinToggle;
  final VoidCallback? onHistory;
  final bool isPinned;
  final bool showPin;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final walt = WaltColors.of(context);

    final budget = progress.budget;
    final isOver = progress.isOverBudget;
    final isNear = progress.isNearLimit && !isOver;

    final accent = _parseAccent(budget.accentColor) ?? scheme.primary;
    final tone = isOver ? walt.expense : (isNear ? walt.warning : accent);
    final errorTone = walt.expense;
    final trackColor = scheme.surfaceContainerHighest.withValues(alpha: 0.8);

    final headerStart = Color.alphaBlend(
      accent.withValues(alpha: 0.16),
      scheme.surface,
    );
    final headerEnd = Color.alphaBlend(
      accent.withValues(alpha: 0.08),
      scheme.surface,
    );

    final name = progress.displayName;
    final categoryLabel = progress.categoryNames;
    final remaining = progress.remaining;
    final overspent = remaining < 0 ? -remaining : 0.0;
    final percent = (progress.rawProgress * 100).clamp(0.0, 999.0);

    // `isOverBudget` means "reached the limit", which includes spending exactly
    // 100%. Keep that distinct from actually overspending so the card never
    // says "Overspent 0" on a budget that is merely used up.
    final isOverspent = overspent > 0;
    final pillLabel = isOver
        ? (isOverspent ? 'Over limit' : 'Limit reached')
        : (isNear ? 'Near limit' : null);
    final pillColor = isOver
        ? walt.expenseContainer
        : (isNear ? walt.warningContainer : scheme.primaryContainer);
    final pillOn = isOver
        ? scheme.onErrorContainer
        : (isNear ? scheme.onSecondaryContainer : scheme.onPrimaryContainer);

    return Semantics(
      button: onTap != null,
      label:
          '$name, $currency ${progress.spentAmount.toStringAsFixed(0)} '
          'of $currency ${progress.limit.toStringAsFixed(0)}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [headerStart, headerEnd],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(
                      compact ? AppSpacing.md : AppSpacing.lg,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeaderArtwork(progress: progress),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  if (onHistory != null)
                                    IconButton(
                                      tooltip: 'Budget history',
                                      onPressed: onHistory,
                                      icon: const Icon(Icons.history_rounded),
                                    ),
                                  if (showPin && onPinToggle != null)
                                    IconButton(
                                      tooltip: isPinned
                                          ? 'Unpin budget'
                                          : 'Pin budget',
                                      onPressed: onPinToggle,
                                      icon: Icon(
                                        isPinned
                                            ? Icons.push_pin
                                            : Icons.push_pin_outlined,
                                        color: isPinned
                                            ? accent
                                            : scheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      categoryLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                  if (pillLabel != null) ...[
                                    const SizedBox(width: AppSpacing.sm),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: pillColor,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.pill,
                                        ),
                                      ),
                                      child: Text(
                                        pillLabel,
                                        maxLines: 1,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: pillOn,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (!compact) ...[
                                const SizedBox(height: AppSpacing.sm),
                                _PeriodLine(
                                  currency: currency,
                                  progress: progress,
                                  isOver: isOver,
                                  overspent: overspent,
                                  errorTone: errorTone,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? AppSpacing.md : AppSpacing.lg,
                    compact ? AppSpacing.sm : AppSpacing.md,
                    compact ? AppSpacing.md : AppSpacing.lg,
                    compact ? AppSpacing.md : AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: (isOver ? errorTone : tone).withValues(
                                alpha: 0.14,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              _percentLabel(percent),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isOver ? errorTone : scheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              isOver
                                  ? (isOverspent
                                        ? 'Overspent $currency ${overspent.toStringAsFixed(0)}'
                                        : 'No budget left')
                                  : progress.daysLeft == 1
                                  ? '1 day left'
                                  : '${progress.daysLeft} days left',
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isOver
                                    ? errorTone
                                    : scheme.onSurfaceVariant,
                                fontWeight: isOver
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      BudgetWaveBar(
                        progress: progress.rawProgress,
                        color: tone,
                        trackColor: trackColor,
                        todayFraction: progress.todayFraction,
                        markerColor: scheme.onSurfaceVariant,
                        height: 14,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Text(
                            _barDate.format(progress.calculation.window.start),
                            maxLines: 1,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _barDate.format(
                              progress.calculation.window.endExclusive.subtract(
                                const Duration(days: 1),
                              ),
                            ),
                            maxLines: 1,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Scaled as one unit: a long amount shortens the pair
                      // instead of overflowing the card at large text sizes.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AmountText(
                              amount: progress.spentAmount,
                              currency: currency,
                              color: scheme.onSurface,
                              fractionDigits: 0,
                            ),
                            Text(
                              ' / ',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '$currency ${progress.limit.toStringAsFixed(0)}',
                              maxLines: 1,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (compact && !isOver) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Daily allowance: $currency ${progress.dailyAllowance.toStringAsFixed(0)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _percentLabel(double percent) => '${percent.toStringAsFixed(0)}%';

  Color? _parseAccent(String? hex) {
    if (hex == null || hex.trim().isEmpty) return null;
    final cleaned = hex.replaceAll('#', '');
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }
}

class _HeaderArtwork extends StatelessWidget {
  const _HeaderArtwork({required this.progress});

  final BudgetProgress progress;

  @override
  Widget build(BuildContext context) {
    if (progress.categories.isNotEmpty) {
      if (progress.categories.length == 1) {
        return CategoryArtwork(
          category: progress.categories.first,
          size: 48,
          radius: AppRadius.md,
        );
      }
      return SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: CategoryArtwork(
                category: progress.categories[0],
                size: 34,
                radius: AppRadius.sm,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: CategoryArtwork(
                  category: progress.categories[1],
                  size: 30,
                  radius: AppRadius.sm,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return CategoryArtwork(
      category: progress.category,
      size: 48,
      radius: AppRadius.md,
    );
  }
}

class _PeriodLine extends StatelessWidget {
  const _PeriodLine({
    required this.currency,
    required this.progress,
    required this.isOver,
    required this.overspent,
    required this.errorTone,
  });

  final String currency;
  final BudgetProgress progress;
  final bool isOver;
  final double overspent;
  final Color errorTone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (isOver) {
      if (overspent <= 0) {
        return Text(
          'Budget fully used for this period',
          maxLines: 2,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: errorTone,
            fontWeight: FontWeight.w600,
          ),
        );
      }
      return Text(
        'Over by $currency ${overspent.toStringAsFixed(0)} · ${progress.daysLeft == 1 ? "1 day left" : "${progress.daysLeft} days left"}',
        maxLines: 2,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: errorTone,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    if (progress.dailyAllowance > 0) {
      return Text(
        'Daily allowance $currency ${progress.dailyAllowance.toStringAsFixed(0)}',
        maxLines: 2,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      );
    }
    return Text(
      'Budget limit $currency ${progress.limit.toStringAsFixed(0)}',
      maxLines: 2,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
    );
  }
}
