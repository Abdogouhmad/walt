import 'package:flutter/material.dart';
import 'package:walt_ui/walt_ui.dart';

/// Title block of the budget form: the headline, a one-line subtitle and — in
/// edit mode — the delete button that removes the budget being edited.
class BudgetFormHeader extends StatelessWidget {
  const BudgetFormHeader({
    super.key,
    required this.isEditing,
    required this.onDelete,
  });

  final bool isEditing;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UiText(
                text: isEditing ? 'Edit Budget' : 'New Budget',
                type: UiTextType.titleLarge,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              UiText(
                text: isEditing
                    ? 'Adjust your spending limits'
                    : 'Set bounds to save smarter',
                type: UiTextType.bodySmall,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (isEditing)
          IconButton.filledTonal(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            color: Theme.of(context).colorScheme.error,
          ),
      ],
    );
  }
}
