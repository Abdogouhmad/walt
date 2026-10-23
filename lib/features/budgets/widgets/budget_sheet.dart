import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/data/reports/budget_window.dart';
import 'package:walt/features/budgets/widgets/budget_alert_slider.dart';
import 'package:walt/features/budgets/widgets/budget_form_header.dart';
import 'package:walt/features/budgets/widgets/budget_save.dart';
import 'package:walt/features/budgets/widgets/budget_section_label.dart';
import 'package:walt/features/categories/category_editor_sheet.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/category_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/widgets/category_picker.dart';
import 'package:walt_ui/walt_ui.dart';

/// Opens the create-budget form in the shared bottom sheet.
///
/// Lives here (next to the form) so the shell's FAB menu can trigger it without
/// reaching into the budgets screen.
void showBudgetSheet(BuildContext context, {WaltBudget? budgetToEdit}) {
  showWaltModal<void>(
    context,
    content: BudgetSheet(budgetToEdit: budgetToEdit),
    heightFactor: 0.9,
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
  final _nameController = TextEditingController();
  late Set<int> selectedCategoryIds;
  late BudgetPeriod period;
  double alertThreshold = 0.8;
  String? accentColor;
  late bool isPinned;

  @override
  void initState() {
    super.initState();
    final budget = widget.budgetToEdit;
    if (budget != null) {
      _amountController.text = budget.amount.toString();
      _nameController.text = budget.name;
      selectedCategoryIds = budget.effectiveCategoryIds.toSet();
      period = BudgetPeriodX.parse(budget.period);
      alertThreshold = budget.alertAt;
      accentColor = budget.accentColor;
      isPinned = budget.isPinned;
    } else {
      selectedCategoryIds = {};
      period = BudgetPeriod.monthly;
      // The first budget is pinned by default so Home is not empty on the very
      // first setup.
      isPinned = (ref.read(budgetProvider).value ?? const []).isEmpty;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> saveBudget() async {
    final saved = await BudgetSaver(
      context: context,
      ref: ref,
      formKey: _formKey,
      amountController: _amountController,
      nameController: _nameController,
      selectedCategoryIds: selectedCategoryIds.toList(),
      period: period,
      accentColor: accentColor,
      isPinned: isPinned,
      alertThreshold: alertThreshold,
      budgetToEdit: widget.budgetToEdit,
    ).save();

    if (!saved || !mounted) return;
    Navigator.pop(context);
  }

  Future<void> _deleteBudget() async {
    final budget = widget.budgetToEdit;
    if (budget == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete budget?'),
        content: const Text(
          'This removes the budget and its saved period history. '
          'The transactions themselves are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(budgetProvider.notifier).deleteBudget(budget.id);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final label = budget.name.trim().isEmpty ? 'Budget' : budget.name.trim();
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text('“$label” deleted')));
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

          const BudgetSectionLabel('BUDGET LIMIT'),
          const SizedBox(height: AppSpacing.md),
          InputUI(
            labelText: 'Amount',
            controller: _amountController,
            hintText: '0.00 ($currency)',
            icon: Icons.account_balance_wallet_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppSpacing.lg),

          const BudgetSectionLabel('NAME (OPTIONAL)'),
          const SizedBox(height: AppSpacing.md),
          InputUI(
            labelText: 'Name',
            controller: _nameController,
            hintText: 'e.g. Monthly groceries',
            icon: Icons.label_outline,
            isRequired: false,
          ),
          const SizedBox(height: AppSpacing.lg),

          const BudgetSectionLabel('PERIOD'),
          const SizedBox(height: AppSpacing.md),
          PillSwitcher<BudgetPeriod>(
            value: period,
            options: BudgetPeriod.values,
            labelBuilder: (value) => value.label,
            semanticLabel: 'Budget period',
            onChanged: (value) => setState(() => period = value),
          ),
          const SizedBox(height: AppSpacing.xl),

          const BudgetSectionLabel('CATEGORIES'),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Pick every category this budget covers. Long-press one to edit it.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          CategoryPicker(
            categories: categories,
            selectedIds: selectedCategoryIds,
            mode: CategorySelectionMode.multiple,
            onToggle: (category) {
              setState(() {
                if (!selectedCategoryIds.remove(category.id)) {
                  selectedCategoryIds.add(category.id);
                }
              });
            },
            onCreate: () async {
              final created = await showCategoryEditor(context);
              if (created != null && created.type == 'expense') {
                setState(() => selectedCategoryIds.add(created.id));
              }
            },
            onLongPress: (category) async {
              final deleted = await showCategoryActions(
                context,
                category: category,
              );
              if (!deleted || !mounted) return;
              setState(() => selectedCategoryIds.remove(category.id));
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          const BudgetSectionLabel('ACCENT'),
          const SizedBox(height: AppSpacing.md),
          _AccentPicker(
            selected: accentColor,
            onSelected: (hex) => setState(() => accentColor = hex),
          ),
          const SizedBox(height: AppSpacing.xl),

          BudgetAlertSlider(
            threshold: alertThreshold,
            onChanged: (v) => setState(() => alertThreshold = v),
          ),
          const SizedBox(height: AppSpacing.lg),

          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: isPinned,
            onChanged: (value) => setState(() => isPinned = value),
            title: const Text('Pin to Home'),
            subtitle: const Text('Show this budget in the Home summary'),
            secondary: Icon(
              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            ),
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

/// Theme-derived accent choices plus a "follow theme" option.
class _AccentPicker extends StatelessWidget {
  const _AccentPicker({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final walt = WaltColors.of(context);

    String hex(Color color) =>
        '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

    final choices = <String?>[
      null,
      hex(scheme.primary),
      hex(scheme.secondary),
      hex(scheme.tertiary),
      hex(walt.income),
      hex(walt.expense),
      hex(walt.warning),
    ];
    final seen = <String>{};

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final choice in choices)
          if (choice == null || seen.add(choice.toLowerCase()))
            _AccentSwatch(
              hex: choice,
              selected: choice == null
                  ? selected == null
                  : selected?.toLowerCase() == choice.toLowerCase(),
              onTap: () => onSelected(choice),
            ),
      ],
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  final String? hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = hex == null
        ? scheme.surfaceContainerHighest
        : Color(0xFF000000 | int.parse(hex!.replaceAll('#', ''), radix: 16));

    return Semantics(
      button: true,
      selected: selected,
      label: hex == null ? 'Follow theme accent' : 'Accent $hex',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? scheme.onSurface : Colors.transparent,
                width: 2,
              ),
            ),
            child: hex == null
                ? Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  )
                : selected
                ? Icon(
                    Icons.check_rounded,
                    size: 18,
                    color:
                        ThemeData.estimateBrightnessForColor(color) ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
