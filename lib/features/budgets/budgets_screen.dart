// lib/features/budgets/budgets_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:walt/features/budgets/widgets/budget_add_card.dart';
import 'package:walt/features/budgets/widgets/budget_card.dart';
import 'package:walt/features/budgets/widgets/budget_delete_action.dart';
import 'package:walt/features/budgets/widgets/budget_delete_background.dart';
import 'package:walt/features/budgets/widgets/budget_sheet.dart';
import 'package:walt/features/budgets/widgets/sumcard.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/profile_app_bar_action.dart';
import 'package:walt_ui/walt_ui.dart';

/// Shared month-name formatter — built once, not on every header rebuild.
final _monthNameFormat = DateFormat('MMMM');

/// The budgets tab.
///
/// The pencil action enters a focused reorder mode for pinned budgets: only
/// those can be dragged, because [pinOrder] is the only ordering the user
/// controls (everything else stays in creation order).
class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  bool _reorderMode = false;

  @override
  Widget build(BuildContext context) {
    final budgetsAsync = ref.watch(budgetProvider);
    final progress = ref.watch(budgetProgressProvider);
    final summary = ref.watch(budgetSummaryProvider);
    final currency = ref.watch(settingsProvider.select((s) => s.currency));

    final pinned = progress.where((p) => p.budget.isPinned).toList();
    final unpinned = progress.where((p) => !p.budget.isPinned).toList();
    final canReorder = pinned.length > 1;

    final thisMonth = _monthNameFormat.format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => ref.read(budgetProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: const Text('Budgets'),
              actions: [
                if (canReorder)
                  IconButton(
                    tooltip: _reorderMode
                        ? 'Done reordering'
                        : 'Reorder pinned budgets',
                    onPressed: () =>
                        setState(() => _reorderMode = !_reorderMode),
                    icon: Icon(
                      _reorderMode ? Icons.check_rounded : Icons.edit_outlined,
                    ),
                  ),
                const ProfileAppBarAction(),
              ],
            ),
            if (budgetsAsync.isLoading && progress.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: LoadingStateView(),
              )
            else if (budgetsAsync.hasError && progress.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: InlineErrorView(
                    message: 'Error loading budgets',
                    onRetry: () => ref.read(budgetProvider.notifier).refresh(),
                  ),
                ),
              )
            else if (_reorderMode && pinned.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                sliver: SliverToBoxAdapter(
                  child: WaltChrome.constrain(
                    Text(
                      'Drag a pinned budget to change the order on Home.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverReorderableList(
                  itemCount: pinned.length,
                  onReorderItem: (oldIndex, newIndex) {
                    final ids = pinned
                        .map((p) => p.budget.id)
                        .toList(growable: false);
                    if (oldIndex < 0 || oldIndex >= ids.length) return;
                    final moved = ids.removeAt(oldIndex);
                    ids.insert(newIndex.clamp(0, ids.length), moved);
                    Haptics.selection();
                    ref.read(budgetProvider.notifier).reorderPinned(ids);
                  },
                  itemBuilder: (context, index) {
                    final item = pinned[index];
                    return Padding(
                      key: ValueKey(item.budget.id),
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: WaltChrome.constrain(
                        ReorderableDelayedDragStartListener(
                          index: index,
                          child: BudgetCard(
                            progress: item,
                            currency: currency,
                            showPin: false,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: WaltChrome.scrollBottomPadding(context),
                ),
              ),
            ] else ...[
              if (progress.isEmpty) ...[
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: WaltChrome.scrollBottomPadding(context),
                    ),
                    child: const EmptyStateView(
                      title: 'No budgets set yet',
                      message:
                          'Create a budget to keep your spending in check and reach your goals faster.',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: WaltChrome.constrain(
                      BudgetAddCard(onTap: () => showBudgetSheet(context)),
                    ),
                  ),
                ),
              ] else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: WaltChrome.constrain(
                      BudgetSumCard(
                        currency: currency,
                        summary: summary,
                        month: thisMonth,
                      ),
                    ),
                  ),
                ),
                if (pinned.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: WaltChrome.constrain(
                      const SectionHeader(title: 'Pinned'),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    sliver: SliverList.builder(
                      itemCount: pinned.length,
                      itemBuilder: (context, index) {
                        final item = pinned[index];
                        return Padding(
                          key: ValueKey(item.budget.id),
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: WaltChrome.constrain(
                            _DismissibleBudgetCard(
                              progress: item,
                              currency: currency,
                              onDelete: () =>
                                  deleteBudgetWithUndo(context, ref, item),
                              onTap: () => showBudgetSheet(
                                context,
                                budgetToEdit: item.budget,
                              ),
                              onHistory: () => context.push(
                                '/budgets/${item.budget.id}/history',
                              ),
                              onPinToggle: () => _togglePin(item),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                if (unpinned.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: WaltChrome.constrain(
                      SectionHeader(
                        title: 'All budgets',
                        trailing: Text(
                          '${progress.length} total',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    sliver: SliverList.builder(
                      itemCount: unpinned.length,
                      itemBuilder: (context, index) {
                        final item = unpinned[index];
                        return Padding(
                          key: ValueKey(item.budget.id),
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: WaltChrome.constrain(
                            _DismissibleBudgetCard(
                              progress: item,
                              currency: currency,
                              onDelete: () =>
                                  deleteBudgetWithUndo(context, ref, item),
                              onTap: () => showBudgetSheet(
                                context,
                                budgetToEdit: item.budget,
                              ),
                              onHistory: () => context.push(
                                '/budgets/${item.budget.id}/history',
                              ),
                              onPinToggle: () => _togglePin(item),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    pinned.isEmpty && unpinned.isNotEmpty ? AppSpacing.sm : 0,
                    AppSpacing.md,
                    WaltChrome.scrollBottomPadding(context),
                  ),
                  sliver: SliverToBoxAdapter(
                    child: WaltChrome.constrain(
                      BudgetAddCard(onTap: () => showBudgetSheet(context)),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _togglePin(BudgetProgress progress) {
    Haptics.selection();
    final willPin = !progress.budget.isPinned;
    ref.read(budgetProvider.notifier).togglePinned(progress.budget.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          willPin
              ? '${progress.displayName} pinned to Home'
              : '${progress.displayName} unpinned from Home',
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }
}

class _DismissibleBudgetCard extends StatelessWidget {
  const _DismissibleBudgetCard({
    required this.progress,
    required this.currency,
    required this.onDelete,
    required this.onTap,
    required this.onHistory,
    required this.onPinToggle,
  });

  final BudgetProgress progress;
  final String currency;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback onHistory;
  final VoidCallback onPinToggle;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss-${progress.budget.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: const BudgetDeleteBackground(),
      child: BudgetCard(
        progress: progress,
        currency: currency,
        onTap: onTap,
        onHistory: onHistory,
        showPin: true,
        isPinned: progress.budget.isPinned,
        onPinToggle: onPinToggle,
      ),
    );
  }
}
