import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:walt/features/home/widgets/txtype_picker.dart';
import 'package:walt_ui/walt_ui.dart';

/// The top of the add-transaction sheet: the expense/income toggle and the
/// amount field.
class AddTransactionAmountSection extends StatelessWidget {
  final String type;
  final ValueChanged<String> onTypeChanged;
  final String currency;
  final TextEditingController amountController;
  final FocusNode amountFocus;
  final void Function(String value) onAmountSubmitted;

  const AddTransactionAmountSection({
    super.key,
    required this.type,
    required this.onTypeChanged,
    required this.currency,
    required this.amountController,
    required this.amountFocus,
    required this.onAmountSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TypeToggle(value: type, onChanged: onTypeChanged),
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
          controller: amountController,
          focusNode: amountFocus,
          autofocus: true,
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
          onFieldSubmitted: onAmountSubmitted,
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
      ],
    );
  }
}
