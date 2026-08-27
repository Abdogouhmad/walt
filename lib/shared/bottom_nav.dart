import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:walt/data/services/notification_service.dart';
import 'package:walt/providers/budget_progress_provider.dart';
import 'package:walt/shared/header_app.dart';

// Session-level dedup so each budget fires at most one warning and one
// "exceeded" notification per app run.
final _notifiedBudgetAlerts = <String>{};

void _checkBudgetAlerts(List<BudgetProgress> progress) {
  for (final p in progress) {
    if (!p.isNearLimit) continue;

    final key = '${p.budget.id}_${p.isOverBudget ? 'over' : 'near'}';
    if (_notifiedBudgetAlerts.contains(key)) continue;
    _notifiedBudgetAlerts.add(key);

    NotificationService().showBudgetAlert(
      id: p.budget.id,
      categoryName: p.category.name,
      limit: p.budget.amount,
      spent: p.spentAmount,
      isOver: p.isOverBudget,
    );
  }
}

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/reports')) return 2;
    if (location.startsWith('/budgets')) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    const routes = ['/', '/transactions', '/reports', '/budgets'];
    context.go(routes[index]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Show the header on Home, Transactions, Reports and Budgets,
    // but not on Settings.
    final String location = GoRouterState.of(context).matchedLocation;
    final bool showHeader = location != '/settings';

    ref.listen(budgetProgressProvider, (_, next) {
      _checkBudgetAlerts(next);
    });

    return Scaffold(
      appBar: showHeader ? const HeaderApp(title: 'Walt') : null,
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt_rounded),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_graph_outlined),
            selectedIcon: Icon(Icons.auto_graph),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Budget',
          ),
        ],
      ),
    );
  }
}
