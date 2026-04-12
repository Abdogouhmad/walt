// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'walt_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WaltAccount _$WaltAccountFromJson(Map<String, dynamic> json) => _WaltAccount(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  type: json['type'] as String,
  balance: (json['balance'] as num).toDouble(),
  currency: json['currency'] as String,
  color: json['color'] as String?,
  isDefault: json['isDefault'] as bool? ?? false,
);

Map<String, dynamic> _$WaltAccountToJson(_WaltAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'balance': instance.balance,
      'currency': instance.currency,
      'color': instance.color,
      'isDefault': instance.isDefault,
    };
