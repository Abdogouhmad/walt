import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/core/design/spacing.dart';
import 'package:walt/core/theme/text_theme.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/features/home/widgets/category_widget.dart';
import 'package:walt/features/home/widgets/date.dart';
import 'package:walt/features/home/widgets/txtype_picker.dart';
import 'package:walt/providers/category_provider.dart';
import 'package:walt/providers/report_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/providers/transaction_provider.dart';
import 'package:walt/shared/bottons.dart';
import 'package:walt/shared/input_ui.dart';
import 'package:walt/shared/ui_modal.dart';

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

class AddTransactionSheet extends ConsumerStatefulWidget {
  final String initialType;

  const AddTransactionSheet({super.key, this.initialType = 'expense'});

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _merchantController = TextEditingController();

  late String _type = widget.initialType;
  int? _selectedCategoryId; // null until categories load
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) return;

    setState(() => _isSaving = true);

    final transaction = WaltTransaction(
      id: DateTime.now().millisecondsSinceEpoch,
      amount: double.parse(_amountController.text.trim()),
      type: _type,
      categoryId: _selectedCategoryId!,
      merchant: _merchantController.text.trim(),
      note: _noteController.text.trim(),
      date: _selectedDate,
    );

    try {
      await ref.read(transactionProvider.notifier).addTransaction(transaction);
      ref.invalidate(reportProvider);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving transaction: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;
    final currency = ref.watch(settingsProvider.select((s) => s.currency));
    final categoriesAsync = ref.watch(categoryProvider);

    // Auto-select first category of matching type once data loads.
    categoriesAsync.whenData((cats) {
      final filtered = cats.where((c) => c.type == _type).toList();
      if (filtered.isNotEmpty &&
          !filtered.any((c) => c.id == _selectedCategoryId)) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedCategoryId = filtered.first.id);
        });
      }
    });

    return Form(
      key: _formKey,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: waltModalPadding(context),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Add transaction',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          TypeToggle(
            value: _type,
            onChanged: (v) {
              setState(() {
                _type = v;
                _selectedCategoryId = null;
              });
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          SizedBox(
            width: double.infinity,
            child: Text(
              'Amount ($currency)',
              textAlign: TextAlign.center,
              style: textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          TextFormField(
            controller: _amountController,
            autofocus: true,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: AppTextTheme.tabular,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '0.00',
              hintStyle: textTheme.displaySmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                fontWeight: FontWeight.w700,
              ),
            ),
            validator: (value) {
              final parsed = double.tryParse(value?.trim() ?? '');
              if (parsed == null || parsed <= 0) {
                return 'Please enter a valid amount';
              }
              return null;
            },
          ),
          Divider(height: AppSpacing.xl, color: scheme.outlineVariant),

          Text('Category', style: textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),

          categoriesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, _) => Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: AppSpacing.md,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Failed to load categories',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      ref.read(categoryProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
            data: (categories) {
              final filtered = categories
                  .where((c) => c.type == _type)
                  .toList();
              return CategoryPicker(
                categories: filtered,
                selected: _selectedCategoryId,
                onChanged: (id) => setState(() => _selectedCategoryId = id),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          InputUI(
            controller: _merchantController,
            labelText: 'Merchant',
            textError: 'Enter a description',
            keyboardType: TextInputType.text,
            regexPattern: r'^.{3,}$',
            icon: Icons.store,
          ),
          const SizedBox(height: AppSpacing.md),
          InputUI(
            controller: _noteController,
            labelText: 'Note (optional)',
            keyboardType: TextInputType.text,
            regexPattern: r'^.{3,}$',
            textError: null,
            icon: Icons.edit_note,
          ),
          const SizedBox(height: AppSpacing.lg),

          DateWidget(date: _selectedDate, onTap: _pickDate),
          const SizedBox(height: AppSpacing.xl),

          AppButton(
            label: 'Save Transaction',
            onPressed: _submit,
            isLoading: _isSaving,
            isFullWidth: true,
            tooltip: 'Save the transaction',
            type: ButtonType.primary,
            size: ButtonSize.large,
          ),
        ],
      ),
    );
  }
}
