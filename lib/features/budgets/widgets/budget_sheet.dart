import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/features/budgets/widgets/budget_alert_slider.dart';
import 'package:walt/features/budgets/widgets/budget_category_picker.dart';
import 'package:walt/features/budgets/widgets/budget_form_header.dart';
import 'package:walt/features/budgets/widgets/budget_save.dart';
import 'package:walt/features/budgets/widgets/budget_section_label.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/category_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt_ui/walt_ui.dart';

/// Opens the create-budget form in the shared bottom sheet.
///
/// Lives here (next to the form) so the shell's FAB menu can trigger it without
/// reaching into the budgets screen.
void showBudgetSheet(BuildContext context, {WaltBudget? budgetToEdit}) {
  showWaltModal<void>(
    context,
    content: BudgetSheet(budgetToEdit: budgetToEdit),
    heightFactor: 0.8,
  );
}

/// Create / edit budget form. Rendered inside the app's shared bottom sheet
/// ([showWaltModal]) so it never hand-rolls a sheet shell — it only provides
/// the scrollable form body.
class BudgetSheet extends ConsumerStatefulWidget {
  final WaltBudget? budgetToEdit;

  const BudgetSheet({super.key, this.budgetToEdit});

  @override
  ConsumerState<BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends ConsumerState<BudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  int? selectedCategoryId;
  double alertThreshold = 0.8;

  @override
  void initState() {
    super.initState();
    if (widget.budgetToEdit != null) {
      _amountController.text = widget.budgetToEdit!.amount.toString();
      selectedCategoryId = widget.budgetToEdit!.categoryId;
      alertThreshold = widget.budgetToEdit!.alertAt;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> saveBudget() async {
    final saved = await BudgetSaver(
      context: context,
      ref: ref,
      formKey: _formKey,
      amountController: _amountController,
      selectedCategoryId: selectedCategoryId,
      alertThreshold: alertThreshold,
      budgetToEdit: widget.budgetToEdit,
    ).save();

    if (!saved || !mounted) return;
    Navigator.pop(context);
  }

  Future<void> _deleteBudget() async {
    await ref
        .read(budgetProvider.notifier)
        .deleteBudget(widget.budgetToEdit!.id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        ref
            .watch(categoryProvider)
            .value
            ?.where((e) => e.type == 'expense')
            .toList() ??
        [];
    final currency = ref.watch(settingsProvider.select((s) => s.currency));
    final isEditing = widget.budgetToEdit != null;

    // The form key has to be attached to a real `Form` for `validate()` to
    // reach the `TextFormField` inside [InputUI].
    return Form(
      key: _formKey,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: waltModalPadding(context),
        children: [
          BudgetFormHeader(isEditing: isEditing, onDelete: _deleteBudget),
          const SizedBox(height: AppSpacing.xl),

          const BudgetSectionLabel('MONTHLY LIMIT'),
          const SizedBox(height: AppSpacing.md),
          InputUI(
            labelText: 'Amount',
            controller: _amountController,
            hintText: '0.00 ($currency)',
            icon: Icons.account_balance_wallet_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppSpacing.xl),

          const BudgetSectionLabel('SELECT CATEGORY'),
          const SizedBox(height: AppSpacing.md),
          BudgetCategoryPicker(
            categories: categories,
            selectedCategoryId: selectedCategoryId,
            isEditing: isEditing,
            onSelected: (id) => setState(() => selectedCategoryId = id),
          ),
          const SizedBox(height: AppSpacing.xl),

          BudgetAlertSlider(
            threshold: alertThreshold,
            onChanged: (v) => setState(() => alertThreshold = v),
          ),
          const SizedBox(height: AppSpacing.lg),

          AppButton(
            label: isEditing ? 'Update Budget' : 'Create Budget',
            onPressed: saveBudget,
            size: ButtonSize.large,
            isFullWidth: true,
            type: ButtonType.primary,
          ),
        ],
      ),
    );
  }
}
