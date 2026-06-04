import 'dart:convert';

import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/api_credentials.dart';
import 'package:admin/data/services/import_api.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Wire-shape coverage for the third-party importers (FreshBooks / Wave / …):
// a direct multipart POST /api/v1/import with `import_type` = the provider and
// one `files[<key>]` per group. Mirrors the migration test harness.

ValueListenable<ApiCredentials?> _creds() => ValueNotifier<ApiCredentials?>(
  const ApiCredentials(baseUrl: 'https://test', token: 't'),
);

String? _multipartField(Uint8List body, String name) {
  final text = utf8.decode(body, allowMalformed: true);
  final start = text.indexOf('name="$name"');
  if (start < 0) return null;
  final bodyStart = text.indexOf('\r\n\r\n', start);
  if (bodyStart < 0) return null;
  final boundary = text.indexOf('\r\n--', bodyStart + 4);
  if (boundary < 0) return null;
  return text.substring(bodyStart + 4, boundary);
}

void main() {
  group('ImportApi.runThirdPartyImport wire shape', () {
    test('posts import_type + a files[<key>] part per group', () async {
      late http.Request captured;
      final client = ApiClient(
        credentials: _creds(),
        passwordCache: PasswordCache(),
        onUnauthorized: () async {},
        httpClient: MockClient((req) async {
          captured = req;
          return http.Response('{"message":"Import started"}', 200);
        }),
      );

      final msg = await ImportApi(client).runThirdPartyImport(
        importType: 'freshbooks',
        files: [
          (
            key: 'client',
            bytes: Uint8List.fromList(utf8.encode('a,b\n1,2')),
            fileName: 'clients.csv',
          ),
          (
            key: 'invoice',
            bytes: Uint8List.fromList(utf8.encode('c,d\n3,4')),
            fileName: 'invoices.csv',
          ),
        ],
      );

      expect(msg, 'Import started');
      expect(captured.method, 'POST');
      expect(captured.url.path, '/api/v1/import');
      expect(captured.headers['Idempotency-Key'], isNotEmpty);
      // import_type is the provider name — the server's bootEngine switches on
      // it; the entity is carried by the files[<key>] part names.
      expect(_multipartField(captured.bodyBytes, 'import_type'), 'freshbooks');
      expect(_multipartField(captured.bodyBytes, 'files[client]'), 'a,b\n1,2');
      expect(_multipartField(captured.bodyBytes, 'files[invoice]'), 'c,d\n3,4');
    });
  });
}
