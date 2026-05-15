import 'package:admin/data/models/domain/report_payload.dart';

/// Typed seed handed to the schedules screen via `context.go(..., extra:)`
/// when the user picks "Schedule recurring email…" from the Reports export
/// menu. Stays a typed object (not a URL query string) so payloads like
/// `report_keys: List<String>` survive without encoding pain.
///
/// Phase 5 ships the menu item behind a flag — the schedules screen is
/// currently a stub. When that screen lands, it reads this seed from
/// `GoRouterState.extra` and pre-fills the recurring-email form.
class ReportScheduleSeed {
  const ReportScheduleSeed({
    required this.reportIdentifier,
    required this.payload,
    required this.reportKeys,
    this.groupBy,
  });

  final String reportIdentifier;
  final ReportPayload payload;
  final List<String> reportKeys;
  final String? groupBy;
}
