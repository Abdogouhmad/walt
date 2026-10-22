import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walt/data/services/budget_alert_service.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/transaction_provider.dart';
import 'package:walt/shared/shell_actions.dart';
import 'package:walt/shared/shell_budget_alerts.dart';
import 'package:walt/shared/shell_destinations.dart';
import 'package:walt_ui/walt_ui.dart';

/// The app shell that owns Walt's docked chrome: a full-width navigation bar
/// and the expressive FAB menu.
///
/// The bar is docked edge-to-edge at the bottom while the shell keeps
/// `extendBody` on, so content scrolls behind its frosted surface. A modal
/// sheet raised on the root navigator covers the bottom edge, so the shell
/// slides the chrome out of the way while a sheet is open.
class MainShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  /// The tabs the nav bar switches between.
  static const List<String> _routes = [
    '/',
    '/transactions',
    '/budgets',
    '/reports',
  ];

  /// Whether the docked chrome is revealed.
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

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    // A modal sheet is pushed on the root navigator, so it paints over this
    // shell. The docked bar sits flush with the bottom edge and is covered by
    // a bottom sheet, but the shell still slides its chrome aside while a
    // sheet is open to avoid any overlap.
    final sheetOpen = ref.watch(modalSheetOpenProvider);

    // `fireImmediately` is what makes budgets that are already over the limit
    // alert on app start, not only on the next change. Riverpod 3 exposes that
    // on `listenManual` (plain `listen` is fire-on-change only).
    ref.listenManual(
      budgetProgressProvider,
      (_, next) => evaluateShellBudgetAlerts(ref, _alerts, next),
      fireImmediately: true,
    );

    // Budgets and transactions arrive independently; re-check once the
    // transaction list lands so the first frame isn't evaluated against an
    // empty list and cached as "nothing to do".
    ref.listen(transactionProvider, (_, next) {
      if (next.hasValue) {
        evaluateShellBudgetAlerts(
          ref,
          _alerts,
          ref.read(budgetProgressProvider),
        );
      }
    });

    return Scaffold(
      // Content scrolls behind the docked frosted nav; screens add bottom
      // padding via `WaltChrome.scrollBottomPadding`.
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(child: widget.child),

          // Docked navigation bar, edge to edge at the bottom.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ValueListenableBuilder<bool>(
              valueListenable: _chromeVisible,
              builder: (context, visible, _) => WaltNavBar(
                selectedIndex: _selectedIndex(location),
                onDestinationSelected: _onDestinationSelected,
                visible: visible && !sheetOpen,
                destinations: shellDestinations,
              ),
            ),
          ),

          // Expressive FAB menu, route-dependent.
          Positioned.fill(
            child: ValueListenableBuilder<bool>(
              valueListenable: _chromeVisible,
              builder: (context, visible, _) => ExpressiveFabMenu(
                // A new route starts with a closed menu: an expanded action
                // stack must never follow the user between tabs.
                key: ValueKey(location),
                visible: visible && !sheetOpen,
                actions: shellActionsFor(location, context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
