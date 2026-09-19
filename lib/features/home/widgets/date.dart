import 'package:flutter/material.dart';

import 'package:walt/core/design/radius.dart';
import 'package:walt/core/design/spacing.dart';

/// Tappable field that opens the date picker inside the add-transaction sheet.
class DateWidget extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const DateWidget({required this.date, required this.onTap, super.key});

  String _format(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} / '
      '${d.month.toString().padLeft(2, '0')} / '
      '${d.year}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: AppSpacing.md,
              color: cs.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              _format(date),
              style: TextStyle(fontSize: 15, color: cs.onSurface),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              size: AppSpacing.md,
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}