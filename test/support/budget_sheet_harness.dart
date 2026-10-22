import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/data/models/walt_category.dart';
import 'package:walt/features/budgets/widgets/budget_sheet.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/category_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt_ui/walt_ui.dart';

/// Settings that are already loaded, so the sheet never waits on Hive.
class StubSheetSettings extends SettingsNotifier {
  @override
  SettingsState build() =>
      SettingsState(isLoaded: true, isOnboardingCompleted: true);
}

/// Records what the sheet tried to save.
class StubBudget extends BudgetNotifier {
  final List<WaltBudget> added = [];

  @override
  Future<void> addBudget(WaltBudget budget) async => added.add(budget);
}

/// Two fixed expense categories to pick from.
class StubCategories extends CategoryNotifier {
  @override
  AsyncValue<List<WaltCategory>> build() => const AsyncData([
    WaltCategory(
      id: 1,
      name: 'Food',
      icon: 'food',
      color: '#FFB3261E',
      type: 'expense',
    ),
    WaltCategory(
      id: 2,
      name: 'Transport',
      icon: 'car',
      color: '#FF386A20',
      type: 'expense',
    ),
  ]);
}

/// Hosts the budget sheet behind a button that opens it.
Widget budgetSheetHost(StubBudget budgets) => ProviderScope(
  overrides: [
    settingsProvider.overrideWith(StubSheetSettings.new),
    budgetProvider.overrideWith(() => budgets),
    categoryProvider.overrideWith(StubCategories.new),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme(),
    home: Scaffold(body: Builder(builder: (c) => openBudgetSheet(c))),
  ),
);

/// The button that opens the budget sheet.
Widget openBudgetSheet(BuildContext context) => TextButton(
  onPressed: () => showBudgetSheet(context),
  child: const Text('open'),
);
