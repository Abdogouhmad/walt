import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/core/constants/app_colors.dart';
import 'package:walt/core/utils/category_icon.dart';
import 'package:walt/core/utils/context.dart';
import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/data/services/notification_service.dart';
import 'package:walt/providers/budget_progress_provider.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/category_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/bottons.dart';
import 'package:walt/shared/input_ui.dart';
import 'package:walt/shared/text_ui.dart';

class BudgetSheet extends ConsumerStatefulWidget {
  const BudgetSheet({super.key});

  @override
  ConsumerState<BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends ConsumerState<BudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  int? selectedCategoryId;
  double alertThreshold = 0.8;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void saveBudget() {
    if (!_formKey.currentState!.validate() || selectedCategoryId == null) {
      return;
    }
    ref.read(budgetProvider.notifier).addBudget(
          WaltBudget(
            id: 0,
            categoryId: selectedCategoryId!,
            amount: double.parse(_amountController.text),
            period: 'Monthly',
            alertAt: alertThreshold,
            createdAt: DateTime.now(),
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider).value?.where(
              (e) => e.type == 'expense',
            ).toList() ?? [];

    final currency = ref.watch(
      settingsProvider.select((s) => s.currency),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            context.w(24),
            context.h(12),
            context.w(24),
            MediaQuery.of(context).viewInsets.bottom + context.h(24),
          ),
          decoration: BoxDecoration(
            color: context.colorAppScheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(context.r(28)),
            ),
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: controller,
              physics: const BouncingScrollPhysics(),
              children: [
                /// Minimalist Pill Handle
                Center(
                  child: Container(
                    width: context.w(40),
                    height: context.h(4),
                    decoration: BoxDecoration(
                      color: context.colorAppScheme.outline.withAlpha(60),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: context.h(24)),

                /// Header Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UiText(
                          text: "New Budget",
                          type: UiTextType.titleLarge,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: context.h(4)),
                        UiText(
                          text: "Set bounds to save smarter",
                          type: UiTextType.bodySmall,
                          style: TextStyle(
                            color: context.textSecondary.withAlpha(200),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: context.h(32)),

                /// Amount Input Section (Clean & Borderless Focus)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UiText(
                      text: "HOW MUCH?",
                      type: UiTextType.labelSmall,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: context.h(10)),
                    InputUI(
                      labelText: "Amount",
                      controller: _amountController,
                      hintText: "0.00 ($currency)",
                      icon: Icons.attach_money, // Swapped for a modern alternate token look if needed, or stick to your preferred icon
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(32)),

                /// Categories Section
                Row(
                  children: [
                    UiText(
                      text: "SELECT CATEGORY",
                      type: UiTextType.labelSmall,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(14)),
                Wrap(
                  spacing: context.w(8),
                  runSpacing: context.h(8),
                  children: categories.map((category) {
                    final selected = selectedCategoryId == category.id;
                    final categoryColor = Color(
                      int.parse(category.color.replaceAll('#', '0xFF')),
                    );

                    return GestureDetector(
                      onTap: () => setState(() => selectedCategoryId = category.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: EdgeInsets.symmetric(
                          horizontal: context.w(16),
                          vertical: context.h(10),
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? categoryColor.withAlpha(35)
                              : context.colorAppScheme.surface,
                          borderRadius: BorderRadius.circular(context.r(20)),
                          border: Border.all(
                            color: selected
                                ? categoryColor
                                : context.colorAppScheme.outline.withAlpha(40),
                            width: selected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CategoryIcons.getIcon(category.icon),
                              size: context.w(16),
                              color: selected ? categoryColor : context.textSecondary,
                            ),
                            SizedBox(width: context.w(8)),
                            UiText(
                              text: category.name,
                              type: UiTextType.bodySmall,
                              style: TextStyle(
                                color: selected ? categoryColor : context.primary,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: context.h(36)),

                /// Modernized Alert Section (No Card Border, Clean Row Setup)
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
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: context.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: UiText(
                            text: "${(alertThreshold * 100).toInt()}% spent",
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
                        trackHeight: 4,
                        activeTrackColor: context.primary,
                        inactiveTrackColor: context.colorAppScheme.outline.withAlpha(40),
                        thumbColor: context.primary,
                        overlayColor: context.primary.withAlpha(30),
                        valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
                      ),
                      child: Slider(
                        value: alertThreshold,
                        min: .5,
                        max: 1,
                        divisions: 10,
                        onChanged: (v) => setState(() => alertThreshold = v),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(40)),

                /// Action Button
                AppButton(
                  label: "Create Budget",
                  onPressed: saveBudget,
                  size: ButtonSize.large,
                  isFullWidth: true,
                  type: ButtonType.primary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
