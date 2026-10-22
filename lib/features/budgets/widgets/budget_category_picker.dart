import 'package:flutter/material.dart';
import 'package:walt/data/models/walt_category.dart';
import 'package:walt_ui/walt_ui.dart';

/// Horizontal wrap of category chips; tapping one selects it.
///
/// Selection is disabled while editing: the category a budget was created for
/// is the one its history is bucketed under, so changing it would silently
/// orphan every past transaction.
class BudgetCategoryPicker extends StatelessWidget {
  const BudgetCategoryPicker({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.isEditing,
    required this.onSelected,
  });

  final List<WaltCategory> categories;
  final int? selectedCategoryId;
  final bool isEditing;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: categories.map((category) {
        final selected = selectedCategoryId == category.id;
        final categoryColor = Color(
          int.parse(category.color.replaceAll('#', '0xFF')),
        );

        return GestureDetector(
          onTap: isEditing ? null : () => onSelected(category.id),
          child: Opacity(
            opacity: isEditing && !selected ? 0.5 : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? categoryColor.withValues(alpha: 0.14)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.field),
                border: Border.all(
                  color: selected
                      ? categoryColor
                      : Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.16),
                  width: selected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CategoryIcons.getIcon(category.icon),
                    size: AppSpacing.sm,
                    color: selected
                        ? categoryColor
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  UiText(
                    text: category.name,
                    type: UiTextType.bodySmall,
                    style: TextStyle(
                      color: selected
                          ? categoryColor
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
