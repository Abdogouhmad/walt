import 'package:flutter/material.dart';

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
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
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

    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? cs.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? activeColor : cs.onSurface.withOpacity(0.4),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? activeColor : cs.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
