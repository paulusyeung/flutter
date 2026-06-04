import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/schedule_constants.dart';
import 'package:admin/domain/reports/report_filter_options.dart';

void main() {
  test('every email_report that shows a status field has report-aware status '
      'options (else it silently falls back to a free-text box)', () {
    final reportsWithStatus = kEmailReportFieldsByReport.entries
        .where((e) => e.value.contains(EmailReportField.status))
        .map((e) => e.key);
    // Guard against an empty filter masking a regression.
    expect(reportsWithStatus, isNotEmpty);
    for (final report in reportsWithStatus) {
      expect(
        reportStatusOptions(report),
        isNotNull,
        reason:
            'report "$report" declares a status field but reportStatusOptions '
            'returns null → the schedule editor shows free text, not chips',
      );
    }
  });

  test('scheduler "tasks" shares the reports-screen "task" status options', () {
    expect(reportStatusOptions('tasks'), isNotNull);
    expect(reportStatusOptions('tasks'), reportStatusOptions('task'));
  });
}
