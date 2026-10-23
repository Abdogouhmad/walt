import 'package:walt/data/models/walt_category.dart';

/// A bundled category image offered when creating a custom category.
class CategoryPreset {
  const CategoryPreset({
    required this.name,
    required this.asset,
    required this.icon,
    required this.color,
    this.type = 'expense',
  });

  final String name;
  final String asset;
  final String icon;
  final String color;
  final String type;

  bool get isIncome => type == 'income';

  /// A category shaped from this preset. Used when the user accepts a preset
  /// without changing anything.
  WaltCategory toCategory({required int id, String? name}) {
    return WaltCategory(
      id: id,
      name: name ?? this.name,
      icon: icon,
      color: color,
      type: type,
      imageSource: CategoryImageSource.asset,
      imagePath: asset,
    );
  }
}

/// The bundled gallery. These are the same silhouettes the default categories
/// use, plus a few extras that only exist here.
const List<CategoryPreset> categoryPresets = [
  CategoryPreset(
    name: 'Food',
    asset: 'assets/categories/food.png',
    icon: 'restaurant',
    color: '#C25B3F',
  ),
  CategoryPreset(
    name: 'Groceries',
    asset: 'assets/categories/groceries.png',
    icon: 'shopping_basket_outlined',
    color: '#3F7A5E',
  ),
  CategoryPreset(
    name: 'Coffee',
    asset: 'assets/categories/coffee.png',
    icon: 'coffee',
    color: '#8A6534',
  ),
  CategoryPreset(
    name: 'Transport',
    asset: 'assets/categories/transport.png',
    icon: 'directions_car',
    color: '#4268A8',
  ),
  CategoryPreset(
    name: 'Shopping',
    asset: 'assets/categories/shopping.png',
    icon: 'shopping_bag',
    color: '#7B5CA6',
  ),
  CategoryPreset(
    name: 'Health',
    asset: 'assets/categories/health.png',
    icon: 'favorite',
    color: '#A6425B',
  ),
  CategoryPreset(
    name: 'Utilities',
    asset: 'assets/categories/utilities.png',
    icon: 'bolt',
    color: '#A8752E',
  ),
  CategoryPreset(
    name: 'Entertainment',
    asset: 'assets/categories/entertainment.png',
    icon: 'celebration',
    color: '#8A4F7D',
  ),
  CategoryPreset(
    name: 'Travel',
    asset: 'assets/categories/travel.png',
    icon: 'flight',
    color: '#357C8A',
  ),
  CategoryPreset(
    name: 'Education',
    asset: 'assets/categories/education.png',
    icon: 'school',
    color: '#4C6A9E',
  ),
  CategoryPreset(
    name: 'Gift',
    asset: 'assets/categories/gift.png',
    icon: 'redeem',
    color: '#B05A72',
  ),
  CategoryPreset(
    name: 'Other',
    asset: 'assets/categories/other.png',
    icon: 'category',
    color: '#5E6B78',
  ),
  CategoryPreset(
    name: 'Salary',
    asset: 'assets/categories/salary.png',
    icon: 'account_balance_wallet',
    color: '#3F7A5E',
    type: 'income',
  ),
  CategoryPreset(
    name: 'Freelance',
    asset: 'assets/categories/freelance.png',
    icon: 'laptop',
    color: '#2F7C78',
    type: 'income',
  ),
];
