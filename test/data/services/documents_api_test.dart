import 'dart:convert';

import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/api_credentials.dart';
import 'package:admin/data/services/documents_api.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ApiClient _client(MockClient httpClient) => ApiClient(
  credentials: ValueNotifier<ApiCredentials?>(
    const ApiCredentials(baseUrl: 'https://test', token: 't'),
  ),
  passwordCache: PasswordCache(),
  onUnauthorized: () async {},
  httpClient: httpClient,
);

http.Response _ok() => http.Response(
  jsonEncode({'data': <dynamic>[]}),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  group('DocumentsApi.bulkDownload', () {
    test('POSTs /api/v1/documents/bulk with action:download + the ids '
        '(server-side zip+email export)', () async {
      http.BaseRequest? captured;
      final fake = MockClient((req) async {
        captured = req;
        return _ok();
      });

      await DocumentsApi(
        _client(fake),
      ).bulkDownload(ids: const ['d1', 'd2'], idempotencyKey: 'idem-1');

      expect(captured!.method, 'POST');
      expect(captured!.url.path, '/api/v1/documents/bulk');
      final body =
          jsonDecode((captured! as http.Request).body) as Map<String, dynamic>;
      expect(body['action'], 'download');
      expect(body['ids'], ['d1', 'd2']);
      // Idempotency key rides the standard header (retry-safe).
      expect(captured!.headers['Idempotency-Key'], 'idem-1');
    });
  });
}
