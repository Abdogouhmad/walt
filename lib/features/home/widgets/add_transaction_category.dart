import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/data/models/walt_category.dart';
import 'package:walt/features/categories/category_editor_sheet.dart';
import 'package:walt/shared/widgets/category_picker.dart';
import 'package:walt_ui/walt_ui.dart';

/// The category picker of the add-transaction sheet, plus its
/// "select a category" error line.
class AddTransactionCategorySection extends StatelessWidget {
  final String type;
  final AsyncValue<List<WaltCategory>> categories;
  final int? selectedCategoryId;
  final bool hasError;

  /// Anchor used to scroll the section into view when the save was blocked
  /// only because no category is selected.
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
        Row(
          children: [
            Expanded(
              child: Text(
                'Category',
                key: anchorKey,
                style: textTheme.labelLarge,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Category options',
              icon: const Icon(Icons.more_horiz_rounded),
              onSelected: (value) async {
                if (value == 'new') {
                  final created = await showCategoryEditor(context);
                  if (created != null) onChanged(created.id);
                } else if (value == 'manage') {
                  await showCategoryManager(context);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'new',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.add_rounded),
                    title: Text('New category'),
                  ),
                ),
                PopupMenuItem(
                  value: 'manage',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.tune_rounded),
                    title: Text('Manage categories'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
              Expanded(
                child: Text(
                  'Failed to load categories',
                  maxLines: 2,
                  style: TextStyle(color: scheme.error, fontSize: 13),
                ),
              ),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
          data: (all) {
            final filtered = all.where((c) => c.type == type).toList();
            WaltCategory? selected;
            for (final category in filtered) {
              if (category.id == selectedCategoryId) {
                selected = category;
                break;
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (selected != null) ...[
                  SelectedCategoryPreview(category: selected),
                  const SizedBox(height: AppSpacing.md),
                ],
                CategoryPicker(
                  categories: filtered,
                  selectedIds: {?selectedCategoryId},
                  onToggle: (category) => onChanged(category.id),
                  onCreate: () async {
                    final created = await showCategoryEditor(context);
                    if (created != null && created.type == type) {
                      onChanged(created.id);
                    }
                  },
                  onLongPress: (category) async {
                    final deleted = await showCategoryActions(
                      context,
                      category: category,
                    );
                    if (!context.mounted) return;
                    if (deleted && category.id == selectedCategoryId) {
                      onChanged(null);
                    }
                  },
                ),
              ],
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
