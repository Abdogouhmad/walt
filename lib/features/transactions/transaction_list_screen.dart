import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:walt/core/design/spacing.dart';
import 'package:walt/core/widgets/grouped_list.dart';
import 'package:walt/core/widgets/section_header.dart';
import 'package:walt/core/widgets/staggered_entry.dart';
import 'package:walt/core/widgets/walt_chrome.dart';
import 'package:walt/shared/profile_app_bar_action.dart';
import 'package:walt/data/models/walt_category.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/features/transactions/widgets/tx_list.dart';
import 'package:walt/providers/category_provider.dart';
import 'package:walt/providers/transaction_provider.dart';
import 'package:walt/shared/state_views.dart';

/// Retained (app-lifetime) activity filters so switching tabs does not clear
/// the query or chips.
final activityQueryProvider = StateProvider<String>((ref) => '');
final activityTypeProvider = StateProvider<String>((ref) => 'all');
final activityCategoryProvider = StateProvider<int?>((ref) => null);

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  late final TextEditingController _search = TextEditingController(
    text: ref.read(activityQueryProvider),
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txMap = ref.watch(transactionsByDayProvider);
    final categories = ref.watch(categoryProvider).value ?? const [];
    final query = ref.watch(activityQueryProvider);
    final type = ref.watch(activityTypeProvider);
    final categoryId = ref.watch(activityCategoryProvider);

    final categoryById = {for (final c in categories) c.id: c};

    final filtered = <String, List<WaltTransaction>>{};
    txMap.forEach((day, transactions) {
      final kept = transactions.where((tx) {
        if (type != 'all' && tx.type.toLowerCase() != type) return false;
        if (categoryId != null && tx.categoryId != categoryId) return false;

        if (query.trim().isNotEmpty) {
          final category = categoryById[tx.categoryId];
          final haystack =
              '${tx.merchant ?? ''} ${tx.note ?? ''} ${category?.name ?? ''}'
                  .toLowerCase();
          if (!haystack.contains(query.trim().toLowerCase())) return false;
        }
        return true;
      }).toList();

      if (kept.isNotEmpty) filtered[day] = kept;
    });

    final isEmpty = filtered.isEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Activity'),
            actions: const [ProfileAppBarAction()],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(120),
              child: _ActivityControls(
                controller: _search,
                query: query,
                type: type,
                categoryId: categoryId,
                categories: categories,
                onQueryChanged: (value) =>
                    ref.read(activityQueryProvider.notifier).state = value,
                onTypeChanged: (value) =>
                    ref.read(activityTypeProvider.notifier).state = value,
                onCategoryChanged: (value) =>
                    ref.read(activityCategoryProvider.notifier).state = value,
              ),
            ),
          ),
          if (isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: WaltChrome.scrollBottomPadding(context),
                ),
                child: const EmptyStateView(
                  title: 'No activity found',
                  message:
                      'Your transactions will appear here once you add them.',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: filtered.keys.length + 1,
              itemBuilder: (context, index) {
                if (index == filtered.keys.length) {
                  return SizedBox(
                    height: WaltChrome.scrollBottomPadding(context),
                  );
                }

                final day = filtered.keys.elementAt(index);
                final transactions = filtered[day]!;

                return WaltChrome.constrain(
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(title: day),
                        GroupedList(
                          children: [
                            for (var i = 0; i < transactions.length; i++)
                              StaggeredEntry(
                                key: ValueKey(transactions[i].id),
                                index: i,
                                child: Builder(
                                  builder: (context) {
                                    final category =
                                        categoryById[transactions[i]
                                            .categoryId];
                                    return TxList(
                                      transaction: transactions[i],
                                      categoryName: category?.name ?? 'Unknown',
                                      categoryIcon:
                                          category?.icon ?? 'category',
                                      categoryColor: category?.color,
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ActivityControls extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final String type;
  final int? categoryId;
  final List<WaltCategory> categories;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<int?> onCategoryChanged;

  const _ActivityControls({
    required this.controller,
    required this.query,
    required this.type,
    required this.categoryId,
    required this.categories,
    required this.onQueryChanged,
    required this.onTypeChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SearchBar(
            controller: controller,
            hintText: 'Search transactions',
            leading: const Icon(Icons.search_rounded),
            elevation: const WidgetStatePropertyAll(0),
            backgroundColor: WidgetStatePropertyAll(
              scheme.surfaceContainerHigh,
            ),
            trailing: [
              if (query.isNotEmpty)
                IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    controller.clear();
                    onQueryChanged('');
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
            onChanged: onQueryChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _Chip(
                  label: 'All',
                  selected: type == 'all' && categoryId == null,
                  onSelected: (_) {
                    onTypeChanged('all');
                    onCategoryChanged(null);
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                _Chip(
                  label: 'Income',
                  selected: type == 'income',
                  onSelected: (selected) =>
                      onTypeChanged(selected ? 'income' : 'all'),
                ),
                const SizedBox(width: AppSpacing.sm),
                _Chip(
                  label: 'Expenses',
                  selected: type == 'expense',
                  onSelected: (selected) =>
                      onTypeChanged(selected ? 'expense' : 'all'),
                ),
                const SizedBox(width: AppSpacing.md),
                for (final category in categories) ...[
                  _Chip(
                    label: category.name,
                    selected: categoryId == category.id,
                    onSelected: (selected) =>
                        onCategoryChanged(selected ? category.id : null),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
