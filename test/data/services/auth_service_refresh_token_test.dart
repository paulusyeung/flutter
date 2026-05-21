import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:admin/data/services/api_exception.dart';
import 'package:admin/data/services/auth_service.dart';

/// `AuthService.refreshWithToken` — the demo-build bootstrap call. It POSTs
/// `/api/v1/refresh` authenticated by an explicit `X-API-Token` header (no
/// session exists yet) and returns the standard login envelope. The server
/// echoes the supplied token back in `data[N].token`, which is what lets
/// `AuthRepository._persistAndActivate` persist that token unchanged.
///
/// Imports only `auth_service` (no Drift / view-model graph) so it runs fast
/// and independent of unrelated concurrent breakage.
void main() {
  group('AuthService.refreshWithToken', () {
    test('sends the token header and parses the echoed envelope', () async {
      Uri? url;
      String? tokenHeader;
      final svc = AuthService(
        httpClient: MockClient((req) async {
          url = req.url;
          tokenHeader = req.headers['X-API-Token'];
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'token': {'token': 'TOKEN', 'name': 'test token'},
                  'company': {'id': 'c1'},
                  'account': {'id': 'a1'},
                  'user': {'id': 'u1'},
                },
              ],
            }),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }),
      );

      final res = await svc.refreshWithToken(
        baseUrl: 'https://demo.invoiceninja.com',
        isHosted: false,
        token: 'TOKEN',
      );

      expect(url!.path, '/api/v1/refresh');
      expect(url!.queryParameters['first_load'], 'true');
      expect(url!.queryParameters['include_static'], 'true');
      expect(tokenHeader, 'TOKEN');
      // The server echoes the supplied token back in the envelope.
      expect(res.data.single.token.token, 'TOKEN');
    });

    test('throws UnauthorizedException on 401', () async {
      final svc = AuthService(
        httpClient: MockClient((req) async {
          return http.Response(
            jsonEncode({'message': 'Unauthenticated'}),
            401,
            headers: const {'content-type': 'application/json'},
          );
        }),
      );

      await expectLater(
        svc.refreshWithToken(
          baseUrl: 'https://demo.invoiceninja.com',
          isHosted: false,
          token: 'bad',
        ),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });
}
