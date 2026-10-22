import 'package:flutter/material.dart';
import 'package:walt/features/home/widgets/date.dart';
import 'package:walt_ui/walt_ui.dart';

/// The lower half of the add-transaction sheet: merchant, note, the date
/// picker and the save button.
class AddTransactionDetailsSection extends StatelessWidget {
  final TextEditingController merchantController;
  final FocusNode merchantFocus;
  final void Function(String value) onMerchantSubmitted;
  final TextEditingController noteController;
  final FocusNode noteFocus;
  final VoidCallback onSubmit;
  final DateTime selectedDate;
  final VoidCallback onPickDate;
  final bool isSaving;

  const AddTransactionDetailsSection({
    super.key,
    required this.merchantController,
    required this.merchantFocus,
    required this.onMerchantSubmitted,
    required this.noteController,
    required this.noteFocus,
    required this.onSubmit,
    required this.selectedDate,
    required this.onPickDate,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InputUI(
          controller: merchantController,
          focusNode: merchantFocus,
          labelText: 'Merchant',
          textError: 'Enter a description',
          requiredMessage: 'Required',
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: onMerchantSubmitted,
          regexPattern: r'^.{3,}$',
          icon: Icons.store,
        ),
        const SizedBox(height: AppSpacing.md),
        InputUI(
          controller: noteController,
          focusNode: noteFocus,
          labelText: 'Note (optional)',
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => onSubmit(),
          isRequired: false,
          icon: Icons.edit_note,
        ),
        const SizedBox(height: AppSpacing.lg),

        DateWidget(date: selectedDate, onTap: onPickDate),
        const SizedBox(height: AppSpacing.xl),

        AppButton(
          label: 'Save Transaction',
          onPressed: onSubmit,
          isLoading: isSaving,
          isFullWidth: true,
          tooltip: 'Save the transaction',
          type: ButtonType.primary,
          size: ButtonSize.large,
        ),
      ],
    );
  }
}
