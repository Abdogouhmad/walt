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
    String? note,
    String? merchant,
    DateTime? createdAt,
  }) = _WaltTransaction;

  factory WaltTransaction.fromJson(Map<String, dynamic> json) =>
      _$WaltTransactionFromJson(json);
}
