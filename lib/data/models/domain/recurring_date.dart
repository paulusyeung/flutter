import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/recurring_expense_api_model.dart';
import 'package:admin/data/models/value/date.dart';

part 'recurring_date.freezed.dart';

/// One previewed send date for a recurring entity. Populated only when the
/// server responds with `?show_dates=true`; treat as ephemeral — the
/// `RecurringExpenseRepository` does **not** persist this to Drift.
@freezed
abstract class RecurringDate with _$RecurringDate {
  const factory RecurringDate({required Date? sendDate}) = _RecurringDate;

  factory RecurringDate.fromApi(RecurringDateApi a) =>
      RecurringDate(sendDate: Date.tryParse(a.sendDate));
}
