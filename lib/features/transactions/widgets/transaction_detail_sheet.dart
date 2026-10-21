import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:walt/core/design/radius.dart';
import 'package:walt/core/design/spacing.dart';
import 'package:walt/core/theme/walt_colors.dart';
import 'package:walt/core/widgets/amount_text.dart';
import 'package:walt/core/widgets/category_icon.dart';
import 'package:walt/core/widgets/grouped_list.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/providers/account_provider.dart';
import 'package:walt/providers/category_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/ui_modal.dart';

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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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

    final note = transaction.note?.trim() ?? '';
    // The add form trims the field before saving, so an "empty" merchant can
    // be an empty *string* rather than a null.
    final merchant = transaction.merchant?.trim();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: waltModalPadding(context),
      children: [
        // ── Who it was ──────────────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CategoryAvatar(
              icon: category?.icon ?? 'category',
              color: category?.color,
              size: 48,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    merchant == null || merchant.isEmpty
                        ? 'Unknown Merchant'
                        : merchant,
                    style: theme.textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    category?.name ?? 'Uncategorised',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
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
            _DetailRow(
              icon: isIncome
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              label: 'Type',
              value: isIncome ? 'Income' : 'Expense',
              valueColor: isIncome ? semantic.income : semantic.expense,
            ),
            _DetailRow(
              icon: Icons.event_rounded,
              label: 'Date',
              value: _dateFormat.format(transaction.date),
            ),
            _DetailRow(
              icon: Icons.schedule_rounded,
              label: 'Time',
              value: _timeFormat.format(transaction.date),
            ),
            if (account != null)
              _DetailRow(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Account',
                value: account.name,
              ),
          ],
        ),

        // ── The note ────────────────────────────────────────────────────────
        // Its own block rather than another row: a note is the one field that
        // is allowed to run to several lines, and a single-line row would clip
        // the one piece of free text the user actually wrote.
        if (note.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _NoteBlock(note: note),
        ],
      ],
    );
  }
}

/// One label/value row inside the details group.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Overrides the value colour — used to tint the income/expense direction.
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The note, in a block of its own.
class _NoteBlock extends StatelessWidget {
  const _NoteBlock({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notes_rounded,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Note',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Selectable: a note is the one field a user is likely to want to
          // copy out of the app — a reference number, an address, a name.
          SelectableText(
            note,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}
