import 'dart:async';

import 'package:currency_converter/currency.dart';
import 'package:currency_converter/currency_converter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/data/local/account_dao.dart';
import 'package:walt/data/local/budget_dao.dart';
import 'package:walt/data/local/transaction_dao.dart';
import 'package:walt/providers/account_provider.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/report_provider.dart';
import 'package:walt/providers/transaction_provider.dart';

/// The [Currency] whose code matches [code], or `null` when the code is not
/// one the converter knows about.
Currency? currencyFromCode(String code) {
  final upper = code.toUpperCase();
  for (final c in Currency.values) {
    if (c.name.toUpperCase() == upper) return c;
  }
  return null;
}

/// The rate to convert one unit of [from] into [to].
///
/// A rate of `1.0` means "no conversion": either the codes are unknown or the
/// converter is unreachable, and the amounts on disk stay as they are rather
/// than being scaled by a guess.
Future<double> conversionRate(String from, String to) async {
  try {
    final fromEnum = currencyFromCode(from);
    final toEnum = currencyFromCode(to);
    if (fromEnum == null || toEnum == null) return 1.0;

    final rate = await CurrencyConverter.convert(
      from: fromEnum,
      to: toEnum,
      amount: 1,
    );
    return rate ?? 1.0;
  } catch (e) {
    debugPrint('Error converting currency: $e');
    return 1.0;
  }
}

/// Rewrites every stored amount from the old currency into the new one.
///
/// Accounts, transactions and budgets all hold the same money in three
/// places; leaving one of them behind would make the totals disagree.
Future<void> migrateAmountsToCurrency({
  required Ref ref,
  required double rate,
  required String currency,
}) async {
  await AccountDao().updateAllBalances(rate, currency);
  await TransactionDao().updateAllAmounts(rate);
  await BudgetDao().updateAllAmounts(rate);

  unawaited(ref.read(accountProvider.notifier).refresh());
  unawaited(ref.read(transactionProvider.notifier).refresh());
  unawaited(ref.read(budgetProvider.notifier).refresh());
  // Reports hold converted amounts, so they must be rebuilt too.
  ref.invalidate(reportProvider);
}
