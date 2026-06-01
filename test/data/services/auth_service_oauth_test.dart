import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:admin/data/services/auth_service.dart';

/// Pins the `/api/v1/oauth_login` request body the server expects.
///
/// The Google flow rides the access-token path: it sends `access_token`
/// and NO `id_token`. The server's Laravel `request()->has('id_token')`
/// returns true even for an empty string, so an *absent* key is the only
/// way to route through `harvestUser(access_token)` instead of the JWT
/// branch. Mirrors admin-portal's `auth_repository.oauthLogin`.
///
/// Imports only `auth_service` (no Drift / view-model graph) so it runs
/// fast and independent of unrelated concurrent breakage.
void main() {
  Future<Map<String, dynamic>> capture({
    required String provider,
    String? idToken,
    String? accessToken,
    String? authCode,
    String? email,
  }) async {
    Map<String, dynamic>? body;
    Uri? url;
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
    await svc.oauthLogin(
      baseUrl: 'https://t',
      isHosted: true,
      provider: provider,
      idToken: idToken,
      accessToken: accessToken,
      authCode: authCode,
      email: email,
    );
    expect(url!.path, '/api/v1/oauth_login');
    return body!;
  }

  group('AuthService.oauthLogin wire shape', () {
    test('google (access-token path) omits id_token entirely', () async {
      final body = await capture(provider: 'google', accessToken: 'ya29.tok');
      expect(body['provider'], 'google');
      expect(body['access_token'], 'ya29.tok');
      expect(body.containsKey('id_token'), isFalse);
      expect(body.containsKey('auth_code'), isFalse);
      expect(body.containsKey('email'), isFalse);
    });

    test(
      'empty id_token is treated as absent (Laravel has() gotcha)',
      () async {
        final body = await capture(
          provider: 'google',
          accessToken: 'tok',
          idToken: '',
        );
        expect(body.containsKey('id_token'), isFalse);
      },
    );

    test('apple (JWT path) includes id_token + auth_code + email', () async {
      final body = await capture(
        provider: 'apple',
        idToken: 'jwt.header.sig',
        authCode: 'code123',
        email: 'a@b.test',
      );
      expect(body['provider'], 'apple');
      expect(body['id_token'], 'jwt.header.sig');
      expect(body['auth_code'], 'code123');
      expect(body['email'], 'a@b.test');
      expect(body.containsKey('access_token'), isFalse);
    });
  });
}
