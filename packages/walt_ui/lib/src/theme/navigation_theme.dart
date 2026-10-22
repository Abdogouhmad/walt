import 'package:flutter/material.dart';

import '../tokens/radius.dart';

/// The navigation family: the M3 navigation bar, the FAB, menus, list tiles,
/// dividers and the date picker.
///
/// The custom floating pill is the app's real navigation, but the M3 widgets
/// still need a theme: they show up inside sheets and dialogs, and a themed
/// `NavigationBar` keeps them from looking borrowed.
class NavigationTheme {
  const NavigationTheme._();

  /// The M3 navigation bar, kept in step with the floating pill.
  static NavigationBarThemeData bar(ColorScheme colorScheme, TextTheme t) =>
      NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: colorScheme.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        labelTextStyle: WidgetStateTextStyle.resolveWith(
          (states) =>
              t.labelMedium?.copyWith(
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: states.contains(WidgetState.selected)
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
              ) ??
              const TextStyle(),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
      );

  /// The floating action button: rounded square, tinted, flat.
  static FloatingActionButtonThemeData fab(ColorScheme colorScheme) =>
      FloatingActionButtonThemeData(
        elevation: 3,
        hoverElevation: 6,
        highlightElevation: 6,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rXl),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      );

  /// Menus and popups: the same raised, rounded surface.
  static MenuThemeData menu(ColorScheme colorScheme) => MenuThemeData(
    style: MenuStyle(
      backgroundColor: WidgetStatePropertyAll(colorScheme.surfaceContainerHigh),
      elevation: const WidgetStatePropertyAll(3),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: AppRadius.rMd),
      ),
    ),
  );

  /// Pop-up menus: the same raised, rounded surface.
  static PopupMenuThemeData popup(ColorScheme colorScheme) =>
      PopupMenuThemeData(
        color: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
      );

  /// List tiles: rounded, with themed icon and text colours.
  static ListTileThemeData listTile(ColorScheme colorScheme) =>
      ListTileThemeData(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
      );

  /// Dividers: hairline, in the outline role.
  static DividerThemeData divider(ColorScheme colorScheme) => DividerThemeData(
    color: colorScheme.outlineVariant,
    thickness: 1,
    space: 1,
  );

  /// The date picker: a dialog, so the same surface as everything else.
  static DatePickerThemeData datePicker(ColorScheme colorScheme) =>
      DatePickerThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rXl),
      );
}
