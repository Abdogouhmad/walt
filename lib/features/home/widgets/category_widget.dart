import 'package:flutter/material.dart';

import 'package:walt/core/design/motion.dart';
import 'package:walt/core/design/radius.dart';
import 'package:walt/core/design/spacing.dart';
import 'package:walt/data/models/walt_category.dart';
import 'package:walt/core/utils/category_icon.dart';

/// Wrap of selectable category chips used inside the add-transaction sheet.
///
/// Region geometry (radius, padding, motion, gaps) comes from the design
/// tokens in `core/design/`.
class CategoryPicker extends StatelessWidget {
  final List<WaltCategory> categories;
  final int? selected;
  final ValueChanged<int> onChanged;

  const CategoryPicker({
    super.key,
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          'No categories found. Check database seed.',
          style: TextStyle(color: cs.error),
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: categories.map((cat) {
        final isSelected = selected == cat.id;
        return GestureDetector(
          onTap: () => onChanged(cat.id),
          child: AnimatedContainer(
            duration: AppMotion.short,
            curve: AppMotion.standard,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primaryContainer
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.field),
              border: Border.all(
                color: isSelected ? cs.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CategoryIcons.getIcon(cat.icon),
                  size: AppSpacing.md,
                  color: isSelected
                      ? cs.onPrimaryContainer
                      : cs.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}