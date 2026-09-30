import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walt/core/widgets/fab_menu.dart';
import 'package:walt/core/widgets/floating_nav_bar.dart';
import 'package:walt/data/services/budget_alert_service.dart';
import 'package:walt/features/budgets/widgets/budget_sheet.dart';
import 'package:walt/features/home/widgets/bottom_sheet.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/providers/transaction_provider.dart';

/// The app shell that owns Walt's floating chrome: a detached pill navigation
/// bar and the expressive FAB menu.
///
/// Screens contribute their own `SliverAppBar` and scroll view; this shell only
/// overlays the chrome and hides the pill while the user scrolls down so more
/// content is visible.
class MainShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  /// Settings is *not* a tab — it is pushed as a normal route from the profile
  /// avatar in each top-level screen's app bar.
  static const List<String> _routes = [
    '/',
    '/transactions',
    '/budgets',
    '/reports',
  ];

  /// Whether the floating chrome is revealed. Flipped by scroll direction.
  final ValueNotifier<bool> _chromeVisible = ValueNotifier(true);

  final BudgetAlertService _alerts = BudgetAlertService();

  @override
  void dispose() {
    _chromeVisible.dispose();
    super.dispose();
  }

  int _selectedIndex(String location) {
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/budgets')) return 2;
    if (location.startsWith('/reports')) return 3;
    return 0;
  }

  void _onDestinationSelected(int index) {
    if (index < 0 || index >= _routes.length) return;
    _chromeVisible.value = true;
    context.go(_routes[index]);
  }

  bool _handleScroll(UserScrollNotification notification) {
    switch (notification.direction) {
      case ScrollDirection.reverse:
        // Scrolling down — get the pill out of the way.
        if (_chromeVisible.value) _chromeVisible.value = false;
      case ScrollDirection.forward:
        if (!_chromeVisible.value) _chromeVisible.value = true;
      case ScrollDirection.idle:
        break;
    }
    return false;
  }

  List<FabAction> _actionsFor(String location) {
    if (location.startsWith('/budgets')) {
      return [
        FabAction(
          icon: Icons.savings_outlined,
          label: 'Add budget',
          onPressed: () => showBudgetSheet(context),
        ),
      ];
    }
    return [
      FabAction(
        icon: Icons.arrow_upward_rounded,
        label: 'Add expense',
        onPressed: () => showAddTransactionSheet(context, type: 'expense'),
      ),
      FabAction(
        icon: Icons.arrow_downward_rounded,
        label: 'Add income',
        onPressed: () => showAddTransactionSheet(context, type: 'income'),
      ),
    ];
  }

  /// Evaluates budget thresholds after any transaction change and on app start.
  Future<void> _evaluateBudgetAlerts(List<BudgetProgress> progress) async {
    if (!ref.read(settingsProvider).budgetAlertsEnabled) return;
    final currency = ref.read(settingsProvider).currency;
    await _alerts.evaluate(progress: progress, currency: currency);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    // `fireImmediately` is what makes budgets that are already over the limit
    // alert on app start, not only on the next change. Riverpod 3 exposes that
    // on `listenManual` (plain `listen` is fire-on-change only).
    ref.listenManual(
      budgetProgressProvider,
      (_, next) => _evaluateBudgetAlerts(next),
      fireImmediately: true,
    );

    // Budgets and transactions arrive independently; re-check once the
    // transaction list lands so the first frame isn't evaluated against an
    // empty list and cached as "nothing to do".
    ref.listen(transactionProvider, (_, next) {
      if (next.hasValue) {
        _evaluateBudgetAlerts(ref.read(budgetProgressProvider));
      }
    });

    return Scaffold(
      // Content draws behind the floating pill; screens add bottom padding via
      // `WaltChrome.scrollBottomPadding`.
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: NotificationListener<UserScrollNotification>(
              onNotification: _handleScroll,
              child: widget.child,
            ),
          ),

          // Floating pill navigation.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ValueListenableBuilder<bool>(
              valueListenable: _chromeVisible,
              builder: (context, visible, _) => FloatingNavBar(
                selectedIndex: _selectedIndex(location),
                onDestinationSelected: _onDestinationSelected,
                visible: visible,
                destinations: const [
                  WaltDestination(
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    label: 'Home',
                  ),
                  WaltDestination(
                    icon: Icons.receipt_long_outlined,
                    selectedIcon: Icons.receipt_long_rounded,
                    label: 'Activity',
                  ),
                  WaltDestination(
                    icon: Icons.savings_outlined,
                    selectedIcon: Icons.savings_rounded,
                    label: 'Budget',
                  ),
                  WaltDestination(
                    icon: Icons.donut_large_outlined,
                    selectedIcon: Icons.donut_large_rounded,
                    label: 'Reports',
                  ),
                ],
              ),
            ),
          ),

          // Expressive FAB menu, route-dependent.
          Positioned.fill(
            child: ValueListenableBuilder<bool>(
              valueListenable: _chromeVisible,
              builder: (context, visible, _) => ExpressiveFabMenu(
                visible: visible,
                actions: _actionsFor(location),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
