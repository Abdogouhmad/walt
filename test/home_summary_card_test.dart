import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walt/data/models/walt_account.dart';
import 'package:walt/features/home/widgets/home_summary_card.dart';
import 'package:walt/providers/account_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/providers/transaction_provider.dart';
import 'package:walt_ui/walt_ui.dart';

class _StubSettings extends SettingsNotifier {
  @override
  SettingsState build() =>
      SettingsState(isLoaded: true, isOnboardingCompleted: true);
}

class _StubAccounts extends AccountNotifier {
  @override
  AsyncValue<List<WaltAccount>> build() => const AsyncValue.data([
    WaltAccount(
      id: 1,
      name: 'Checking',
      type: 'bank',
      balance: 3200,
      currency: 'USD',
      color: '#2F6B52',
      isDefault: true,
    ),
    WaltAccount(
      id: 2,
      name: 'Savings',
      type: 'bank',
      balance: 12000,
      currency: 'USD',
      color: '#3E5F8A',
    ),
  ]);
}

Future<void> _pump(WidgetTester tester, double scale) async {
  tester.view.physicalSize = const Size(360 * 3, 800 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsProvider.overrideWith(_StubSettings.new),
        accountProvider.overrideWith(_StubAccounts.new),
        weekSpendingProvider.overrideWithValue(const [
          12,
          0,
          48,
          130,
          9,
          0,
          1730,
        ]),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme(),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.md),
              child: HomeSummaryCard(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('HomeSummaryCard', () {
    for (final scale in <double>[1.0, 1.5, 2.0]) {
      testWidgets('lays out at ${scale}x on a narrow phone', (tester) async {
        await _pump(tester, scale);
        expect(tester.takeException(), isNull);
        expect(find.text('All accounts'), findsOneWidget);
        expect(find.text('Total balance'), findsOneWidget);
        expect(find.text('This week'), findsOneWidget);
      });
    }

    testWidgets('selecting an account narrows the chips to that account', (
      tester,
    ) async {
      await _pump(tester, 1.0);

      await tester.tap(find.text('Checking'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final chip = tester.widget<Material>(
        find
            .ancestor(
              of: find.text('Checking'),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(chip.shape, isA<StadiumBorder>());
    });

    testWidgets('stays compact so the rest of Home fits', (tester) async {
      await _pump(tester, 1.0);

      final card = tester.getSize(find.byType(HomeSummaryCard));
      // The card is a summary, not a dashboard: the pinned budgets and recent
      // activity below it are the point of the screen.
      expect(card.height, lessThan(320));
    });
  });
}
