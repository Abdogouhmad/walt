import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/data/services/notification_preferences.dart';
import 'package:walt/providers/budget_provider.dart';

/// Validates the budget form and persists it.
///
/// Kept out of the widget so the form's build tree stays readable and the
/// rules (what counts as valid, what happens on a duplicate) live in one
/// place instead of being scattered through the button handler.
class BudgetSaver {
  const BudgetSaver({
    required this.context,
    required this.ref,
    required this.formKey,
    required this.amountController,
    required this.selectedCategoryId,
    required this.alertThreshold,
    required this.budgetToEdit,
  });

  final BuildContext context;
  final WidgetRef ref;
  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  final int? selectedCategoryId;
  final double alertThreshold;
  final WaltBudget? budgetToEdit;

  /// Returns `true` when the budget was written and the caller should close
  /// the sheet.
  Future<bool> save() async {
    // `currentState` is null whenever no `Form` is currently mounted with this
    // key. That used to throw "Null check operator used on a null value" on
    // every single save, because the key was never attached to a `Form` at all.
    // The `Form` now exists (see the form body), but the fallback keeps a save
    // from ever taking the app down if the sheet is torn down mid-tap — the
    // checks below still guard the data.
    final form = formKey.currentState;
    if (form != null && !form.validate()) {
      return false;
    }

    if (selectedCategoryId == null) {
      // Previously a silent `return`, so tapping Create with nothing selected
      // looked like the button was broken.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return false;
    }

    final amount = double.tryParse(amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return false;
    }

    final budgetNotifier = ref.read(budgetProvider.notifier);
    final existingBudgets = ref.read(budgetProvider).value ?? [];

    if (budgetToEdit == null) {
      final alreadyExists = existingBudgets.any(
        (b) => b.categoryId == selectedCategoryId,
      );

      if (alreadyExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A budget for this category already exists.'),
          ),
        );
        return false;
      }

      await budgetNotifier.addBudget(
        WaltBudget(
          id: 0,
          categoryId: selectedCategoryId!,
          amount: amount,
          period: 'Monthly',
          alertAt: alertThreshold,
          createdAt: DateTime.now(),
        ),
      );

      // A budget is the whole reason alerts exist, so this is the one place
      // where asking for notification permission has real context. Only on the
      // very first budget, and only if the OS prompt has not been dismissed
      // before.
      if (existingBudgets.isEmpty) {
        await requestNotificationPermission();
        // Re-evaluate straight away: a budget created already over its limit
        // should say so now, not after the next unrelated change.
        await evaluateBudgetAlertsNow(ref);
      }
    } else {
      await budgetNotifier.updateBudget(
        budgetToEdit!.copyWith(
          categoryId: selectedCategoryId!,
          amount: amount,
          alertAt: alertThreshold,
        ),
      );
    }

    return true;
  }
}
