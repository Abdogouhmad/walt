import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/features/home/widgets/add_transaction_amount.dart';
import 'package:walt/features/home/widgets/add_transaction_budget.dart';
import 'package:walt/features/home/widgets/add_transaction_category.dart';
import 'package:walt/features/home/widgets/add_transaction_details.dart';
import 'package:walt/features/home/widgets/add_transaction_form_controller.dart';
import 'package:walt/features/home/widgets/add_transaction_header.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/category_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt_ui/walt_ui.dart';

/// Opens the shared bottom sheet with the add-transaction form.
///
/// [type] pre-selects Expense or Income, letting the shell's FAB menu deep-link
/// straight into the right mode.
void showAddTransactionSheet(BuildContext context, {String type = 'expense'}) {
  showWaltModal<void>(
    context,
    content: AddTransactionSheet(initialType: type),
    heightFactor: 0.92,
  );
}

/// The add-transaction form.
///
/// All of its mutable state lives in [AddTransactionFormController]; this
/// widget only assembles the three sections and forwards user intent.
class AddTransactionSheet extends ConsumerStatefulWidget {
  final String initialType;

  const AddTransactionSheet({super.key, this.initialType = 'expense'});

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  late final AddTransactionFormController _form = AddTransactionFormController(
    initialType: widget.initialType,
    onChanged: () => setState(() {}),
  );

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final saved = await _form.submit(context: context, ref: ref);
    if (!saved || !mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(settingsProvider.select((s) => s.currency));
    final categoriesAsync = ref.watch(categoryProvider);

    // Auto-select first category of matching type once data loads.
    categoriesAsync.whenData((cats) {
      final filtered = cats.where((c) => c.type == _form.type).toList();
      if (filtered.isNotEmpty &&
          !filtered.any((c) => c.id == _form.selectedCategoryId)) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _form.selectedCategoryId = filtered.first.id;
              _form.categoryError = false;
            });
          }
        });
      }
    });

    // Extra bottom room equal to the keyboard inset, so the focused field and
    // the Save button can always scroll fully clear of the keyboard.
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    // Only budgets that consume the chosen category are meaningful here. The
    // picker is expense-only because budgets never count income.
    final selectedCategoryId = _form.selectedCategoryId;
    final matchingBudgets =
        _form.type == 'expense' && selectedCategoryId != null
        ? ref
              .watch(budgetProgressProvider)
              .where(
                (p) =>
                    p.budget.effectiveCategoryIds.contains(selectedCategoryId),
              )
              .toList(growable: false)
        : const <BudgetProgress>[];

    return Form(
      key: _form.formKey,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: waltModalPadding(
          context,
        ).add(EdgeInsets.only(bottom: keyboardInset)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AddTransactionHeader(onClose: () => Navigator.pop(context)),
            const SizedBox(height: AppSpacing.sm),

            AddTransactionAmountSection(
              type: _form.type,
              onTypeChanged: (v) => setState(() {
                _form.type = v;
                _form.selectedCategoryId = null;
                _form.selectedBudgetId = null;
              }),
              currency: currency,
              amountController: _form.amountController,
              amountFocus: _form.amountFocus,
              onAmountSubmitted: (value) => _form.handleNext(
                value,
                _form.amountFocus,
                _form.merchantFocus,
              ),
            ),

            AddTransactionCategorySection(
              type: _form.type,
              categories: categoriesAsync,
              selectedCategoryId: _form.selectedCategoryId,
              hasError: _form.categoryError,
              anchorKey: _form.categoryKey,
              onChanged: (id) => setState(() {
                _form.selectedCategoryId = id;
                // The budget list is scoped to the category, so a previous
                // choice may no longer apply.
                _form.selectedBudgetId = null;
                _form.categoryError = false;
              }),
              onRetry: () => ref.read(categoryProvider.notifier).refresh(),
            ),

            if (matchingBudgets.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              AddTransactionBudgetSection(
                budgets: matchingBudgets,
                selectedBudgetId: _form.selectedBudgetId,
                currency: currency,
                onChanged: (id) => setState(() => _form.selectedBudgetId = id),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),

            AddTransactionDetailsSection(
              merchantController: _form.merchantController,
              merchantFocus: _form.merchantFocus,
              onMerchantSubmitted: (value) =>
                  _form.handleNext(value, _form.merchantFocus, _form.noteFocus),
              noteController: _form.noteController,
              noteFocus: _form.noteFocus,
              onSubmit: _submit,
              selectedDate: _form.selectedDate,
              onPickDate: () => _form.pickDate(context),
              isSaving: _form.isSaving,
            ),
          ],
        ),
      ),
    );
  }
}
