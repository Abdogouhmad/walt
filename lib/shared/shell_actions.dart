import 'package:flutter/material.dart';

import 'package:walt/features/budgets/widgets/budget_sheet.dart';
import 'package:walt/features/home/widgets/bottom_sheet.dart';
import 'package:walt_ui/walt_ui.dart';

/// The FAB menu's actions for the current route.
///
/// The budgets screen offers a budget instead of a transaction; every other
/// tab offers the two transaction directions.
List<FabAction> shellActionsFor(String location, BuildContext context) {
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
