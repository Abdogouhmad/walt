import 'package:flutter/material.dart';

import 'package:walt/core/theme/walt_colors.dart';

/// Expense/Income segmented control at the top of the add-transaction form
/// (spec §4).
class TypeToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const TypeToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final walt = WaltColors.of(context);

    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment<String>(
            value: 'expense',
            label: const Text('Expense'),
            icon: Icon(Icons.north_east_rounded, color: walt.expense),
          ),
          ButtonSegment<String>(
            value: 'income',
            label: const Text('Income'),
            icon: Icon(Icons.south_west_rounded, color: walt.income),
          ),
        ],
        selected: {value},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}
