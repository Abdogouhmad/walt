import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/data/models/walt_transaction.dart';

/// A throwaway budget.
WaltBudget testBudget({
  int id = 1,
  int categoryId = 7,
  double amount = 200,
  String period = 'monthly',
  double alertAt = 0.8,
}) => WaltBudget(
  id: id,
  categoryId: categoryId,
  amount: amount,
  period: period,
  alertAt: alertAt,
);

/// A throwaway transaction.
WaltTransaction testExpense({
  required int id,
  required double amount,
  required DateTime date,
  int categoryId = 7,
  String type = 'expense',
}) => WaltTransaction(
  id: id,
  amount: amount,
  type: type,
  categoryId: categoryId,
  date: date,
);
