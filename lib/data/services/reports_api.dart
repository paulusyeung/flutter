import 'dart:async';
import 'dart:typed_data';

import 'package:admin/data/services/api_client.dart';

/// Format choices for the queued export flow.
enum ReportExportFormat { pdf, csv, xlsx }

extension ReportExportFormatWire on ReportExportFormat {
  String get wire {
    switch (this) {
      case ReportExportFormat.pdf:
        return 'pdf';
      case ReportExportFormat.csv:
        return 'csv';
      case ReportExportFormat.xlsx:
        return 'xlsx';
    }
  }

  String get defaultExtension {
    switch (this) {
      case ReportExportFormat.pdf:
        return 'pdf';
      case ReportExportFormat.csv:
        return 'csv';
      case ReportExportFormat.xlsx:
        return 'xlsx';
    }
  }
}

/// Stop polling cleanly when the caller (VM) has lost interest — e.g. the
/// user clicked Cancel or the screen was disposed. Throw `false` and the
/// polling helpers translate into a [ReportPollingCancelled].
typedef ReportPollingCancellation = bool Function();

class ReportPollingCancelled implements Exception {
  const ReportPollingCancelled();
}

/// Thrown when polling exhausts its retry budget. The repository maps this
/// to `ReportErrorKind.timeout`; the UI surfaces a "Keep waiting?"
/// affordance that re-polls the same hash for another budget.
class ReportPollingTimeout implements Exception {
  const ReportPollingTimeout(this.hash);
  final String hash;
  @override
  String toString() => 'ReportPollingTimeout($hash)';
}

/// Thin HTTP service for the report endpoints. Does not extend
/// `BaseEntityApi` — these are queued-job endpoints, not list/CRUD.
///
/// Every method here is **read-only in effect** even when the wire verb is
/// POST (the server pre-aggregates from existing data). `readOnly: true`
/// keeps demo-mode short-circuits from rejecting them.
///
/// Three flows:
/// - [runPreview]: `POST <endpoint>?output=json` → hash → poll
///   `/api/v1/reports/preview/<hash>` → JSON rows.
/// - [runExport]: `POST <endpoint>` → hash → poll
///   `/api/v1/exports/preview/<hash>` → binary file.
/// - [sendEmail]: `POST <endpoint>` with `send_email: true` → 200 OK; server
///   queues + emails asynchronously. No polling.
///
/// Polling budgets are configurable so the VM can hand off a longer budget
/// when the user clicks "Keep waiting?" on a timeout.
class ReportsApi {
  ReportsApi(this.client);

  final ApiClient client;

  /// Default preview budget: 30 retries × 2 s = 60 s. Wider than React's
  /// 10× because `invoice_item` / `ar_detail` over multi-year ranges
  /// routinely exceeds 20 s.
  static const Duration defaultPollInterval = Duration(seconds: 2);
  static const int defaultPreviewRetries = 30;
  static const int defaultExportRetries = 50;

  /// Preview flow. Returns the decoded JSON rows envelope.
  Future<Map<String, Object?>> runPreview({
    required String endpoint,
    required Map<String, dynamic> payload,
    int maxRetries = defaultPreviewRetries,
    Duration pollInterval = defaultPollInterval,
    ReportPollingCancellation? isCancelled,
  }) async {
    final hash = await _postForHash(
      path: endpoint,
      payload: payload,
      query: const {'output': 'json'},
    );
    return _pollPreview(
      hash: hash,
      maxRetries: maxRetries,
      pollInterval: pollInterval,
      isCancelled: isCancelled,
    );
  }

  /// Continue polling an in-flight preview hash for another budget. Used
  /// when the user clicks "Keep waiting?" on a timeout error — the server
  /// caches the hash, so re-POSTing would just queue a duplicate job.
  Future<Map<String, Object?>> continuePreview({
    required String hash,
    int maxRetries = defaultPreviewRetries,
    Duration pollInterval = defaultPollInterval,
    ReportPollingCancellation? isCancelled,
  }) {
    return _pollPreview(
      hash: hash,
      maxRetries: maxRetries,
      pollInterval: pollInterval,
      isCancelled: isCancelled,
    );
  }

  /// Export flow. Phase 4 will return the binary bytes of the rendered
  /// PDF / CSV / XLSX via a content-type-aware variant of `client.postRaw`
  /// — the current helper does strict content-type matching that doesn't
  /// fit a multi-format export. Stubbed in Phase 1 so the flow is shaped
  /// correctly; calling it throws to make wiring mistakes loud.
  Future<ReportExportResult> runExport({
    required String endpoint,
    required Map<String, dynamic> payload,
    required ReportExportFormat format,
    int maxRetries = defaultExportRetries,
    Duration pollInterval = defaultPollInterval,
    ReportPollingCancellation? isCancelled,
  }) async {
    throw UnimplementedError(
      'Phase 4: queued export flow — needs a content-type-aware variant of '
      'ApiClient.postRaw to handle PDF / CSV / XLSX responses.',
    );
  }

  /// Email flow. POSTs the same payload as [runExport] but with
  /// `send_email: true` on the payload — the server queues + sends async,
  /// the response is a plain 200. No hash to poll.
  ///
  /// Caller is responsible for setting `send_email: true` on the payload
  /// before calling. We don't munge it here so the wire shape stays
  /// transparent.
  Future<void> sendEmail({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    await client.postJson(endpoint, body: payload, readOnly: true);
  }

  Future<String> _postForHash({
    required String path,
    required Map<String, dynamic> payload,
    Map<String, String>? query,
  }) async {
    final raw = await client.postJson(
      path,
      body: payload,
      query: query,
      readOnly: true,
    );
    final hash = _extractHash(raw);
    if (hash == null || hash.isEmpty) {
      throw const FormatException(
        'Report endpoint did not return a polling hash',
      );
    }
    return hash;
  }

  static String? _extractHash(Object? raw) {
    if (raw is Map) {
      final msg = raw['message'];
      if (msg is String) return msg;
      // Some endpoints wrap into {data: {hash}} — defensive fallback.
      final data = raw['data'];
      if (data is Map && data['hash'] is String) return data['hash'] as String;
    }
    return null;
  }

  Future<Map<String, Object?>> _pollPreview({
    required String hash,
    required int maxRetries,
    required Duration pollInterval,
    required ReportPollingCancellation? isCancelled,
  }) async {
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      if (isCancelled?.call() == true) {
        throw const ReportPollingCancelled();
      }
      try {
        final raw = await client.postJson(
          '/api/v1/reports/preview/$hash',
          readOnly: true,
        );
        if (raw is Map<String, Object?>) {
          return raw;
        }
        if (raw is Map) {
          return raw.map((k, v) => MapEntry(k.toString(), v));
        }
        // Defensive — server should always emit an object once ready.
      } catch (_) {
        // 404 while the queued job is still running is normal — fall
        // through to the backoff sleep. Other ApiExceptions propagate.
        rethrow;
      }
      await Future<void>.delayed(pollInterval);
    }
    throw ReportPollingTimeout(hash);
  }

}

class ReportExportResult {
  const ReportExportResult({required this.bytes, required this.hash});
  final Uint8List bytes;
  final String hash;
}
