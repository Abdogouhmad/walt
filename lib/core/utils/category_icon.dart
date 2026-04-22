import 'package:flutter/material.dart';

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

  static const Map<String, Color> _colorMap = {
    'restaurant': Colors.orange,
    'account_balance_wallet': Colors.blue,
    'coffee': Colors.brown,
    'directions_car': Colors.red,
    'shopping_bag': Colors.pink,
    'favorite': Colors.redAccent,
    'bolt': Colors.amber,
    'laptop': Colors.blueGrey,
    'category': Colors.teal,
    'shopping_basket_outlined': Colors.green,
    'work_outline': Colors.indigo,
    'attach_money': Colors.lightGreen,
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

  static Color getColor(String name) {
    return _colorMap[name] ?? Colors.grey;
  }

  static String getName(String name) {
    return _nameMap[name] ?? 'Unknown';
  }
}
