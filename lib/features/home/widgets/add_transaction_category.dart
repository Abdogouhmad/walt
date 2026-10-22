import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/data/models/walt_category.dart';
import 'package:walt/features/home/widgets/category_widget.dart';
import 'package:walt_ui/walt_ui.dart';

/// The category chip picker of the add-transaction sheet, plus its
/// "select a category" error line.
class AddTransactionCategorySection extends StatelessWidget {
  final String type;
  final AsyncValue<List<WaltCategory>> categories;
  final int? selectedCategoryId;
  final bool hasError;

  /// Anchor used to scroll the section into view when the save was blocked
  /// only because no chip is selected.
  final GlobalKey anchorKey;
  final ValueChanged<int?> onChanged;
  final VoidCallback onRetry;

  const AddTransactionCategorySection({
    super.key,
    required this.type,
    required this.categories,
    required this.selectedCategoryId,
    required this.hasError,
    required this.anchorKey,
    required this.onChanged,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Category', key: anchorKey, style: textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),

        categories.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (e, _) => Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: AppSpacing.md,
                color: scheme.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Failed to load categories',
                style: TextStyle(color: scheme.error, fontSize: 13),
              ),
              const Spacer(),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
          data: (all) {
            final filtered = all.where((c) => c.type == type).toList();
            return CategoryPicker(
              categories: filtered,
              selected: selectedCategoryId,
              onChanged: onChanged,
            );
          },
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              left: AppSpacing.md,
            ),
            child: Text(
              'Select a category',
              style: textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ),
      ],
    );
  }
}
