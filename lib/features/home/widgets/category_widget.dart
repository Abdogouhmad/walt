import 'package:flutter/material.dart';
import 'package:walt/data/models/walt_category.dart';

// Maps the string stored in WaltCategory.icon → MaterialIcons codepoint
IconData _iconFromName(String name) {
  const map = <String, IconData>{
    'restaurant': Icons.restaurant,
    'account_balance_wallet': Icons.account_balance_wallet,
    'coffee': Icons.coffee,
    'directions_car': Icons.directions_car,
    'shopping_bag': Icons.shopping_bag,
    'favorite': Icons.favorite,
    'bolt': Icons.bolt,
    'laptop': Icons.laptop,
    'category': Icons.category,
  };
  return map[name] ?? Icons.label_outline;
}

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
      return Text(
        'No categories available',
        style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.5)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = selected == cat.id;

        return GestureDetector(
          onTap: () => onChanged(cat.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primaryContainer
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? cs.primary : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _iconFromName(cat.icon),
                  size: 16,
                  color: isSelected
                      ? cs.primary
                      : cs.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? cs.primary
                        : cs.onSurface.withOpacity(0.7),
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
