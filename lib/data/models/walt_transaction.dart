import 'package:freezed_annotation/freezed_annotation.dart';

part 'walt_transaction.freezed.dart';
part 'walt_transaction.g.dart';

@freezed
sealed class WaltTransaction with _$WaltTransaction {
  const factory WaltTransaction({
    required int id,
    required double amount,
    required String type, // 'income' or 'expense'
    required int categoryId,
    required DateTime date,
    int? accountId,

    /// The budget this expense was explicitly booked against.
    ///
    /// Null keeps the legacy behaviour: any budget whose categories include
    /// [categoryId] consumes it. A non-null value makes the expense count for
    /// that one budget only, so overlapping budgets no longer double-count a
    /// transaction the user deliberately assigned.
    int? budgetId,
    String? note,
    String? merchant,
    DateTime? createdAt,
  }) = _WaltTransaction;

  factory WaltTransaction.fromJson(Map<String, dynamic> json) =>
      _$WaltTransactionFromJson(json);
}
