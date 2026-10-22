/// Budget maths: the period a budget is measured over, how much of it has been
/// spent, and the summary the budget screen's header shows.
///
/// The pieces live in their own files so a screen can import exactly the one
/// it needs; this barrel re-exports all of them.
library;

export 'budget_calculation.dart';
export 'budget_summary.dart';
export 'budget_window.dart';
