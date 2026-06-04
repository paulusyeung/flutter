import 'package:admin/data/models/domain/report_payload.dart';
import 'package:admin/data/models/domain/report_schedule_seed.dart';
import 'package:admin/data/models/domain/schedule.dart';
import 'package:admin/data/models/domain/schedule_constants.dart';
import 'package:admin/data/models/value/date.dart';

/// Maps the current reports-screen state ([ReportScheduleSeed]) to a
/// prefilled `email_report` [Schedule] draft, so "Schedule report" lands the
/// user in the normal recurring-email editor pre-populated.
///
/// Faithful port of React `useScheduleReport`
/// (`react/src/pages/reports/common/hooks/useScheduleReport.ts:24-72`):
/// identifier → `report_name`; the report's short-form date preset → the
/// scheduler's long-form `date_range` (React's `DATE_RANGES_ALIASES` only
/// rewrites `last7`/`last30`; everything else — `all`, `this_month`,
/// `last90`, … — passes through); CSV filters + bool flags copied across;
/// visible columns → `report_keys`; `send_email: true`. Pure +
/// unit-tested; `now` is injectable for deterministic `next_run`.
Schedule reportEmailSchedule(
  ReportScheduleSeed seed, {
  DateTime? now,
  String? name,
}) {
  final p = seed.payload;
  final base = Schedule.empty().withTemplate(kScheduleTemplateEmailReport);
  final params = Map<String, dynamic>.from(base.parameters)
    ..addAll(<String, dynamic>{
      'report_name': _scheduleReportName(seed.reportIdentifier),
      'date_range': _scheduleDateRange(p.datePreset),
      'start_date': p.startDate?.toIso() ?? '',
      'end_date': p.endDate?.toIso() ?? '',
      'client_id': p.clientId ?? '',
      'clients': _csv(p.clients),
      'vendors': p.vendors ?? '',
      'projects': p.projects ?? '',
      'categories': p.categories ?? '',
      'status': p.status ?? '',
      'product_key': p.productKey ?? '',
      'template_id': p.templateId ?? '',
      'group_by': seed.groupBy ?? '',
      'report_keys': seed.reportKeys,
      'is_income_billed': p.isIncomeBilled,
      'is_expense_billed': p.isExpenseBilled,
      'include_tax': p.includeTax,
      'include_deleted': p.includeDeleted,
      'document_email_attachment': p.documentEmailAttachment,
      'pdf_email_attachment': p.pdfEmailAttachment,
      'send_email': true,
    });
  final runAt = now == null ? Date.today() : Date(now.year, now.month, now.day);
  return base.copyWith(
    name: (name == null || name.isEmpty) ? seed.reportIdentifier : name,
    nextRun: runAt,
    parameters: params,
  );
}

/// Normalize a report-registry identifier to a server-valid email_report
/// `report_name`. The report registry exposes identifiers (`contact`,
/// `task`, `vendor`, `purchase_order`, …) that don't all line up with the
/// scheduler's exporter set: `contact`/`task` need the server's
/// `client_contact`/`tasks`, and reports with no scheduler exporter
/// (vendor, purchase_order[_item]) would be force-deleted on first run. Map
/// the aliases and fall back to `activity` for anything unschedulable so a
/// seeded schedule never silently self-destructs.
String _scheduleReportName(String reportIdentifier) {
  const aliases = <String, String>{
    'contact': 'client_contact',
    'task': 'tasks',
  };
  final mapped = aliases[reportIdentifier] ?? reportIdentifier;
  return kEmailReportReportNames.contains(mapped) ? mapped : 'activity';
}

/// Scheduler `date_range` vocabulary is long-form; the report payload uses
/// short-form. React rewrites only `last7`/`last30`; all other presets are
/// accepted verbatim by the scheduler.
String _scheduleDateRange(ReportDatePreset preset) {
  switch (preset) {
    case ReportDatePreset.last7:
      return 'last7_days';
    case ReportDatePreset.last30:
      return 'last30_days';
    default:
      return preset.wire;
  }
}

/// `clients` is a `List<String>` on the wire (per
/// `EmailReportParametersAccess.reportClients`); the report payload carries
/// it as a CSV string. Empty → `[]` (matching the template default).
List<String> _csv(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const <String>[];
  return raw
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}
