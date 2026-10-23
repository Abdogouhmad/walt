import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walt/features/budgets/widgets/budget_card.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt_ui/walt_ui.dart';

/// The pinned-budget slice of Home.
///
/// Home is a summary, so it shows at most three: enough to answer "am I on
/// track?" without turning the screen into the Budgets list. The rest live one
/// tap away behind "See all", which is also the only affordance shown when
/// nothing is pinned yet.
class PinnedBudgetsSection extends ConsumerWidget {
  const PinnedBudgetsSection({super.key});

  static const int _maxVisible = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinned = ref.watch(pinnedBudgetProgressProvider);
    final currency = ref.watch(settingsProvider.select((s) => s.currency));
    final theme = Theme.of(context);

    if (pinned.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: _PinPrompt(onTap: () => context.go('/budgets')),
      );
    }

    final visible = pinned.take(_maxVisible).toList(growable: false);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: pinned.length == 1 ? 'Pinned budget' : 'Pinned budgets',
            trailing: TextButton(
              onPressed: () => context.go('/budgets'),
              child: const Text('See all'),
            ),
          ),
          for (final progress in visible)
            Padding(
              key: ValueKey(progress.budget.id),
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: BudgetCard(
                progress: progress,
                currency: currency,
                compact: true,
                isPinned: true,
                showPin: true,
                onTap: () =>
                    context.push('/budgets/${progress.budget.id}/history'),
                onPinToggle: () => _unpin(context, ref, progress),
              ),
            ),
          if (pinned.length > _maxVisible)
            _SeeAllBudgetsTile(
              hiddenCount: pinned.length - _maxVisible,
              onTap: () => context.go('/budgets'),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'Tap a budget to see its history.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _unpin(BuildContext context, WidgetRef ref, BudgetProgress progress) {
    Haptics.selection();
    ref.read(budgetProvider.notifier).togglePinned(progress.budget.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${progress.displayName} unpinned from Home'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => ref
              .read(budgetProvider.notifier)
              .togglePinned(progress.budget.id),
        ),
      ),
    );
  }
}

/// The compact "nothing pinned" state.
///
/// A full budget card would be a fake placeholder; this is an invitation with
/// one action, sized like a row rather than a card so it reads as a prompt.
class _PinPrompt extends StatelessWidget {
  const _PinPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: 'Pin a budget to show it on Home',
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.push_pin_outlined,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Pin a budget',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Keep the ones you watch here on Home',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
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

class _SeeAllBudgetsTile extends StatelessWidget {
  const _SeeAllBudgetsTile({required this.hiddenCount, required this.onTap});

  final int hiddenCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: scheme.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  hiddenCount == 1
                      ? '1 more pinned budget'
                      : '$hiddenCount more pinned budgets',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
