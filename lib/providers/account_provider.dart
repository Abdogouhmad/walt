import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/data/local/account_deo.dart';
import 'package:walt/data/models/walt_account.dart';

final accountProvider =
    NotifierProvider<AccountNotifier, AsyncValue<List<WaltAccount>>>(() {
      return AccountNotifier();
    });

class AccountNotifier extends Notifier<AsyncValue<List<WaltAccount>>> {
  final _dao = AccountDao();

  @override
  AsyncValue<List<WaltAccount>> build() {
    loadAccounts();
    return const AsyncValue.loading();
  }

  Future<void> loadAccounts() async {
    try {
      state = const AsyncValue.loading();
      final accounts = await _dao.getAllAccounts();
      state = AsyncValue.data(accounts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => loadAccounts();
}
