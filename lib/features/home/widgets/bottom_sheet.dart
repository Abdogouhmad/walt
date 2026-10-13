import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/core/design/spacing.dart';
import 'package:walt/core/theme/motion.dart';
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

  // One FocusNode per text field so the keyboard's Next/Done action can walk
  // the form in order (Amount → Merchant → Note) instead of being implicit.
  final _amountFocus = FocusNode();
  final _merchantFocus = FocusNode();
  final _noteFocus = FocusNode();

  /// Anchor for the category section, used to scroll it into view when a save
  /// is blocked only because no chip is selected.
  final _categoryKey = GlobalKey();

  late String _type = widget.initialType;
  int? _selectedCategoryId; // null until categories load
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  /// True after a save attempt that found no category selected. Drives the red
  /// helper text under the chips (mirrors a text field's error line).
  bool _categoryError = false;

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    _merchantFocus.dispose();
    _noteFocus.dispose();
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

  /// Handles the keyboard's "Next" action.
  ///
  /// An empty field must never be skipped: it shows its "Required" error and
  /// keeps focus. Only a filled field advances to [next].
  void _handleNext(String value, FocusNode current, FocusNode next) {
    if (value.trim().isEmpty) {
      _formKey.currentState?.validate();
      current.requestFocus();
      return;
    }
    next.requestFocus();
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    final categoryMissing = _selectedCategoryId == null;

    // Refresh the chip error on every attempt so it clears as soon as a
    // category is selected.
    if (_categoryError != categoryMissing) {
      setState(() => _categoryError = categoryMissing);
    }

    if (!formValid || categoryMissing) {
      // Text fields are fine but the chips were missed: bring them into view
      // so the user can see what the error is pointing at.
      if (formValid && categoryMissing) {
        final categoryContext = _categoryKey.currentContext;
        if (categoryContext != null) {
          await Scrollable.ensureVisible(
            categoryContext,
            duration: AppMotion.medium,
            curve: AppMotion.standard,
            alignment: 0.1,
          );
        }
      }
      return;
    }

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
          if (mounted) {
            setState(() {
              _selectedCategoryId = filtered.first.id;
              _categoryError = false;
            });
          }
        });
      }
    });

    // Extra bottom room equal to the keyboard inset, so the focused field and
    // the Save button can always scroll fully clear of the keyboard.
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: waltModalPadding(
          context,
        ).add(EdgeInsets.only(bottom: keyboardInset)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
              focusNode: _amountFocus,
              autofocus: true,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
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
              onFieldSubmitted: (value) =>
                  _handleNext(value, _amountFocus, _merchantFocus),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Required';
                final parsed = double.tryParse(text);
                if (parsed == null || parsed <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            Divider(height: AppSpacing.xl, color: scheme.outlineVariant),

            Text('Category', key: _categoryKey, style: textTheme.labelLarge),
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
                    color: scheme.error,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Failed to load categories',
                    style: TextStyle(color: scheme.error, fontSize: 13),
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
                  onChanged: (id) => setState(() {
                    _selectedCategoryId = id;
                    _categoryError = false;
                  }),
                );
              },
            ),
            if (_categoryError)
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  left: AppSpacing.md,
                ),
                child: Text(
                  'Select a category',
                  style: textTheme.bodySmall?.copyWith(color: scheme.error),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),

            InputUI(
              controller: _merchantController,
              focusNode: _merchantFocus,
              labelText: 'Merchant',
              textError: 'Enter a description',
              requiredMessage: 'Required',
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (value) =>
                  _handleNext(value, _merchantFocus, _noteFocus),
              regexPattern: r'^.{3,}$',
              icon: Icons.store,
            ),
            const SizedBox(height: AppSpacing.md),
            InputUI(
              controller: _noteController,
              focusNode: _noteFocus,
              labelText: 'Note (optional)',
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              isRequired: false,
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
      ),
    );
  }
}
