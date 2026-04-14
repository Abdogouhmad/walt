import 'package:flutter/material.dart';
import 'package:walt/core/utils/context.dart';
// colors of appBar
extension AppBarColors on BuildContext {
  ColorScheme get _colorApp => colorAppScheme;
  Color get appBarBackground => _colorApp.primaryContainer.withAlpha(200);
  Color get appBarText => _colorApp.primary;
  Color get appBarIcon => _colorApp.primary;
}
// colors of list within home screen
extension ListColors on BuildContext {
  ColorScheme get _colorApp => colorAppScheme;
  Color get listTitle => _colorApp.primary;
  Color get listContainer => _colorApp.primaryContainer;
  Color get listLabelText => _colorApp.onPrimary;
  Color get listSubLabel => _colorApp.onPrimaryContainer;
  Color get listIconBk => _colorApp.primary;
  Color get listIncome => Colors.lightGreen[300] ?? Colors.green;
  Color get listExpense => Colors.red[400] ?? Colors.red;
  Color get listColorLinks => _colorApp.primary;
}

// colors of summary card within home screen
extension CardColors on BuildContext {
  ColorScheme get _colorApp => colorAppScheme;
  Color get primaryCardBackground => _colorApp.primaryContainer.withAlpha(200);
  Color get secondaryCardBackground =>
      _colorApp.primaryContainer.withAlpha(200);
  Color get cardTextPrimary => _colorApp.primary;
  Color get cardTextSecondary => _colorApp.onPrimaryContainer;
  Color get cardIncome => Colors.lightGreen[500] ?? Colors.green;
  Color get cardExpense => Colors.red[400] ?? Colors.red;
}

// colors of buttons
extension ButtonColors on BuildContext {
  ColorScheme get _colorApp => colorAppScheme;
  Color get primaryButton => _colorApp.primary;
  Color get secondaryButton => _colorApp.primaryContainer;
  Color get primaryTextButton => _colorApp.onPrimary;
  Color get secondaryTextButton => _colorApp.onPrimaryContainer;
}

// colors of buttom sheet within home screen
extension BottomSheetColor on BuildContext {
  ColorScheme get _colorApp => colorAppScheme;
  Color get background => _colorApp.primaryContainer.withAlpha(230);
  Color get textPrimary => _colorApp.primary;
  Color get textSecondary => _colorApp.primaryFixed;
  Color get textonError => _colorApp.error;
}
