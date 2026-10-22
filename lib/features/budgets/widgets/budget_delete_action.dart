import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/providers/budget_provider.dart';
import 'package:walt_ui/walt_ui.dart';

/// Deletes a budget and offers an undo.
///
/// Deleting a budget is destructive and immediate, so the confirmation is the
/// snack bar's *Undo* action rather than a dialog: the row stays where it was
/// and one tap brings the budget back.
void deleteBudgetWithUndo(
  BuildContext context,
  WidgetRef ref,
  BudgetProgress progress,
) {
  ref.read(budgetProvider.notifier).deleteBudget(progress.budget.id);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Budget for ${progress.category.name} deleted'),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(AppSpacing.md),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          ref.read(budgetProvider.notifier).addBudget(progress.budget);
        },
      ),
    ),
  );
}
