import 'package:admin/data/models/value/date.dart';

/// One row of a recurring invoice's computed schedule: when the next
/// occurrence will be **sent** (`send_date`) and when the generated invoice
/// is **due** (`due_date`).
///
/// Returned only by `GET /api/v1/recurring_invoices/{id}?show_dates=true` —
/// the server computes each due date from the client's payment terms
/// (`due_date_days`), which a pure client-side frequency calc can't reproduce.
/// It is therefore a **read-only, on-demand** value: never stored in Drift,
/// never part of the synced entity payload. Mirrors React's Schedule tab and
/// admin-portal's `invoice_view_schedule`.
class RecurringScheduleDate {
  const RecurringScheduleDate({this.sendDate, this.dueDate});

  final Date? sendDate;
  final Date? dueDate;

  factory RecurringScheduleDate.fromJson(Map<String, dynamic> json) =>
      RecurringScheduleDate(
        sendDate: Date.tryParse((json['send_date'] as String?) ?? ''),
        dueDate: Date.tryParse((json['due_date'] as String?) ?? ''),
      );
}
