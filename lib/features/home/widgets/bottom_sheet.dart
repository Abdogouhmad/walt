import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/features/home/widgets/category_widget.dart';
import 'package:walt/features/home/widgets/date.dart';
import 'package:walt/features/home/widgets/txtype_picker.dart';
import 'package:walt/providers/category_provider.dart';
import 'package:walt/providers/report_provider.dart';
import 'package:walt/providers/transaction_provider.dart';
import 'package:walt/shared/bottons.dart';
import 'package:walt/shared/input_ui.dart';
import 'package:walt/data/local/transaction_dao.dart';

void showAddTransactionSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AddTransactionSheet(),
  );
}

// ── sheet ─────────────────────────────────────────────────────────────────────

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _merchantController = TextEditingController();

  String _type = 'expense';
  int? _selectedCategoryId; // null until categories load
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  // ── actions ───────────────────────────────────────────────────────────────

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

    // 1. Create the transaction object
    final transaction = WaltTransaction(
      // Ensure your DAO/Database handles ID auto-increment,
      // otherwise keep your timestamp logic
      id: DateTime.now().millisecondsSinceEpoch,
      amount: double.parse(_amountController.text.trim()),
      type: _type,
      categoryId: _selectedCategoryId!,
      merchant: _merchantController.text.trim(),
      note: _noteController.text.trim(), // Added the note field
      date: _selectedDate,
    );

    try {
      // 2. Save to SQLite via your DAO
      // Note: You might need to import your TransactionDao or
      // access it via a provider depending on your setup.
      final dao = TransactionDao();
      await dao.insertTransaction(transaction);
      ref.invalidate(reportProvider);
      // 3. REFRESH THE PROVIDER
      // This is the "magic" step that updates the SummaryCard automatically
      ref.read(transactionProvider.notifier).refresh();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving transaction: $e');
      // Optional: Show a snackbar error here
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final categoriesAsync = ref.watch(categoryProvider);

    // Auto-select first category of matching type once data loads
    categoriesAsync.whenData((cats) {
      final filtered = cats.where((c) => c.type == _type).toList();
      if (filtered.isNotEmpty &&
          !filtered.any((c) => c.id == _selectedCategoryId)) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedCategoryId = filtered.first.id);
        });
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cs.onSurface.withAlpha(1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // title
            Text(
              'Add Transaction',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),

            // type toggle
            TypeToggle(
              value: _type,
              onChanged: (v) {
                setState(() {
                  _type = v;
                  _selectedCategoryId = null; // reset so auto-select re-fires
                });
              },
            ),

            const SizedBox(height: 20),

            InputUI(
              controller: _amountController,
              labelText: 'Amount',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              hintText: '0.00',
              textError: 'Please enter a valid amount',
              regexPattern: r'^\d+\.?\d{0,2}',
              icon: Icons.attach_money,
            ),
            const SizedBox(height: 16),

            // category
            Text('Category', style: textTheme.labelLarge),
            const SizedBox(height: 10),

            categoriesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (e, _) => Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: cs.error),
                  const SizedBox(width: 8),
                  Text(
                    'Failed to load categories',
                    style: TextStyle(color: cs.error, fontSize: 13),
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
                // filter to matching type only
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
            const SizedBox(height: 20),
            // ── Merchant & Note Row ─────────────────────────────────────────────────
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align top if error text appears
              children: [
                Expanded(
                  child: InputUI(
                    controller: _merchantController,
                    labelText: 'Merchant',
                    textError: 'Enter a description',
                    keyboardType: TextInputType.text,
                    regexPattern: r'^.{3,}$', // At least 3 characters
                    icon: Icons.store, // Updated icon for merchant
                  ),
                ),
                const SizedBox(width: 12), // Horizontal gap between inputs
                Expanded(
                  child: InputUI(
                    controller: _noteController,
                    labelText: 'Note',
                    keyboardType: TextInputType.text,
                    regexPattern: r'^.{3,}$', // At least 3 charactersj
                    textError: null, // Note is optional, no error needed
                    icon: Icons.edit_note,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // date
            DateWidget(date: _selectedDate, onTap: _pickDate),
            const SizedBox(height: 24),
            // save button
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
