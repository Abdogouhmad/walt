import 'package:walt/data/models/walt_category.dart';
import 'package:walt/data/models/walt_transaction.dart';

/// The activity list's filter state.
///
/// Kept as a plain value so the list screen can hand it to [filterTransactions]
/// without the filtering logic needing to know about Riverpod.
class ActivityFilter {
  const ActivityFilter({
    required this.query,
    required this.type,
    required this.categoryId,
  });

  /// Free-text search over merchant, note and category name.
  final String query;

  /// `'all'`, or a transaction type such as `'income'` / `'expense'`.
  final String type;

  /// The category to restrict to, or `null` for every category.
  final int? categoryId;

  bool get isAllTypes => type == 'all';

  /// The search term, normalised once instead of per transaction.
  String get term => query.trim().toLowerCase();

  bool get hasQuery => term.isNotEmpty;
}

/// Keeps the transactions of [byDay] that pass [filter].
///
/// Days that end up empty are dropped, so the caller can render one section
/// per remaining day without checking for emptiness again.
Map<String, List<WaltTransaction>> filterTransactions(
  Map<String, List<WaltTransaction>> byDay,
  List<WaltCategory> categories,
  ActivityFilter filter,
) {
  final categoryById = {for (final c in categories) c.id: c};
  final term = filter.term;

  final filtered = <String, List<WaltTransaction>>{};
  byDay.forEach((day, transactions) {
    final kept = transactions.where((tx) {
      if (!filter.isAllTypes && tx.type.toLowerCase() != filter.type) {
        return false;
      }
      if (filter.categoryId != null && tx.categoryId != filter.categoryId) {
        return false;
      }

      if (filter.hasQuery) {
        final category = categoryById[tx.categoryId];
        final haystack =
            '${tx.merchant ?? ''} ${tx.note ?? ''} ${category?.name ?? ''}'
                .toLowerCase();
        if (!haystack.contains(term)) return false;
      }
      return true;
    }).toList();

    if (kept.isNotEmpty) filtered[day] = kept;
  });
  return filtered;
}
