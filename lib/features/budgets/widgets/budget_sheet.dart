import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/core/design/radius.dart';
import 'package:walt/core/design/spacing.dart';
import 'package:walt/core/utils/category_icon.dart';
import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/category_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/bottons.dart';
import 'package:walt/shared/input_ui.dart';
import 'package:walt/shared/status_badge.dart';
import 'package:walt/shared/text_ui.dart';
import 'package:walt/shared/ui_modal.dart';

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

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: waltModalPadding(context),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
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
                  const SizedBox(height: AppSpacing.xs),
                  UiText(
                    text: isEditing
                        ? "Adjust your spending limits"
                        : "Set bounds to save smarter",
                    type: UiTextType.bodySmall,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
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
                color: Theme.of(context).colorScheme.error,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        _SectionLabel("MONTHLY LIMIT"),
        const SizedBox(height: AppSpacing.md),
        InputUI(
          labelText: "Amount",
          controller: _amountController,
          hintText: "0.00 ($currency)",
          icon: Icons.account_balance_wallet_outlined,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: AppSpacing.xl),

        const _SectionLabel("SELECT CATEGORY"),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: categories.map((category) {
            final selected = selectedCategoryId == category.id;
            final categoryColor = Color(
              int.parse(category.color.replaceAll('#', '0xFF')),
            );

            return GestureDetector(
              onTap: isEditing
                  ? null
                  : () => setState(() => selectedCategoryId = category.id),
              child: Opacity(
                opacity: isEditing && !selected ? 0.5 : 1.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? categoryColor.withValues(alpha: 0.14)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.field),
                    border: Border.all(
                      color: selected
                          ? categoryColor
                          : Theme.of(context).colorScheme.outline.withValues(
                              alpha: 0.16,
                            ),
                      width: selected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CategoryIcons.getIcon(category.icon),
                        size: AppSpacing.sm,
                        color: selected
                            ? categoryColor
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      UiText(
                        text: category.name,
                        type: UiTextType.bodySmall,
                        style: TextStyle(
                          color: selected
                              ? categoryColor
                              : Theme.of(context).colorScheme.primary,
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
        const SizedBox(height: AppSpacing.xl),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionLabel("ALERT THRESHOLD"),
            StatusBadge(
              label: "${(alertThreshold * 100).toInt()}% spent",
              variant: StatusBadgeVariant.accent,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Theme.of(context).colorScheme.outline
                .withValues(alpha: 0.16),
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.12),
            valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: alertThreshold,
            min: .5,
            max: 1,
            divisions: 10,
            onChanged: (v) => setState(() => alertThreshold = v),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        AppButton(
          label: isEditing ? "Update Budget" : "Create Budget",
          onPressed: saveBudget,
          size: ButtonSize.large,
          isFullWidth: true,
          type: ButtonType.primary,
        ),
      ],
    );
  }
}

/// Small uppercase section heading used by the budget form.
class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return UiText(
      text: text,
      type: UiTextType.labelSmall,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}