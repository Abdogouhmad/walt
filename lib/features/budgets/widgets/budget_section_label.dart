import 'package:flutter/material.dart';
import 'package:walt_ui/walt_ui.dart';

/// Small uppercase section heading used by the budget form.
class BudgetSectionLabel extends StatelessWidget {
  const BudgetSectionLabel(this.text, {super.key});

  final String text;

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
