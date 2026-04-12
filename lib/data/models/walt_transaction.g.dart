// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'walt_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WaltTransaction _$WaltTransactionFromJson(Map<String, dynamic> json) =>
    _WaltTransaction(
      id: (json['id'] as num).toInt(),
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      categoryId: (json['categoryId'] as num).toInt(),
      date: DateTime.parse(json['date'] as String),
      accountId: (json['accountId'] as num?)?.toInt(),
      note: json['note'] as String?,
      merchant: json['merchant'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$WaltTransactionToJson(_WaltTransaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
      'type': instance.type,
      'categoryId': instance.categoryId,
      'date': instance.date.toIso8601String(),
      'accountId': instance.accountId,
      'note': instance.note,
      'merchant': instance.merchant,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
