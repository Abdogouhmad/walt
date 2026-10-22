import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:walt/features/transactions/activity_filter.dart';
import 'package:walt/features/transactions/widgets/activity_controls.dart';
import 'package:walt/features/transactions/widgets/activity_day_group.dart';
import 'package:walt/providers/category_provider.dart';
import 'package:walt/providers/transaction_provider.dart';
import 'package:walt/shared/profile_app_bar_action.dart';
import 'package:walt_ui/walt_ui.dart';

/// Retained (app-lifetime) activity filters so switching tabs does not clear
/// the query or chips.
final activityQueryProvider = StateProvider<String>((ref) => '');
final activityTypeProvider = StateProvider<String>((ref) => 'all');
final activityCategoryProvider = StateProvider<int?>((ref) => null);

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  late final TextEditingController _search = TextEditingController(
    text: ref.read(activityQueryProvider),
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txMap = ref.watch(transactionsByDayProvider);
    final categories = ref.watch(categoryProvider).value ?? const [];
    final query = ref.watch(activityQueryProvider);
    final type = ref.watch(activityTypeProvider);
    final categoryId = ref.watch(activityCategoryProvider);

    final categoryById = {for (final c in categories) c.id: c};

    final filtered = filterTransactions(
      txMap,
      categories,
      ActivityFilter(query: query, type: type, categoryId: categoryId),
    );

    final isEmpty = filtered.isEmpty;
    // Materialise the day keys once. `filtered` is a LinkedHashMap, whose
    // `keys.elementAt(i)` walks from the head — calling it per row made the
    // list O(days²). Indexing a list is O(1).
    final dayKeys = filtered.keys.toList(growable: false);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Activity'),
            actions: const [ProfileAppBarAction()],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(120),
              child: ActivityControls(
                controller: _search,
                query: query,
                type: type,
                categoryId: categoryId,
                categories: categories,
                onQueryChanged: (value) =>
                    ref.read(activityQueryProvider.notifier).state = value,
                onTypeChanged: (value) =>
                    ref.read(activityTypeProvider.notifier).state = value,
                onCategoryChanged: (value) =>
                    ref.read(activityCategoryProvider.notifier).state = value,
              ),
            ),
          ),
          if (isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: WaltChrome.scrollBottomPadding(context),
                ),
                child: const EmptyStateView(
                  title: 'No activity found',
                  message:
                      'Your transactions will appear here once you add them.',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: dayKeys.length + 1,
              itemBuilder: (context, index) {
                if (index == dayKeys.length) {
                  return SizedBox(
                    height: WaltChrome.scrollBottomPadding(context),
                  );
                }

                final day = dayKeys[index];
                final transactions = filtered[day]!;

                return ActivityDayGroup(
                  day: day,
                  transactions: transactions,
                  categoryById: categoryById,
                );
              },
            ),
        ],
      ),
    );
  }
}
