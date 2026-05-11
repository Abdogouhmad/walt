import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputUI extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final TextInputType? keyboardType;
  final String? textError;
  final String? hintText;
  final String? regexPattern;
  final IconData? icon;
  final Function(String)? onchange;

  const InputUI({
    super.key,
    required this.controller,
    required this.labelText,
    this.keyboardType,
    this.textError,
    this.hintText,
    this.regexPattern,
    this.icon,
    this.onchange,
  });

  @override
  Widget build(BuildContext context) {
    // Define isNumeric inside build so it's accessible everywhere
    final isNumeric =
        keyboardType == TextInputType.number ||
        keyboardType == const TextInputType.numberWithOptions(decimal: true);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: isNumeric
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        hintText: hintText,
        labelText: labelText,
        prefixIcon: icon != null ? Icon(icon) : const Icon(Icons.attach_money),
      ),
      onChanged: onchange,
      validator: (value) {
        // 1. Basic empty check
        if (value == null || value.trim().isEmpty) {
          return textError ?? 'Field required';
        }

        // 2. Numeric validation
        if (isNumeric) {
          final n = double.tryParse(value);
          if (n == null || n <= 0) {
            return textError ?? 'Enter a valid number';
          }
        }
        // 3. Regex/Text validation
        else if (regexPattern != null) {
          if (!RegExp(regexPattern!).hasMatch(value)) {
            return textError ?? 'Invalid input format';
          }
        }

        return null;
      },
    );
  }
}
