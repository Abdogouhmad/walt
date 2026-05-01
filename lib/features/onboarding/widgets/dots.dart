import 'package:flutter/material.dart';
import 'package:walt/core/constants/app_colors.dart';

class Dots extends StatelessWidget {
  final int current, total;

  const Dots({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        total,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: current == i ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: current == i ? context.primary : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
