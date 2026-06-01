import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/api_credentials.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:admin/data/services/users_api.dart';

// Imports only `users_api` (→ api_client) — no view-model graph, so it
// runs independent of unrelated concurrent breakage.

ValueListenable<ApiCredentials?> _creds() => ValueNotifier<ApiCredentials?>(
  const ApiCredentials(baseUrl: 'https://t', token: 't'),
);

void main() {
  group('UsersApi.connectOauth wire shape', () {
    test(
      'POSTs /api/v1/connected_account?provider=&include with token body',
      () async {
        Uri? url;
        String? method;
        Map<String, dynamic>? body;
        final fake = MockClient((req) async {
          url = req.url;
          method = req.method;
          body = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'data': {'id': 'u1'},
            }),
            200,
            headers: const {'content-type': 'application/json'},
          );
        });
        final api = UsersApi(
          ApiClient(
            credentials: _creds(),
            passwordCache: PasswordCache(),
            onUnauthorized: () async {},
            httpClient: fake,
          ),
        );

        final res = await api.connectOauth(
          provider: 'google',
          accessToken: 'ya29.tok',
          idempotencyKey: 'idem-1',
        );

        expect(method, 'POST');
        expect(url!.path, '/api/v1/connected_account');
        expect(url!.queryParameters['provider'], 'google');
        expect(url!.queryParameters['include'], 'company_user');
        expect(body, {'access_token': 'ya29.tok'});
        // Same envelope shape as the disconnect actions → applies cleanly.
        expect(res.id, 'u1');
      },
    );

    test('surfaces server errors (non-2xx) to the caller', () async {
      final api = UsersApi(
        ApiClient(
          credentials: _creds(),
          passwordCache: PasswordCache(),
          onUnauthorized: () async {},
          httpClient: MockClient(
            (_) async => http.Response(
              jsonEncode({'message': 'Invalid token'}),
              422,
              headers: const {'content-type': 'application/json'},
            ),
          ),
        ),
      );

      await expectLater(
        () => api.connectOauth(
          provider: 'google',
          accessToken: 'bad',
          idempotencyKey: 'k',
        ),
        throwsA(isA<Object>()),
      );
    });
  });
}
