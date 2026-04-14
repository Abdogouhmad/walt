import 'package:flutter/material.dart';
import 'package:walt/data/models/walt_category.dart';
import 'package:walt/core/utils/category_icon.dart'; // Import mapper

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

    // debugPrint("Categories count: ${categories.length}"); // Add this to check console

    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'No categories found. Check database seed.',
          style: TextStyle(color: cs.error),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 5, // Increased spacing for better touch targets
      children: categories.map((cat) {
        final isSelected = selected == cat.id;
        return GestureDetector(
          onTap: () => onChanged(cat.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primaryContainer
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
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
                  size: 18,
                  color: isSelected
                      ? cs.onPrimaryContainer
                      : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  cat.name,
                  style: TextStyle(
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
