/// How a [RecurringPayment] recurs. Stored on the row as this enum's
/// [name] (see `RecurringPayments.frequency` in tables.dart) -- every row
/// created before this existed has no stored value and defaults to
/// [monthly], the only kind that existed then.
enum RecurringPaymentFrequency {
  /// Bills on a fixed day of every calendar month (`dayOfMonth`).
  monthly,

  /// Bills every `intervalDays` days, counted from `intervalAnchorDate` --
  /// for bills that don't line up with the calendar (e.g. "every 10
  /// days").
  interval,

  /// Bills once a year, on `yearlyMonth`/`yearlyDay`.
  yearly;

  static RecurringPaymentFrequency fromStored(String value) {
    return RecurringPaymentFrequency.values.byName(value);
  }

  String get stored => name;

  String get label => switch (this) {
    RecurringPaymentFrequency.monthly => 'Monthly',
    RecurringPaymentFrequency.interval => 'Every few days',
    RecurringPaymentFrequency.yearly => 'Yearly',
  };
}
