import 'dart:async';
import 'dart:convert';

import 'package:admin/app/version.dart';
import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/api_credentials.dart';
import 'package:admin/data/services/api_exception.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Helpers — these tests target ApiClient's behavioral contract, not http or
/// Drift. Each test exercises an invariant that other layers (sync engine,
/// UI, repositories) rely on.

ValueListenable<ApiCredentials?> _creds([ApiCredentials? c]) =>
    ValueNotifier<ApiCredentials?>(
      c ?? const ApiCredentials(baseUrl: 'https://test', token: 't'),
    );

void main() {
  group('ApiClient 401 handling', () {
    test(
      'single-flight: parallel 401s call onUnauthorized exactly once',
      () async {
        var unauthorizedCalls = 0;
        final fake = MockClient((_) async => http.Response('nope', 401));

        final client = ApiClient(
          credentials: _creds(),
          passwordCache: PasswordCache(),
          onUnauthorized: () async {
            unauthorizedCalls++;
            // Simulate slow logout work (token wipe, navigation, etc.).
            await Future<void>.delayed(const Duration(milliseconds: 50));
          },
          httpClient: fake,
        );

        // Fire 5 parallel calls that will all 401.
        final results = await Future.wait([
          for (var i = 0; i < 5; i++)
            client.getOne('/api/v1/x').catchError((_) => null),
        ]);

        expect(results.length, 5);
        expect(
          unauthorizedCalls,
          1,
          reason: 'parallel 401s must coalesce into a single logout',
        );
      },
    );

    test(
      'logout cache resets so a second session can trigger a fresh logout',
      () async {
        // Regression: `_logoutFuture ??=` used to stick forever, swallowing
        // 401s in later sessions after re-login.
        var unauthorizedCalls = 0;
        final fake = MockClient((_) async => http.Response('nope', 401));
        final client = ApiClient(
          credentials: _creds(),
          passwordCache: PasswordCache(),
          onUnauthorized: () async => unauthorizedCalls++,
          httpClient: fake,
        );

        // Session 1: 401 logs us out.
        await client.getOne('/api/v1/x').catchError((_) => null);
        // Simulate the user re-logging in (a new request after the logout
        // future has resolved). The next 401 must trigger onUnauthorized
        // again — it's a different session.
        await Future<void>.delayed(Duration.zero);
        await client.getOne('/api/v1/x').catchError((_) => null);

        expect(unauthorizedCalls, 2);
      },
    );
  });

  group('ApiClient mutation headers', () {
    test('mutate forwards the caller-supplied Idempotency-Key', () async {
      String? captured;
      final fake = MockClient((req) async {
        captured = req.headers['Idempotency-Key'];
        return http.Response('{}', 200);
      });
      final client = ApiClient(
        credentials: _creds(),
        passwordCache: PasswordCache(),
        onUnauthorized: () async {},
        httpClient: fake,
      );

      await client.mutate(
        method: 'POST',
        path: '/api/v1/clients',
        idempotencyKey: 'idem-abc',
        body: {'name': 'A'},
      );
      expect(captured, 'idem-abc');
    });

    test('hosted creds inject X-API-SECRET; self-hosted does not', () async {
      String? hostedSecret;
      String? selfHostedSecret;
      final fake = MockClient((req) async {
        if (req.url.host == 'hosted') {
          hostedSecret = req.headers['X-API-SECRET'];
        } else {
          selfHostedSecret = req.headers['X-API-SECRET'];
        }
        return http.Response('{}', 200);
      });

      final hosted = ApiClient(
        credentials: _creds(
          const ApiCredentials(
            baseUrl: 'https://hosted',
            token: 't',
            apiSecret: 'shh',
            isHosted: true,
          ),
        ),
        passwordCache: PasswordCache(),
        onUnauthorized: () async {},
        httpClient: fake,
      );
      final selfHosted = ApiClient(
        credentials: _creds(
          const ApiCredentials(baseUrl: 'https://my-ninja', token: 't'),
        ),
        passwordCache: PasswordCache(),
        onUnauthorized: () async {},
        httpClient: fake,
      );

      await hosted.getOne('/api/v1/x');
      await selfHosted.getOne('/api/v1/x');

      expect(hostedSecret, 'shh');
      expect(selfHostedSecret, isNull);
    });

    test(
      'X-API-PASSWORD-BASE64 is added when requiresPassword=true and cache is set',
      () async {
        String? captured;
        final fake = MockClient((req) async {
          captured = req.headers['X-API-PASSWORD-BASE64'];
          return http.Response('{}', 200);
        });
        final cache = PasswordCache()..set('hunter2');
        final client = ApiClient(
          credentials: _creds(),
          passwordCache: cache,
          onUnauthorized: () async {},
          httpClient: fake,
        );

        await client.mutate(
          method: 'DELETE',
          path: '/api/v1/clients/a',
          idempotencyKey: 'k',
          requiresPassword: true,
        );
        expect(captured, base64Encode(utf8.encode('hunter2')));
      },
    );

    test(
      'requiresPassword + empty cache throws PasswordRequired before any HTTP call',
      () async {
        var calls = 0;
        final fake = MockClient((_) async {
          calls++;
          return http.Response('{}', 200);
        });
        final client = ApiClient(
          credentials: _creds(),
          passwordCache: PasswordCache(),
          onUnauthorized: () async {},
          httpClient: fake,
        );

        await expectLater(
          () => client.mutate(
            method: 'DELETE',
            path: '/api/v1/clients/a',
            idempotencyKey: 'k',
            requiresPassword: true,
          ),
          throwsA(isA<PasswordRequiredException>()),
        );
        expect(calls, 0, reason: 'must not hit the network without a password');
      },
    );
  });

  group('ApiClient error mapping', () {
    test('422 surfaces field-level errors for inline form display', () async {
      final fake = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message': 'Validation failed',
            'errors': {
              'email': ['Must be unique'],
              'name': ['Required'],
            },
          }),
          422,
          headers: {'content-type': 'application/json'},
        ),
      );
      final client = ApiClient(
        credentials: _creds(),
        passwordCache: PasswordCache(),
        onUnauthorized: () async {},
        httpClient: fake,
      );

      try {
        await client.mutate(
          method: 'POST',
          path: '/api/v1/clients',
          idempotencyKey: 'k',
          body: {},
        );
        fail('expected ValidationException');
      } on ValidationException catch (e) {
        expect(e.fieldErrors['email'], ['Must be unique']);
        expect(e.fieldErrors['name'], ['Required']);
      }
    });

    test('429 with Retry-After header carries the wait duration', () async {
      final fake = MockClient(
        (_) async => http.Response('{}', 429, headers: {'retry-after': '7'}),
      );
      final client = ApiClient(
        credentials: _creds(),
        passwordCache: PasswordCache(),
        onUnauthorized: () async {},
        httpClient: fake,
      );

      try {
        await client.getOne('/api/v1/x');
        fail('expected RateLimitedException');
      } on RateLimitedException catch (e) {
        expect(e.retryAfter, const Duration(seconds: 7));
      }
    });

    test(
      '409 produces ConflictException so the sync engine can surface it',
      () async {
        final fake = MockClient((_) async => http.Response('{}', 409));
        final client = ApiClient(
          credentials: _creds(),
          passwordCache: PasswordCache(),
          onUnauthorized: () async {},
          httpClient: fake,
        );
        await expectLater(
          () => client.getOne('/api/v1/x'),
          throwsA(isA<ConflictException>()),
        );
      },
    );
  });

  group('ApiClient version negotiation', () {
    test(
      'x-minimum-client-version greater than ours throws ClientTooOldException',
      () async {
        final bumped = _bumpMinor(
          AppVersion.kClientVersion,
          by: 5,
        ); // > current
        final fake = MockClient(
          (_) async => http.Response(
            '{}',
            200,
            headers: {'x-minimum-client-version': bumped},
          ),
        );
        final client = ApiClient(
          credentials: _creds(),
          passwordCache: PasswordCache(),
          onUnauthorized: () async {},
          httpClient: fake,
        );

        await expectLater(
          () => client.getOne('/api/v1/x'),
          throwsA(isA<ClientTooOldException>()),
        );
      },
    );

    test(
      'onClientTooOld is invoked with min+current so the router can redirect',
      () async {
        final bumped = _bumpMinor(AppVersion.kClientVersion, by: 5);
        ({String minRequired, String current})? reported;
        final fake = MockClient(
          (_) async => http.Response(
            '{}',
            200,
            headers: {'x-minimum-client-version': bumped},
          ),
        );
        final client = ApiClient(
          credentials: _creds(),
          passwordCache: PasswordCache(),
          onUnauthorized: () async {},
          onClientTooOld: (info) => reported = info,
          httpClient: fake,
        );

        await client.getOne('/api/v1/x').catchError((_) => null);
        expect(reported, isNotNull);
        expect(reported!.minRequired, bumped);
        expect(reported!.current, AppVersion.kClientVersion);
      },
    );

    test(
      'x-app-version is reported to onServerVersion for the diagnostics screen',
      () async {
        String? reported;
        final fake = MockClient(
          (_) async => http.Response(
            '{"data": {}}',
            200,
            headers: {'x-app-version': '5.12.34'},
          ),
        );
        final client = ApiClient(
          credentials: _creds(),
          passwordCache: PasswordCache(),
          onUnauthorized: () async {},
          onServerVersion: (v) => reported = v,
          httpClient: fake,
        );

        await client.getOne('/api/v1/x');
        expect(reported, '5.12.34');
      },
    );
  });

  group('PasswordCache', () {
    test('expires after the configured TTL', () {
      var now = DateTime(2026, 1, 1, 12);
      final cache = PasswordCache(
        ttl: const Duration(minutes: 5),
        now: () => now,
      )..set('s3cret');
      expect(cache.read(), 's3cret');

      now = now.add(const Duration(minutes: 4));
      expect(cache.read(), 's3cret');

      now = now.add(const Duration(minutes: 2));
      expect(cache.read(), isNull, reason: 'TTL elapsed → cache must drop');
    });
  });

  group('ApiClient list cursor sanitisation', () {
    test(
      'far-future updated_at is dropped instead of poisoning the next page',
      () async {
        // Regression for H3: a malformed/malicious row could put `updated_at`
        // in year 9999, which the next list call would send as the cursor
        // and silently skip every subsequent row server-side.
        final fake = MockClient(
          (_) async => http.Response(
            jsonEncode({
              'data': [
                {'id': 'a', 'updated_at': 99999999999}, // ~year 5138
              ],
            }),
            200,
          ),
        );
        final client = ApiClient(
          credentials: _creds(),
          passwordCache: PasswordCache(),
          onUnauthorized: () async {},
          httpClient: fake,
        );

        final result = await client.getList('/api/v1/clients', page: 1);
        expect(result.cursorUpdatedAt, isNull);
        expect(
          result.cursorId,
          'a',
        ); // id still surfaces so caller can fall back
      },
    );

    test('negative updated_at is dropped', () async {
      final fake = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'data': [
              {'id': 'a', 'updated_at': -1},
            ],
          }),
          200,
        ),
      );
      final client = ApiClient(
        credentials: _creds(),
        passwordCache: PasswordCache(),
        onUnauthorized: () async {},
        httpClient: fake,
      );

      final result = await client.getList('/api/v1/clients', page: 1);
      expect(result.cursorUpdatedAt, isNull);
    });

    test('valid updated_at passes through', () async {
      final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final fake = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'data': [
              {'id': 'a', 'updated_at': ts},
            ],
          }),
          200,
        ),
      );
      final client = ApiClient(
        credentials: _creds(),
        passwordCache: PasswordCache(),
        onUnauthorized: () async {},
        httpClient: fake,
      );

      final result = await client.getList('/api/v1/clients', page: 1);
      expect(result.cursorUpdatedAt, ts);
    });
  });

  group('ApiClient decode timeout', () {
    test(
      'a never-completing decode raises NetworkException via the timeout',
      () async {
        // Regression for H4: a pathological JSON payload (deeply nested,
        // multi-MB) used to be able to hang the worker isolate forever —
        // the calling list view spun with no signal to the user.
        final fake = MockClient(
          (_) async => http.Response('{"data": []}', 200),
        );
        final client = ApiClient(
          credentials: _creds(),
          passwordCache: PasswordCache(),
          onUnauthorized: () async {},
          httpClient: fake,
          decoder: (_) => Completer<dynamic>().future, // never completes
          decodeTimeout: const Duration(milliseconds: 20),
        );

        await expectLater(
          () => client.getOne('/api/v1/x'),
          throwsA(isA<NetworkException>()),
        );
      },
    );
  });
}

/// Bump the minor version by [by] — used to fabricate a server-required
/// version that's strictly greater than our compile-time constant.
String _bumpMinor(String semver, {int by = 1}) {
  final parts = semver.split('-').first.split('.');
  final minor = int.parse(parts[1]) + by;
  return '${parts[0]}.$minor.0';
}
