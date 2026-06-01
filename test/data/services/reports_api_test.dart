import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/api_credentials.dart';
import 'package:admin/data/services/api_exception.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:admin/data/services/reports_api.dart';

ValueListenable<ApiCredentials?> _creds() => ValueNotifier<ApiCredentials?>(
  const ApiCredentials(baseUrl: 'https://test', token: 't'),
);

/// Drives `_pollPreview` against a stubbed HTTP layer so we can assert the
/// narrowed `on ServerException` catch:
///   - retries on 404 / 425 (job-in-flight)
///   - propagates other ApiExceptions (validation, unauthorized, plan-required)
///   - bubbles to `ReportPollingTimeout` only when the retry budget runs out
void main() {
  group('ReportsApi.runPreview polling contract', () {
    test('initial POST returns hash, then 404 → 404 → 200 succeeds', () async {
      final paths = <String>[];
      var pollCount = 0;
      final fake = MockClient((req) async {
        paths.add(req.url.path);
        if (req.url.path == '/api/v1/reports/clients') {
          // First call: the "?output=json" POST returns the hash.
          return http.Response(
            jsonEncode({'message': 'hash-abc'}),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }
        if (req.url.path == '/api/v1/reports/preview/hash-abc') {
          pollCount++;
          if (pollCount <= 2) {
            // Still queued — 404 should be silently retried.
            return http.Response('{}', 404);
          }
          return http.Response(
            jsonEncode({'columns': <Object>[], '0': <Object>[]}),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }
        return http.Response('unexpected', 500);
      });
      final client = ApiClient(
        credentials: _creds(),
        passwordCache: PasswordCache(),
        onUnauthorized: () async {},
        httpClient: fake,
      );
      final api = ReportsApi(client);

      final result = await api.runPreview(
        endpoint: '/api/v1/reports/clients',
        payload: const {},
        pollInterval: const Duration(milliseconds: 1),
      );

      expect(result['columns'], isEmpty);
      expect(pollCount, 3, reason: '2 retries then success');
    });

    test('ValidationException during polling propagates immediately', () async {
      var pollCount = 0;
      final fake = MockClient((req) async {
        if (req.url.path == '/api/v1/reports/clients') {
          return http.Response(
            jsonEncode({'message': 'hash-validate'}),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }
        pollCount++;
        // The PHP server emits a 422 with the standard `errors` envelope.
        return http.Response(
          jsonEncode({
            'message': 'The given data was invalid.',
            'errors': {
              'start_date': ['The start date must be a valid date.'],
            },
          }),
          422,
          headers: const {'content-type': 'application/json'},
        );
      });
      final client = ApiClient(
        credentials: _creds(),
        passwordCache: PasswordCache(),
        onUnauthorized: () async {},
        httpClient: fake,
      );
      final api = ReportsApi(client);

      expect(
        () => api.runPreview(
          endpoint: '/api/v1/reports/clients',
          payload: const {},
          pollInterval: const Duration(milliseconds: 1),
        ),
        throwsA(isA<ValidationException>()),
      );
      // One poll attempt is enough — 422 must NOT spin the retry loop.
      // (Awaiting throwsA above already resolved; pollCount is now 1.)
      // We re-check via a short delay to confirm no further polls.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(pollCount, lessThanOrEqualTo(1));
    });

    test(
      '500 ServerException during polling propagates (not retried)',
      () async {
        var pollCount = 0;
        final fake = MockClient((req) async {
          if (req.url.path == '/api/v1/reports/clients') {
            return http.Response(
              jsonEncode({'message': 'hash-500'}),
              200,
              headers: const {'content-type': 'application/json'},
            );
          }
          pollCount++;
          return http.Response('boom', 500);
        });
        final client = ApiClient(
          credentials: _creds(),
          passwordCache: PasswordCache(),
          onUnauthorized: () async {},
          httpClient: fake,
        );
        final api = ReportsApi(client);

        expect(
          () => api.runPreview(
            endpoint: '/api/v1/reports/clients',
            payload: const {},
            pollInterval: const Duration(milliseconds: 1),
          ),
          throwsA(isA<ServerException>()),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        // 500 is a non-retriable ServerException — the polling loop must
        // surface it, not spin.
        expect(pollCount, lessThanOrEqualTo(1));
      },
    );
  });

  group('ReportsApi.runExport polling contract', () {
    ApiClient clientWith(MockClient fake) => ApiClient(
      credentials: _creds(),
      passwordCache: PasswordCache(),
      onUnauthorized: () async {},
      httpClient: fake,
    );

    test('2xx JSON status → retry, then binary → result', () async {
      var pollCount = 0;
      final fake = MockClient((req) async {
        if (req.url.path == '/api/v1/reports/clients') {
          return http.Response(
            jsonEncode({'message': 'hx'}),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }
        if (req.url.path == '/api/v1/exports/preview/hx') {
          pollCount++;
          if (pollCount <= 2) {
            // Still processing: 2xx + JSON status envelope, NOT an error.
            return http.Response(
              jsonEncode({'message': 'processing'}),
              200,
              headers: const {'content-type': 'application/json'},
            );
          }
          return http.Response.bytes(
            [1, 2, 3, 4],
            200,
            headers: const {'content-type': 'application/pdf'},
          );
        }
        return http.Response('x', 500);
      });
      final api = ReportsApi(clientWith(fake));

      final res = await api.runExport(
        endpoint: '/api/v1/reports/clients',
        payload: const {},
        format: ReportExportFormat.pdf,
        pollInterval: const Duration(milliseconds: 1),
      );

      expect(res.bytes, [1, 2, 3, 4]);
      expect(res.hash, 'hx');
      expect(pollCount, 3, reason: '2 pending then binary');
    });

    test('404 (job queued) is retried', () async {
      var pollCount = 0;
      final fake = MockClient((req) async {
        if (req.url.path == '/api/v1/reports/clients') {
          return http.Response(
            jsonEncode({'message': 'h404'}),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }
        pollCount++;
        if (pollCount <= 2) return http.Response('{}', 404);
        return http.Response.bytes(
          [9],
          200,
          headers: const {'content-type': 'text/csv'},
        );
      });
      final api = ReportsApi(clientWith(fake));

      final res = await api.runExport(
        endpoint: '/api/v1/reports/clients',
        payload: const {},
        format: ReportExportFormat.csv,
        pollInterval: const Duration(milliseconds: 1),
      );
      expect(res.bytes, [9]);
      expect(pollCount, 3);
    });

    test('500 bubbles immediately (no budget burn)', () async {
      var pollCount = 0;
      final fake = MockClient((req) async {
        if (req.url.path == '/api/v1/reports/clients') {
          return http.Response(
            jsonEncode({'message': 'h500'}),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }
        pollCount++;
        return http.Response('boom', 500);
      });
      final api = ReportsApi(clientWith(fake));

      await expectLater(
        api.runExport(
          endpoint: '/api/v1/reports/clients',
          payload: const {},
          format: ReportExportFormat.pdf,
          pollInterval: const Duration(milliseconds: 1),
        ),
        throwsA(isA<ServerException>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(pollCount, lessThanOrEqualTo(1));
    });

    test('cancellation mid-poll throws ReportPollingCancelled', () async {
      var cancelled = false;
      final fake = MockClient((req) async {
        if (req.url.path == '/api/v1/reports/clients') {
          return http.Response(
            jsonEncode({'message': 'hc'}),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'message': 'processing'}),
          200,
          headers: const {'content-type': 'application/json'},
        );
      });
      final api = ReportsApi(clientWith(fake));

      final f = api.runExport(
        endpoint: '/api/v1/reports/clients',
        payload: const {},
        format: ReportExportFormat.pdf,
        pollInterval: const Duration(milliseconds: 5),
        isCancelled: () => cancelled,
      );
      cancelled = true;
      await expectLater(f, throwsA(isA<ReportPollingCancelled>()));
    });

    test('exhausting the budget throws ReportPollingTimeout', () async {
      final fake = MockClient((req) async {
        if (req.url.path == '/api/v1/reports/clients') {
          return http.Response(
            jsonEncode({'message': 'ht'}),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'message': 'processing'}),
          200,
          headers: const {'content-type': 'application/json'},
        );
      });
      final api = ReportsApi(clientWith(fake));

      await expectLater(
        api.runExport(
          endpoint: '/api/v1/reports/clients',
          payload: const {},
          format: ReportExportFormat.pdf,
          maxRetries: 2,
          pollInterval: const Duration(milliseconds: 1),
        ),
        throwsA(isA<ReportPollingTimeout>()),
      );
    });
  });
}
