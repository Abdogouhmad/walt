import 'package:flutter/material.dart';

import 'package:walt/data/models/walt_category.dart';
import 'package:walt/features/transactions/widgets/activity_chip.dart';
import 'package:walt_ui/walt_ui.dart';

/// The activity toolbar: a search field plus the filter chips.
///
/// It is pinned under the app bar, so it is a `PreferredSize` child rather
/// than a scrollable sliver of its own.
class ActivityControls extends StatelessWidget {
  const ActivityControls({
    super.key,
    required this.controller,
    required this.query,
    required this.type,
    required this.categoryId,
    required this.categories,
    required this.onQueryChanged,
    required this.onTypeChanged,
    required this.onCategoryChanged,
  });

  final TextEditingController controller;
  final String query;
  final String type;
  final int? categoryId;
  final List<WaltCategory> categories;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<int?> onCategoryChanged;

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
                ActivityChip(
                  label: 'All',
                  selected: type == 'all' && categoryId == null,
                  onSelected: (_) {
                    onTypeChanged('all');
                    onCategoryChanged(null);
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                ActivityChip(
                  label: 'Income',
                  selected: type == 'income',
                  onSelected: (selected) =>
                      onTypeChanged(selected ? 'income' : 'all'),
                ),
                const SizedBox(width: AppSpacing.sm),
                ActivityChip(
                  label: 'Expenses',
                  selected: type == 'expense',
                  onSelected: (selected) =>
                      onTypeChanged(selected ? 'expense' : 'all'),
                ),
                const SizedBox(width: AppSpacing.md),
                for (final category in categories) ...[
                  ActivityChip(
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
