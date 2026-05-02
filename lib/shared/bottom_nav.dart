import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:walt/shared/header_app.dart'; // Ensure this import points to your HeaderApp file

class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Mapping paths to indices to keep the bottom nav synced if the user navigates via code
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/reports')) return 2;
    if (location.startsWith('/budgets')) return 3;
    return 0;
  }

  void _onItemTapped(int index) {
    const routes = ['/', '/transactions', '/reports', '/budgets'];
    context.go(routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Get the current route location
    final String location = GoRouterState.of(context).matchedLocation;

    // 2. Determine if the HeaderApp should be shown
    // It shows on Home, Transactions, Reports, and Budgets, but NOT on Settings
    final bool showHeader = location != '/settings';

    return Scaffold(
      // 3. Conditionally apply the AppBar
      appBar: showHeader
          ? PreferredSize(
              preferredSize: const Size.fromHeight(
                70,
              ), // Adjust height as needed
              child: const HeaderApp(title: 'Walt'),
            )
          : null,
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: true,
        showUnselectedLabels: false,
        currentIndex: _calculateSelectedIndex(context),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt_rounded),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_graph),
            activeIcon: Icon(Icons.auto_graph_outlined),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Budget',
          ),
        ],
      ),
    );
  }
}
