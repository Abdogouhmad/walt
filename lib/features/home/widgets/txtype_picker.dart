import 'package:flutter/material.dart';
import 'package:walt/core/utils/context.dart';

class TypeToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const TypeToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(context.r(12)),
      ),
      padding: EdgeInsets.all(context.w(4)),
      child: Row(
        children: [
          _tab(context, 'expense', 'Expense', Icons.arrow_upward, cs.error),
          _tab(context, 'income', 'Income', Icons.arrow_downward, Colors.green),
        ],
      ),
    );
  }

  Widget _tab(
    BuildContext context,
    String type,
    String label,
    IconData icon,
    Color activeColor,
  ) {
    final isActive = value == type;
    final cs = Theme.of(context).colorScheme;

    final textColor = isActive
        ? activeColor
        : cs.onSurfaceVariant; // ← Best choice for inactive

    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: context.h(10)),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withAlpha(40) : Colors.transparent,
            borderRadius: BorderRadius.circular(context.r(9)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: context.w(18),
                color: textColor,
              ),
              SizedBox(width: context.w(6)),
              Text(
                label,
                style: TextStyle(
                  fontSize: context.sp(14),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
