import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/data/reports/budget_window.dart';
import 'package:walt/data/services/notification_preferences.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/category_provider.dart';

/// Validates the budget form and persists it.
///
/// Kept out of the widget so the form's build tree stays readable and the
/// rules (what counts as valid, how pin order is assigned) live in one place
/// instead of being scattered through a button handler.
class BudgetSaver {
  const BudgetSaver({
    required this.context,
    required this.ref,
    required this.formKey,
    required this.amountController,
    required this.nameController,
    required this.selectedCategoryIds,
    required this.period,
    required this.accentColor,
    required this.isPinned,
    required this.alertThreshold,
    required this.budgetToEdit,
  });

  final BuildContext context;
  final WidgetRef ref;
  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  final TextEditingController nameController;
  final List<int> selectedCategoryIds;
  final BudgetPeriod period;
  final String? accentColor;
  final bool isPinned;
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

    if (selectedCategoryIds.isEmpty) {
      // Not a silent `return`: tapping Create with nothing selected used to
      // look like the button was broken.
      _showMessage('Please select at least one category');
      return false;
    }

    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      _showMessage('Please enter a valid amount');
      return false;
    }

    final name = nameController.text.trim();
    if (name.length > 80) {
      _showMessage('Keep the budget name under 80 characters');
      return false;
    }

    final budgetNotifier = ref.read(budgetProvider.notifier);
    final existingBudgets =
        ref.read(budgetProvider).value ?? const <WaltBudget>[];
    final categories = ref.read(categoryProvider).value ?? const [];
    final categoryIds = selectedCategoryIds.toSet().toList(growable: false);

    // A budget without a name still has to read as something on Home and in
    // the list. The first selected category is the primary one, matching the
    // legacy `categoryId` column; [BudgetProgress.displayName] derives a
    // comma-separated label from the categories if the stored name is empty.
    final pinOrder = _nextPinOrder(
      existingBudgets,
      isPinned: isPinned,
      editing: budgetToEdit,
    );

    if (budgetToEdit == null) {
      await budgetNotifier.addBudget(
        WaltBudget(
          id: 0,
          categoryId: categoryIds.first,
          categoryIds: categoryIds,
          name: name,
          amount: amount,
          period: period.label,
          alertAt: alertThreshold,
          accentColor: accentColor,
          isPinned: isPinned,
          pinOrder: pinOrder,
          createdAt: DateTime.now(),
        ),
      );

      // A budget is the whole reason alerts exist, so this is the one place
      // where asking for notification permission has real context. Only on
      // the very first budget, and only if the OS prompt has not been
      // dismissed before.
      if (existingBudgets.isEmpty) {
        await requestNotificationPermission();
        // Re-evaluate straight away: a budget created already over its limit
        // should say so now, not after the next unrelated change.
        await evaluateBudgetAlertsNow(ref);
      }
    } else {
      final updated = budgetToEdit!.copyWith(
        categoryId: categoryIds.first,
        categoryIds: categoryIds,
        name: name,
        amount: amount,
        period: period.label,
        alertAt: alertThreshold,
        accentColor: accentColor,
        isPinned: isPinned,
        pinOrder: pinOrder,
      );
      await budgetNotifier.updateBudget(updated);
      await evaluateBudgetAlertsNow(ref);
    }

    // Keep the category names in the snack bar rather than a bare "saved", so
    // a multi-category budget confirms *what* it covers.
    final namesById = {
      for (final category in categories) category.id: category.name,
    };
    final label = name.isNotEmpty
        ? name
        : categoryIds.map((id) => namesById[id]).whereType<String>().join(', ');
    if (label.isNotEmpty) {
      _showMessage(
        budgetToEdit == null ? 'Budget "$label" created' : 'Budget updated',
      );
    }

    return true;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Pinned budgets are ordered by `pinOrder`. A newly pinned budget goes to
  /// the end; an already-pinned budget keeps its slot so editing its amount
  /// does not silently move it on Home.
  int _nextPinOrder(
    List<WaltBudget> existing, {
    required bool isPinned,
    required WaltBudget? editing,
  }) {
    if (!isPinned) return 0;
    if (editing != null && editing.isPinned) return editing.pinOrder;
    final maxOrder = existing
        .where((b) => b.isPinned)
        .fold<int>(-1, (order, b) => math.max(order, b.pinOrder));
    return maxOrder + 1;
  }
}
