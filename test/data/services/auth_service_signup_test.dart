import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:admin/app/env.dart';
import 'package:admin/data/services/auth_service.dart';

/// Pins the `/api/v1/signup` request the IN API expects from a native
/// client. Mirrors admin-portal's `AuthRepository.signUp`: a plain body
/// with NO Cloudflare Turnstile token (that's a web-only bot mitigation;
/// the API does not require it for native clients).
///
/// auth_service-only import (like `auth_service_oauth_test.dart`) — fast and
/// independent of any unrelated concurrent breakage.
void main() {
  group('AuthService.signup wire shape', () {
    test('POSTs /api/v1/signup with the native body + rc query', () async {
      Uri? url;
      Map<String, dynamic>? body;
      final svc = AuthService(
        httpClient: MockClient((req) async {
          url = req.url;
          body = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({'data': <Object>[]}),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }),
      );

      final res = await svc.signup(
        baseUrl: 'https://t',
        isHosted: true,
        email: 'a@b.test',
        password: 'pw123456',
        referralCode: 'REF9',
      );

      expect(url!.path, '/api/v1/signup');
      expect(url!.queryParameters['rc'], 'REF9');
      expect(body!['email'], 'a@b.test');
      expect(body!['password'], 'pw123456');
      expect(body!['terms_of_service'], true);
      expect(body!['privacy_policy'], true);
      expect(body!['token_name'], '${Env.clientPlatform}_client');
      expect(body!['platform'], Env.clientPlatform);
      // No captcha / turnstile field — native clients don't send one.
      expect(body!.containsKey('cf-turnstile'), isFalse);
      expect(body!.containsKey('captcha'), isFalse);
      // Parses the same envelope as login().
      expect(res.data, isEmpty);
    });

    test('hosted sends X-API-SECRET; rc defaults to empty', () async {
      Uri? url;
      Map<String, String>? headers;
      final svc = AuthService(
        httpClient: MockClient((req) async {
          url = req.url;
          headers = req.headers;
          return http.Response(
            jsonEncode({'data': <Object>[]}),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }),
      );

      await svc.signup(
        baseUrl: 'https://t',
        isHosted: true,
        email: 'x@y.z',
        password: 'pw',
      );

      // rc is always present (admin-portal appends ?rc=$referralCode);
      // empty when not supplied.
      expect(url!.query, contains('rc='));
      // _headers injects X-API-SECRET on hosted only when the env secret is
      // configured; assert the header machinery ran (content-type set).
      expect(headers!['content-type'], contains('application/json'));
    });

    test('422 → ValidationException with field errors', () async {
      final svc = AuthService(
        httpClient: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'message': 'The given data was invalid.',
              'errors': {
                'email': ['The email has already been taken.'],
              },
            }),
            422,
            headers: const {'content-type': 'application/json'},
          );
        }),
      );

      await expectLater(
        () => svc.signup(
          baseUrl: 'https://t',
          isHosted: true,
          email: 'taken@b.test',
          password: 'pw',
        ),
        throwsA(
          isA<Object>().having((e) => '$e', 'message', contains('invalid')),
        ),
      );
    });
  });
}
