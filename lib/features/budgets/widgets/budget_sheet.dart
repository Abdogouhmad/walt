import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/core/constants/app_colors.dart';
import 'package:walt/core/utils/category_icon.dart';
import 'package:walt/core/utils/context.dart';
import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/category_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/bottons.dart';
import 'package:walt/shared/input_ui.dart';
import 'package:walt/shared/text_ui.dart';

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

  void saveBudget() {
    if (!_formKey.currentState!.validate() || selectedCategoryId == null) {
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final budgetNotifier = ref.read(budgetProvider.notifier);
    final existingBudgets = ref.read(budgetProvider).value ?? [];

    if (widget.budgetToEdit == null) {
      // Check if a budget already exists for this category
      final alreadyExists = existingBudgets.any(
        (b) => b.categoryId == selectedCategoryId,
      );

      if (alreadyExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A budget for this category already exists.'),
          ),
        );
        return;
      }

      budgetNotifier.addBudget(
        WaltBudget(
          id: 0,
          categoryId: selectedCategoryId!,
          amount: amount,
          period: 'Monthly',
          alertAt: alertThreshold,
          createdAt: DateTime.now(),
        ),
      );
    } else {
      budgetNotifier.updateBudget(
        widget.budgetToEdit!.copyWith(
          categoryId: selectedCategoryId!,
          amount: amount,
          alertAt: alertThreshold,
        ),
      );
    }

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

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: context.colorAppScheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(context.r(32)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              /// Handle
              Container(
                margin: EdgeInsets.only(top: context.h(12)),
                width: context.w(40),
                height: context.h(4),
                decoration: BoxDecoration(
                  color: context.colorAppScheme.outline.withAlpha(60),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: controller,
                    padding: EdgeInsets.fromLTRB(
                      context.w(24),
                      context.h(24),
                      context.w(24),
                      MediaQuery.of(context).viewInsets.bottom + context.h(24),
                    ),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      /// Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              UiText(
                                text: isEditing ? "Edit Budget" : "New Budget",
                                type: UiTextType.titleLarge,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: context.h(4)),
                              UiText(
                                text: isEditing
                                    ? "Adjust your spending limits"
                                    : "Set bounds to save smarter",
                                type: UiTextType.bodySmall,
                                style: TextStyle(
                                  color: context.textSecondary.withAlpha(200),
                                ),
                              ),
                            ],
                          ),
                          if (isEditing)
                            IconButton.filledTonal(
                              onPressed: () {
                                ref
                                    .read(budgetProvider.notifier)
                                    .deleteBudget(widget.budgetToEdit!.id);
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.delete_outline),
                              color: context.colorAppScheme.error,
                            ),
                        ],
                      ),
                      SizedBox(height: context.h(32)),

                      /// Amount Input
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UiText(
                            text: "MONTHLY LIMIT",
                            type: UiTextType.labelSmall,
                            style: TextStyle(
                              color: context.textSecondary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: context.h(12)),
                          InputUI(
                            labelText: "Amount",
                            controller: _amountController,
                            hintText: "0.00 ($currency)",
                            icon: Icons.account_balance_wallet_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.h(32)),

                      /// Categories Section
                      UiText(
                        text: "SELECT CATEGORY",
                        type: UiTextType.labelSmall,
                        style: TextStyle(
                          color: context.textSecondary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: context.h(16)),
                      Wrap(
                        spacing: context.w(8),
                        runSpacing: context.h(8),
                        children: categories.map((category) {
                          final selected = selectedCategoryId == category.id;
                          final categoryColor = Color(
                            int.parse(category.color.replaceAll('#', '0xFF')),
                          );

                          return GestureDetector(
                            onTap: isEditing
                                ? null // Prevent changing category when editing
                                : () => setState(
                                    () => selectedCategoryId = category.id,
                                  ),
                            child: Opacity(
                              opacity: isEditing && !selected ? 0.5 : 1.0,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.w(16),
                                  vertical: context.h(10),
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? categoryColor.withAlpha(35)
                                      : context.colorAppScheme.surface,
                                  borderRadius: BorderRadius.circular(
                                    context.r(20),
                                  ),
                                  border: Border.all(
                                    color: selected
                                        ? categoryColor
                                        : context.colorAppScheme.outline
                                              .withAlpha(40),
                                    width: selected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      CategoryIcons.getIcon(category.icon),
                                      size: context.w(16),
                                      color: selected
                                          ? categoryColor
                                          : context.textSecondary,
                                    ),
                                    SizedBox(width: context.w(8)),
                                    UiText(
                                      text: category.name,
                                      type: UiTextType.bodySmall,
                                      style: TextStyle(
                                        color: selected
                                            ? categoryColor
                                            : context.primary,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: context.h(36)),

                      /// Alert Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              UiText(
                                text: "ALERT THRESHOLD",
                                type: UiTextType.labelSmall,
                                style: TextStyle(
                                  color: context.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: context.primary.withAlpha(25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: UiText(
                                  text:
                                      "${(alertThreshold * 100).toInt()}% spent",
                                  type: UiTextType.labelSmall,
                                  style: TextStyle(
                                    color: context.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.h(8)),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 6,
                              activeTrackColor: context.primary,
                              inactiveTrackColor: context.colorAppScheme.outline
                                  .withAlpha(40),
                              thumbColor: context.primary,
                              overlayColor: context.primary.withAlpha(30),
                              valueIndicatorShape:
                                  const PaddleSliderValueIndicatorShape(),
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                              ),
                            ),
                            child: Slider(
                              value: alertThreshold,
                              min: .5,
                              max: 1,
                              divisions: 10,
                              onChanged: (v) =>
                                  setState(() => alertThreshold = v),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.h(40)),

                      /// Action Button
                      AppButton(
                        label: isEditing ? "Update Budget" : "Create Budget",
                        onPressed: saveBudget,
                        size: ButtonSize.large,
                        isFullWidth: true,
                        type: ButtonType.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
