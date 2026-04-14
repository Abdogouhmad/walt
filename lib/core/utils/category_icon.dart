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

  static IconData getIcon(String name) {
    return _iconMap[name] ?? Icons.label_outline;
  }
}