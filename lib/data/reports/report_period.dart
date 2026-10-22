/// Granularity of the reports screen. Each period defines both the date range
/// that is analysed and the buckets the spending-over-time chart is built from.
enum ReportPeriod { week, month, year }

extension ReportPeriodX on ReportPeriod {
  String get label => switch (this) {
    ReportPeriod.week => 'Week',
    ReportPeriod.month => 'Month',
    ReportPeriod.year => 'Year',
  };
}
