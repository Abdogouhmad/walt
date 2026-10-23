import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/features/transactions/widgets/transaction_detail_header.dart';
import 'package:walt/features/transactions/widgets/transaction_detail_row.dart';
import 'package:walt/features/transactions/widgets/transaction_note_block.dart';
import 'package:walt/providers/account_provider.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/category_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt_ui/walt_ui.dart';

/// Formatters built once: a detail sheet is opened per tap, and
/// `DateFormat` construction does a locale lookup every time it is called.
final _dateFormat = DateFormat('d MMMM yyyy');
final _timeFormat = DateFormat('HH:mm');

/// Opens the detail sheet for [transaction].
///
/// A **bottom sheet**, not a dialog: the sheet is the app's only modal
/// vocabulary (see `showWaltModal`), it is what the add-transaction form uses,
/// and a detail view is tall enough that a centred dialog would either clip
/// its own content or float in the middle of the screen with nothing around
/// it. The sheet also keeps the list behind it visible, so the row that was
/// tapped stays in place while the details are read.
void showTransactionDetailSheet(
  BuildContext context,
  WaltTransaction transaction,
) {
  showWaltModal<void>(
    context,
    content: TransactionDetailSheet(transaction: transaction),
    heightFactor: 0.6,
  );
}

/// Everything a transaction knows about itself, on one sheet.
///
/// The list rows are deliberately terse — a merchant, a category and an
/// amount — because a list is scanned, not read. Everything the terse row
/// leaves out lives here: the direction of the money, the day and the time it
/// happened, the account it was booked against, and the note.
///
/// The category and the account are resolved here rather than handed in by the
/// caller, so the sheet reads the same wherever it is opened from.
class TransactionDetailSheet extends ConsumerWidget {
  const TransactionDetailSheet({super.key, required this.transaction});

  final WaltTransaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semantic = WaltColors.of(context);
    final currency = ref.watch(settingsProvider.select((s) => s.currency));
    final isIncome = transaction.type.toLowerCase() == 'income';

    final categories = ref.watch(categoryProvider).value ?? const [];
    final categoryById = {for (final c in categories) c.id: c};
    final category = categoryById[transaction.categoryId];

    final accounts = ref.watch(accountProvider).value ?? const [];
    final accountById = {for (final a in accounts) a.id: a};
    final account = transaction.accountId == null
        ? null
        : accountById[transaction.accountId];

    final budgets = ref.watch(budgetProvider).value ?? const <WaltBudget>[];
    final budgetById = {for (final b in budgets) b.id: b};
    final budget = transaction.budgetId == null
        ? null
        : budgetById[transaction.budgetId];

    final note = transaction.note?.trim() ?? '';
    // The add form trims the field before saving, so an "empty" merchant can
    // be an empty *string* rather than a null.
    final merchant = transaction.merchant?.trim();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: waltModalPadding(context),
      children: [
        // ── Who it was ──────────────────────────────────────────────────────
        TransactionDetailHeader(merchant: merchant, category: category),
        const SizedBox(height: AppSpacing.lg),

        // ── How much, and which way ─────────────────────────────────────────
        // The sign and the tint carry the direction on their own, which is why
        // the "Type" row below repeats it in words.
        AmountText(
          amount: transaction.amount,
          currency: currency,
          isIncome: isIncome,
          hero: true,
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── When, and where it came from ────────────────────────────────────
        GroupedList(
          children: [
            TransactionDetailRow(
              icon: isIncome
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              label: 'Type',
              value: isIncome ? 'Income' : 'Expense',
              valueColor: isIncome ? semantic.income : semantic.expense,
            ),
            TransactionDetailRow(
              icon: Icons.event_rounded,
              label: 'Date',
              value: _dateFormat.format(transaction.date),
            ),
            TransactionDetailRow(
              icon: Icons.schedule_rounded,
              label: 'Time',
              value: _timeFormat.format(transaction.date),
            ),
            if (account != null)
              TransactionDetailRow(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Account',
                value: account.name,
              ),
            if (budget != null)
              TransactionDetailRow(
                icon: Icons.track_changes_rounded,
                label: 'Budget',
                value: budget.name.trim().isEmpty
                    ? 'Budget'
                    : budget.name.trim(),
              ),
          ],
        ),

        // ── The note ────────────────────────────────────────────────────────
        // Its own block rather than another row: a note is the one field that
        // is allowed to run to several lines, and a single-line row would clip
        // the one piece of free text the user actually wrote.
        if (note.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          TransactionNoteBlock(note: note),
        ],
      ],
    );
  }
}
