import 'package:flutter/material.dart';
import 'package:walt_ui/walt_ui.dart';

/// The red panel revealed behind a budget row while it is swiped away.
class BudgetDeleteBackground extends StatelessWidget {
  const BudgetDeleteBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.error,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.lg),
      child: Icon(Icons.delete_outline_rounded, color: scheme.onError),
    );
  }
}
