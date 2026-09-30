import 'package:flutter/material.dart';

/// The neutral tonal bubble behind a settings row's icon.
///
/// Lives in the shared kit rather than being redeclared per screen: the rows in
/// Settings, Appearance and the About pages have to read as one set, and three
/// copies of the same 40dp circle is how a list starts looking assembled rather
/// than designed.
class SettingsLeading extends StatelessWidget {
  const SettingsLeading({super.key, required this.icon, this.selected = false});

  final IconData icon;

  /// Tints the bubble with `primaryContainer` instead of `secondaryContainer`,
  /// for the row that represents the current selection.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: selected ? scheme.primaryContainer : scheme.secondaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 20,
        color: selected
            ? scheme.onPrimaryContainer
            : scheme.onSecondaryContainer,
      ),
    );
  }
}
