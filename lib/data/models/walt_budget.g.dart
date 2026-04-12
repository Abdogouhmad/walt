// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'walt_budget.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WaltBudget _$WaltBudgetFromJson(Map<String, dynamic> json) => _WaltBudget(
  id: (json['id'] as num).toInt(),
  categoryId: (json['categoryId'] as num).toInt(),
  amount: (json['amount'] as num).toDouble(),
  period: json['period'] as String,
  alertAt: (json['alertAt'] as num?)?.toDouble() ?? 0.8,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$WaltBudgetToJson(_WaltBudget instance) =>
    <String, dynamic>{
      'id': instance.id,
      'categoryId': instance.categoryId,
      'amount': instance.amount,
      'period': instance.period,
      'alertAt': instance.alertAt,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
