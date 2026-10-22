import 'package:walt/data/models/walt_category.dart';
import 'package:walt/data/models/walt_transaction.dart';

/// A throwaway category.
WaltCategory testCategory(int id, String name) => WaltCategory(
  id: id,
  name: name,
  icon: 'icon',
  color: '#000000',
  type: 'expense',
);

/// The three categories the report tests aggregate against.
final Map<int, WaltCategory> testCategories = <int, WaltCategory>{
  1: testCategory(1, 'Food'),
  2: testCategory(2, 'Transport'),
  3: testCategory(3, 'Fun'),
};

/// A throwaway transaction.
WaltTransaction testTransaction({
  required int id,
  required double amount,
  required DateTime date,
  int categoryId = 1,
  String type = 'expense',
}) => WaltTransaction(
  id: id,
  amount: amount,
  type: type,
  categoryId: categoryId,
  date: date,
);
