import 'package:flutter/material.dart';

/// The icon key stored per category in the database, mapped to a Material glyph
/// and a display name.
///
/// There is deliberately no colour here. A fixed rainbow of category colours was
/// the one place in the app that ignored the palette, and it was never read:
/// a category's colour is a *user* value (`WaltCategory.color`), and the one
/// derived for the icon comes from `WaltChartColors.harmonizeCategory`, so it
/// follows the theme.
class CategoryIcons {
  static const Map<String, IconData> _iconMap = {
    'restaurant': Icons.restaurant,
    'account_balance_wallet': Icons.account_balance_wallet,
    'coffee': Icons.coffee,
    'directions_car': Icons.directions_car,
    'shopping_bag': Icons.shopping_bag,
    'favorite': Icons.favorite,
    'bolt': Icons.bolt,
    'laptop': Icons.laptop,
    'category': Icons.category,
    'shopping_basket_outlined': Icons.shopping_basket_outlined,
    'work_outline': Icons.work_outline,
    'attach_money': Icons.attach_money,
  };

  static const Map<String, String> _nameMap = {
    'restaurant': 'Dining',
    'account_balance_wallet': 'Finance',
    'coffee': 'Coffee',
    'directions_car': 'Transport',
    'shopping_bag': 'Shopping',
    'favorite': 'Health',
    'bolt': 'Utilities',
    'laptop': 'Tech',
    'category': 'General',
    'shopping_basket_outlined': 'Groceries',
    'work_outline': 'Work',
    'attach_money': 'Income',
  };

  static IconData getIcon(String name) {
    return _iconMap[name] ?? Icons.label_outline;
  }

  static String getName(String name) {
    return _nameMap[name] ?? 'Unknown';
  }
}
