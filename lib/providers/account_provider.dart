import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/data/local/account_dao.dart';
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
      // Only the first load needs a spinner. A refresh after a restore or a
      // currency change should keep the current balances visible until the new
      // ones land, instead of flashing every dependent card back to zero.
      if (!state.hasValue) state = const AsyncValue.loading();
      final accounts = await _dao.getAllAccounts();
      if (ref.mounted) {
        state = AsyncValue.data(accounts);
      }
    } catch (e, st) {
      if (ref.mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> refresh() => loadAccounts();
}
