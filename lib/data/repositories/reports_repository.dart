import 'package:logging/logging.dart';

import 'package:admin/data/models/api/report_preview_api_model.dart';
import 'package:admin/data/models/domain/report_payload.dart';
import 'package:admin/data/models/domain/report_preview.dart';
import 'package:admin/data/services/api_exception.dart';
import 'package:admin/data/services/reports_api.dart';

final _log = Logger('ReportsRepository');

/// Why a Run failed. Mapped from API exceptions in
/// [ReportsRepository.runPreview] so the VM can surface the right UI:
/// inline field errors on 422, password sheet on 412, plan-upgrade CTA on
/// 403-plan, "Keep waiting?" on timeout, etc.
enum ReportErrorKind {
  validation,
  unauthorized,
  passwordRequired,
  planRequired,
  timeout,
  cancelled,
  network,
  serverError,
  unknown,
}

class ReportError implements Exception {
  const ReportError({
    required this.kind,
    this.fieldErrors,
    this.message,
    this.pollingHash,
  });

  final ReportErrorKind kind;

  /// 422 field errors `{fieldName: [msg, ...]}`. Routes to inline filter
  /// field errors in the Filters popover.
  final Map<String, List<String>>? fieldErrors;

  final String? message;

  /// Set on `timeout` errors so the UI's "Keep waiting?" affordance can
  /// re-poll the same hash without re-POSTing a duplicate job.
  final String? pollingHash;

  @override
  String toString() =>
      'ReportError(${kind.name}${message == null ? "" : ": $message"})';
}

/// Glue around [ReportsApi]: builds the wire payload from the typed
/// [ReportPayload], parses the preview response into a [ReportPreview], and
/// maps every error path to a single [ReportError] taxonomy.
class ReportsRepository {
  ReportsRepository({required this.api});

  final ReportsApi api;

  /// Run a preview report. Returns the typed [ReportPreview]; throws a
  /// [ReportError] on any failure.
  ///
  /// - [reportKeys] is the user's visible-column selection, sent to the
  ///   server so the response only carries those columns. Empty list means
  ///   "use the server's default column set."
  /// - [isCancelled] is checked between polls; set it from the VM's
  ///   `_runEpoch` token so a cancelled run stops cleanly.
  Future<ReportPreview> runPreview({
    required String reportIdentifier,
    required String endpoint,
    required ReportPayload payload,
    List<String> reportKeys = const [],
    int maxRetries = ReportsApi.defaultPreviewRetries,
    Duration pollInterval = ReportsApi.defaultPollInterval,
    ReportPollingCancellation? isCancelled,
  }) async {
    final wire = payload.toJson(
      reportIdentifier: reportIdentifier,
      reportKeys: reportKeys,
    );
    try {
      final raw = await api.runPreview(
        endpoint: endpoint,
        payload: wire,
        maxRetries: maxRetries,
        pollInterval: pollInterval,
        isCancelled: isCancelled,
      );
      return decodeReportPreview(raw);
    } on ReportError {
      rethrow;
    } on Object catch (e, st) {
      throw _mapError(e, st);
    }
  }

  /// Continue polling an in-flight preview hash for another budget. Used
  /// by the "Keep waiting?" UX so we don't re-POST a duplicate job.
  Future<ReportPreview> continuePreview({
    required String hash,
    int maxRetries = ReportsApi.defaultPreviewRetries,
    Duration pollInterval = ReportsApi.defaultPollInterval,
    ReportPollingCancellation? isCancelled,
  }) async {
    try {
      final raw = await api.continuePreview(
        hash: hash,
        maxRetries: maxRetries,
        pollInterval: pollInterval,
        isCancelled: isCancelled,
      );
      return decodeReportPreview(raw);
    } on ReportError {
      rethrow;
    } on Object catch (e, st) {
      throw _mapError(e, st);
    }
  }

  /// Email export. Sets `send_email: true` on the wire payload and POSTs
  /// once — no polling. Caller surfaces a "Sent" toast on success.
  Future<void> sendEmail({
    required String reportIdentifier,
    required String endpoint,
    required ReportPayload payload,
    List<String> reportKeys = const [],
    String? groupBy,
  }) async {
    final wire = payload.copyWith(sendEmail: true).toJson(
          reportIdentifier: reportIdentifier,
          reportKeys: reportKeys,
          groupBy: groupBy,
        );
    try {
      await api.sendEmail(endpoint: endpoint, payload: wire);
    } on Object catch (e, st) {
      throw _mapError(e, st);
    }
  }

  /// Translate ApiException / polling errors to the [ReportError] taxonomy.
  /// The 403 → planRequired distinction sniffs the message body for the
  /// legacy "upgrade your plan" copy (admin-portal `constants.dart:978`
  /// — `upgrade_to_view_reports`). Falling back to `unauthorized` when the
  /// message doesn't match keeps us safe — the sidebar is already gated on
  /// `can('view_reports')`, so a real unauthorized landing here would be a
  /// stale permission cache.
  ReportError _mapError(Object e, StackTrace st) {
    if (e is ReportPollingCancelled) {
      return const ReportError(kind: ReportErrorKind.cancelled);
    }
    if (e is ReportPollingTimeout) {
      return ReportError(
        kind: ReportErrorKind.timeout,
        pollingHash: e.hash,
      );
    }
    if (e is ValidationException) {
      return ReportError(
        kind: ReportErrorKind.validation,
        fieldErrors: e.fieldErrors,
        message: e.message,
      );
    }
    if (e is PasswordRequiredException) {
      return ReportError(
        kind: ReportErrorKind.passwordRequired,
        message: e.message,
      );
    }
    if (e is UnauthorizedException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('plan') || msg.contains('upgrade')) {
        return ReportError(
          kind: ReportErrorKind.planRequired,
          message: e.message,
        );
      }
      return ReportError(
        kind: ReportErrorKind.unauthorized,
        message: e.message,
      );
    }
    if (e is ServerException) {
      // 403 with an upgrade message lands here too (only true 401s are
      // typed as UnauthorizedException by the client).
      if (e.statusCode == 403) {
        final msg = e.message.toLowerCase();
        if (msg.contains('plan') || msg.contains('upgrade')) {
          return ReportError(
            kind: ReportErrorKind.planRequired,
            message: e.message,
          );
        }
        return ReportError(
          kind: ReportErrorKind.unauthorized,
          message: e.message,
        );
      }
      return ReportError(
        kind: ReportErrorKind.serverError,
        message: e.message,
      );
    }
    if (e is NetworkException) {
      return ReportError(
        kind: ReportErrorKind.network,
        message: e.message,
      );
    }
    _log.warning('Unmapped report error', e, st);
    return ReportError(kind: ReportErrorKind.unknown, message: '$e');
  }
}
