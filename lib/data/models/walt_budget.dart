import 'package:freezed_annotation/freezed_annotation.dart';

part 'walt_budget.freezed.dart';
part 'walt_budget.g.dart';

@freezed
sealed class WaltBudget with _$WaltBudget {
  const factory WaltBudget({
    required int id,

    /// The budget's primary category. Kept for backwards compatibility with
    /// rows written before budgets could span more than one category; the
    /// full selection lives in [categoryIds].
    required int categoryId,
    required double amount,
    required String period,
    @Default(0.8) double alertAt,
    DateTime? createdAt,

    /// User-facing label. Empty for budgets created before names existed; the
    /// UI falls back to the primary category's name.
    @Default('') String name,

    /// Every category this budget consumes. Empty (legacy rows) means "just
    /// [categoryId]".
    @Default(<int>[]) List<int> categoryIds,

    /// Pinned budgets are shown on Home, in [pinOrder] order.
    @Default(false) bool isPinned,
    @Default(0) int pinOrder,

    /// Per-budget accent (`#RRGGBB`). Null follows the active scheme's primary.
    String? accentColor,
  }) = _WaltBudget;

  factory WaltBudget.fromJson(Map<String, dynamic> json) =>
      _$WaltBudgetFromJson(json);
}

extension WaltBudgetX on WaltBudget {
  /// The categories this budget actually measures. Legacy rows only carry the
  /// single [categoryId].
  List<int> get effectiveCategoryIds =>
      categoryIds.isEmpty ? <int>[categoryId] : categoryIds;
}
