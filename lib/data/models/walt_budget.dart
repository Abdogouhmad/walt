import 'package:freezed_annotation/freezed_annotation.dart';

part 'walt_budget.freezed.dart';
part 'walt_budget.g.dart';

@freezed
sealed class WaltBudget with _$WaltBudget {
  const factory WaltBudget({
    required int id,
    required int categoryId,
    required double amount,
    required String period,
    @Default(0.8) double alertAt,
    DateTime? createdAt,
  }) = _WaltBudget;

  factory WaltBudget.fromJson(Map<String, dynamic> json) =>
      _$WaltBudgetFromJson(json);
}
