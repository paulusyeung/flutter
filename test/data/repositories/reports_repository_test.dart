import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/report_payload.dart';
import 'package:admin/data/repositories/reports_repository.dart';
import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/api_exception.dart';
import 'package:admin/data/services/reports_api.dart';

/// In-memory fake — replaces the real HTTP+polling stack so the repository
/// contract can be exercised without standing up an HTTP server. Each
/// scenario primes either a typed exception or a Map response, in the
/// order [ReportsRepository] consumes them.
class _FakeApi implements ReportsApi {
  final List<Object> _previewResponses = [];
  final List<Object> _sendEmailResponses = [];

  final List<Map<String, dynamic>> previewPayloads = [];
  final List<String> previewEndpoints = [];
  final List<Map<String, dynamic>> sendEmailPayloads = [];
  final List<String> sendEmailEndpoints = [];

  void queuePreviewSuccess(Map<String, Object?> body) {
    _previewResponses.add(body);
  }

  void queuePreviewError(Object error) {
    _previewResponses.add(error);
  }

  void queueSendEmailSuccess() {
    _sendEmailResponses.add('ok');
  }

  void queueSendEmailError(Object error) {
    _sendEmailResponses.add(error);
  }

  @override
  Future<Map<String, Object?>> runPreview({
    required String endpoint,
    required Map<String, dynamic> payload,
    int maxRetries = ReportsApi.defaultPreviewRetries,
    Duration pollInterval = ReportsApi.defaultPollInterval,
    ReportPollingCancellation? isCancelled,
  }) async {
    previewEndpoints.add(endpoint);
    previewPayloads.add(payload);
    if (_previewResponses.isEmpty) {
      throw StateError('no preview response queued');
    }
    final next = _previewResponses.removeAt(0);
    if (next is Map<String, Object?>) return next;
    throw next;
  }

  @override
  Future<Map<String, Object?>> continuePreview({
    required String hash,
    int maxRetries = ReportsApi.defaultPreviewRetries,
    Duration pollInterval = ReportsApi.defaultPollInterval,
    ReportPollingCancellation? isCancelled,
  }) async {
    if (_previewResponses.isEmpty) {
      throw StateError('no preview response queued');
    }
    final next = _previewResponses.removeAt(0);
    if (next is Map<String, Object?>) return next;
    throw next;
  }

  @override
  Future<ReportExportResult> runExport({
    required String endpoint,
    required Map<String, dynamic> payload,
    required ReportExportFormat format,
    int maxRetries = ReportsApi.defaultExportRetries,
    Duration pollInterval = ReportsApi.defaultPollInterval,
    ReportPollingCancellation? isCancelled,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ReportExportResult> continueExport({
    required String hash,
    required ReportExportFormat format,
    int maxRetries = ReportsApi.defaultExportRetries,
    Duration pollInterval = ReportsApi.defaultPollInterval,
    ReportPollingCancellation? isCancelled,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> sendEmail({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    sendEmailEndpoints.add(endpoint);
    sendEmailPayloads.add(payload);
    if (_sendEmailResponses.isEmpty) {
      throw StateError('no send-email response queued');
    }
    final next = _sendEmailResponses.removeAt(0);
    if (next != 'ok') throw next;
  }

  // Required by `implements ReportsApi`; never read by the repository
  // contract being tested.
  @override
  ApiClient get client => throw UnsupportedError('not used by tests');
}

void main() {
  group('ReportsRepository.runPreview', () {
    test('decodes a happy-path preview envelope', () async {
      final api = _FakeApi()
        ..queuePreviewSuccess({
          'columns': [
            {'identifier': 'client.name', 'display_value': 'Client'},
          ],
          '0': [
            {
              'value': 'ACME',
              'display_value': 'ACME',
              'entity': 'client',
              'id': 'abc',
            },
          ],
        });
      final repo = ReportsRepository(api: api);

      final preview = await repo.runPreview(
        reportIdentifier: 'clients',
        endpoint: '/api/v1/reports/clients',
        payload: const ReportPayload(),
      );

      expect(preview.columns, hasLength(1));
      expect(preview.rows, hasLength(1));
      expect(preview.rows.first.entityWire, 'client');
      expect(preview.rows.first.entityId, 'abc');
      expect(api.previewEndpoints, ['/api/v1/reports/clients']);
    });

    test('product_sales sends literal null client_id', () async {
      final api = _FakeApi()..queuePreviewSuccess({'columns': []});
      final repo = ReportsRepository(api: api);
      await repo.runPreview(
        reportIdentifier: 'product_sales',
        endpoint: '/api/v1/reports/product_sales',
        payload: const ReportPayload(clientId: null),
      );
      final payload = api.previewPayloads.first;
      expect(payload.containsKey('client_id'), isTrue);
      expect(payload['client_id'], isNull);
    });

    test('422 maps to validation with fieldErrors', () async {
      final api = _FakeApi()
        ..queuePreviewError(
          const ValidationException('bad', {
            'start_date': ['must be in the past'],
          }),
        );
      final repo = ReportsRepository(api: api);
      expect(
        () => repo.runPreview(
          reportIdentifier: 'clients',
          endpoint: '/api/v1/reports/clients',
          payload: const ReportPayload(),
        ),
        throwsA(
          isA<ReportError>()
              .having((e) => e.kind, 'kind', ReportErrorKind.validation)
              .having((e) => e.fieldErrors, 'fieldErrors', {
                'start_date': ['must be in the past'],
              }),
        ),
      );
    });

    test('PlanRequiredException maps to ReportErrorKind.planRequired '
        '(primary, authoritative signal)', () async {
      final api = _FakeApi()
        ..queuePreviewError(
          const PlanRequiredException('Upgrade to access reports'),
        );
      final repo = ReportsRepository(api: api);
      expect(
        () => repo.runPreview(
          reportIdentifier: 'profitloss',
          endpoint: '/api/v1/reports/profitloss',
          payload: const ReportPayload(),
        ),
        throwsA(
          isA<ReportError>()
              .having((e) => e.kind, 'kind', ReportErrorKind.planRequired)
              .having((e) => e.message, 'message', 'Upgrade to access reports'),
        ),
      );
    });

    test('UnauthorizedException with upgrade message maps to planRequired '
        '(fallback for legacy servers without the typed signal)', () async {
      final api = _FakeApi()
        ..queuePreviewError(
          const UnauthorizedException(
            'Please upgrade your plan to access reports',
          ),
        );
      final repo = ReportsRepository(api: api);
      expect(
        () => repo.runPreview(
          reportIdentifier: 'profitloss',
          endpoint: '/api/v1/reports/profitloss',
          payload: const ReportPayload(),
        ),
        throwsA(
          isA<ReportError>().having(
            (e) => e.kind,
            'kind',
            ReportErrorKind.planRequired,
          ),
        ),
      );
    });

    test('UnauthorizedException with non-plan message stays unauthorized '
        '(fallback heuristic only fires on plan / upgrade keywords)', () async {
      final api = _FakeApi()
        ..queuePreviewError(
          const UnauthorizedException('Your session has expired'),
        );
      final repo = ReportsRepository(api: api);
      expect(
        () => repo.runPreview(
          reportIdentifier: 'profitloss',
          endpoint: '/api/v1/reports/profitloss',
          payload: const ReportPayload(),
        ),
        throwsA(
          isA<ReportError>().having(
            (e) => e.kind,
            'kind',
            ReportErrorKind.unauthorized,
          ),
        ),
      );
    });

    test('PasswordRequiredException maps to passwordRequired', () async {
      final api = _FakeApi()
        ..queuePreviewError(const PasswordRequiredException());
      final repo = ReportsRepository(api: api);
      expect(
        () => repo.runPreview(
          reportIdentifier: 'clients',
          endpoint: '/api/v1/reports/clients',
          payload: const ReportPayload(),
        ),
        throwsA(
          isA<ReportError>().having(
            (e) => e.kind,
            'kind',
            ReportErrorKind.passwordRequired,
          ),
        ),
      );
    });

    test('polling timeout surfaces ReportError.timeout with hash', () async {
      final api = _FakeApi()
        ..queuePreviewError(const ReportPollingTimeout('hash-123'));
      final repo = ReportsRepository(api: api);
      try {
        await repo.runPreview(
          reportIdentifier: 'clients',
          endpoint: '/api/v1/reports/clients',
          payload: const ReportPayload(),
        );
        fail('expected ReportError');
      } on ReportError catch (e) {
        expect(e.kind, ReportErrorKind.timeout);
        expect(e.pollingHash, 'hash-123');
      }
    });
  });

  group('ReportsRepository.sendEmail', () {
    test('forces send_email:true on the wire payload', () async {
      final api = _FakeApi()..queueSendEmailSuccess();
      final repo = ReportsRepository(api: api);
      await repo.sendEmail(
        reportIdentifier: 'clients',
        endpoint: '/api/v1/reports/clients',
        payload: const ReportPayload(),
      );
      expect(api.sendEmailPayloads.first['send_email'], true);
    });
  });
}
