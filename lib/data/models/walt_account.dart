import 'package:freezed_annotation/freezed_annotation.dart';

part 'walt_account.freezed.dart';
part 'walt_account.g.dart';

@freezed
sealed class WaltAccount with _$WaltAccount {
  const factory WaltAccount({
    required int id,
    required String name,
    required String type,
    required double balance,
    required String currency,
    String? color,
    @Default(false) bool isDefault,
  }) = _WaltAccount;

  factory WaltAccount.fromJson(Map<String, dynamic> json) =>
      _$WaltAccountFromJson(json);
}
