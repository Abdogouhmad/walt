import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/report_provider.dart';
import 'package:walt/providers/transaction_provider.dart';
import 'package:walt_ui/walt_ui.dart';

/// The mutable state of the add-transaction form.
///
/// Pulled out of the widget so the sheet file stays a *view*: everything that
/// mutates state lives here, and the widget only rebuilds when the controller
/// says so through [onChanged].
class AddTransactionFormController {
  AddTransactionFormController({required this.initialType, this.onChanged})
    : type = initialType;

  /// The mode the sheet opens in: `expense` or `income`.
  final String initialType;

  /// Called whenever a field changes, so the widget can `setState`.
  final VoidCallback? onChanged;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController merchantController = TextEditingController();

  // One FocusNode per text field so the keyboard's Next/Done action can walk
  // the form in order (Amount → Merchant → Note) instead of being implicit.
  final FocusNode amountFocus = FocusNode();
  final FocusNode merchantFocus = FocusNode();
  final FocusNode noteFocus = FocusNode();

  /// Anchor for the category section, used to scroll it into view when a save
  /// is blocked only because no chip is selected.
  final GlobalKey categoryKey = GlobalKey();

  String type;
  int? selectedCategoryId; // null until categories load

  /// Optional budget the expense is booked against. Null keeps the legacy
  /// category-based attribution; the picker only offers budgets that include
  /// the selected category.
  int? selectedBudgetId;
  DateTime selectedDate = DateTime.now();
  bool isSaving = false;

  /// True after a save attempt that found no category selected. Drives the red
  /// helper text under the chips (mirrors a text field's error line).
  bool categoryError = false;

  void dispose() {
    amountController.dispose();
    merchantController.dispose();
    noteController.dispose();
    amountFocus.dispose();
    merchantFocus.dispose();
    noteFocus.dispose();
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      selectedDate = picked;
      onChanged?.call();
    }
  }

  /// Handles the keyboard's "Next" action.
  ///
  /// An empty field must never be skipped: it shows its "Required" error and
  /// keeps focus. Only a filled field advances to [next].
  void handleNext(String value, FocusNode current, FocusNode next) {
    if (value.trim().isEmpty) {
      formKey.currentState?.validate();
      current.requestFocus();
      return;
    }
    next.requestFocus();
  }

  /// Validates the form and writes the transaction.
  ///
  /// Returns `true` when the transaction was saved.
  Future<bool> submit({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final formValid = formKey.currentState?.validate() ?? false;
    final categoryMissing = selectedCategoryId == null;

    // Refresh the chip error on every attempt so it clears as soon as a
    // category is selected.
    if (categoryError != categoryMissing) {
      categoryError = categoryMissing;
      onChanged?.call();
    }

    if (!formValid || categoryMissing) {
      // Text fields are fine but the chips were missed: bring them into view
      // so the user can see what the error is pointing at.
      if (formValid && categoryMissing) {
        final categoryContext = categoryKey.currentContext;
        if (categoryContext != null) {
          await Scrollable.ensureVisible(
            categoryContext,
            duration: AppMotion.medium,
            curve: AppMotion.standard,
            alignment: 0.1,
          );
        }
      }
      return false;
    }

    isSaving = true;
    onChanged?.call();

    // A budget selected before the sheet's budget list refreshed could no
    // longer exist, or may no longer cover the chosen category. Dropping the
    // link is safer than persisting an invalid one; the transaction still
    // counts by category.
    var budgetId = type == 'expense' ? selectedBudgetId : null;
    if (budgetId != null) {
      final categoryId = selectedCategoryId!;
      final budgets = ref.read(budgetProvider).value ?? const <WaltBudget>[];
      final stillValid = budgets.any(
        (b) => b.id == budgetId && b.effectiveCategoryIds.contains(categoryId),
      );
      if (!stillValid) budgetId = null;
    }

    final transaction = WaltTransaction(
      id: DateTime.now().millisecondsSinceEpoch,
      amount: double.parse(amountController.text.trim()),
      type: type,
      categoryId: selectedCategoryId!,
      budgetId: budgetId,
      merchant: merchantController.text.trim(),
      note: noteController.text.trim(),
      date: selectedDate,
    );

    try {
      await ref.read(transactionProvider.notifier).addTransaction(transaction);
      ref.invalidate(reportProvider);
      return true;
    } catch (e) {
      debugPrint('Error saving transaction: $e');
      return false;
    } finally {
      isSaving = false;
      onChanged?.call();
    }
  }
}
