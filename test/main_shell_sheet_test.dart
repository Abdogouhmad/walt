import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/providers/transaction_provider.dart';
import 'package:walt/shared/bottom_nav.dart';
import 'package:walt_ui/walt_ui.dart';

/// A screen whose only job is to open a sheet from inside the shell.
class _SheetLauncher extends StatelessWidget {
  const _SheetLauncher();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => unawaited(
            showWaltModal<void>(
              context,
              content: const Center(child: Text('sheet body')),
            ),
          ),
          child: const Text('open sheet'),
        ),
      ),
    );
  }
}

/// Settings with budget alerts off: the shell's alert listener would otherwise
/// reach for Hive, which a widget test has no business opening.
class _StubSettings extends SettingsNotifier {
  @override
  SettingsState build() =>
      SettingsState(isLoaded: true, budgetAlertsEnabled: false);
}

/// An empty transaction list, so the shell never touches the database.
class _StubTransactions extends TransactionNotifier {
  @override
  AsyncValue<List<WaltTransaction>> build() => const AsyncData([]);
}

GoRouter _router() => GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const _SheetLauncher()),
      ],
    ),
  ],
);

bool _navVisible(WidgetTester tester) =>
    tester.widget<FloatingNavBar>(find.byType(FloatingNavBar)).visible;

bool _fabVisible(WidgetTester tester) =>
    tester.widget<ExpressiveFabMenu>(find.byType(ExpressiveFabMenu)).visible;

void main() {
  testWidgets('the floating chrome steps aside while a sheet is open', (
    tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(_StubSettings.new),
          transactionProvider.overrideWith(_StubTransactions.new),
          budgetProgressProvider.overrideWithValue(const []),
          reduceTransparencyProvider.overrideWithValue(false),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(_navVisible(tester), isTrue);
    expect(_fabVisible(tester), isTrue);

    await tester.tap(find.text('open sheet'));
    await tester.pumpAndSettle();

    expect(find.text('sheet body'), findsOneWidget);
    expect(
      _navVisible(tester),
      isFalse,
      reason: 'the nav pill must not sit behind the sheet',
    );
    expect(
      _fabVisible(tester),
      isFalse,
      reason: 'the FAB must not sit behind the sheet',
    );

    Navigator.of(tester.element(find.text('sheet body'))).pop();
    await tester.pumpAndSettle();

    expect(_navVisible(tester), isTrue);
    expect(_fabVisible(tester), isTrue);
  });
}
