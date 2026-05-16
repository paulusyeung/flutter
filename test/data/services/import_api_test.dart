import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:admin/data/models/domain/import_preview.dart';
import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/api_credentials.dart';
import 'package:admin/data/services/import_api.dart';
import 'package:admin/data/services/password_cache.dart';

ValueListenable<ApiCredentials?> _creds() => ValueNotifier<ApiCredentials?>(
  const ApiCredentials(baseUrl: 'https://test', token: 't'),
);

void main() {
  group('ImportPreview.fromJson', () {
    test('parses hash, columns, sample, available, hints', () {
      final p = ImportPreview.fromJson({
        'hash': 'h1',
        'mappings': {
          'client': {
            'headers': [
              ['Name', 'Email'],
              ['Acme', 'a@b.c'],
            ],
            'available': ['client.name', 'client.email'],
            'hints': [0, 1],
          },
        },
      }, 'client');
      expect(p.hash, 'h1');
      expect(p.columns, ['Name', 'Email']);
      expect(p.sample, ['Acme', 'a@b.c']);
      expect(p.available, ['client.name', 'client.email']);
      expect(p.hints, [0, 1]);
    });

    test('falls back to data.hash and tolerates missing pieces', () {
      final p = ImportPreview.fromJson({
        'data': {'hash': 'h2'},
        'mappings': {
          'invoice': {
            'headers': [
              ['Number'],
            ],
            'available': ['invoice.number'],
          },
        },
      }, 'invoice');
      expect(p.hash, 'h2');
      expect(p.columns, ['Number']);
      expect(p.sample, isEmpty);
      expect(p.hints, isEmpty);
    });

    test('empty when entity not in mappings', () {
      final p = ImportPreview.fromJson(
        {'hash': 'h', 'mappings': <String, dynamic>{}},
        'task',
      );
      expect(p.columns, isEmpty);
      expect(p.available, isEmpty);
    });
  });

  group('ImportApi', () {
    test('preImport POSTs to /api/v1/preimport and parses the response',
        () async {
      String? hitPath;
      final fake = MockClient((req) async {
        hitPath = req.url.path;
        return http.Response(
          jsonEncode({
            'hash': 'abc',
            'mappings': {
              'client': {
                'headers': [
                  ['Name'],
                  ['Acme'],
                ],
                'available': ['client.name'],
                'hints': [0],
              },
            },
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      });
      final client = ApiClient(
        credentials: _creds(),
        passwordCache: PasswordCache(),
        onUnauthorized: () async {},
        httpClient: fake,
      );
      final api = ImportApi(client);

      final preview = await api.preImport(
        entity: 'client',
        fileName: 'c.csv',
        bytes: Uint8List.fromList(utf8.encode('Name\nAcme')),
      );

      expect(hitPath, '/api/v1/preimport');
      expect(preview.hash, 'abc');
      expect(preview.available, ['client.name']);
    });

    test('runImport posts the column_map JSON shape', () async {
      Map<String, dynamic>? body;
      String? path;
      final fake = MockClient((req) async {
        path = req.url.path;
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({'message': 'Import queued'}),
          200,
          headers: const {'content-type': 'application/json'},
        );
      });
      final client = ApiClient(
        credentials: _creds(),
        passwordCache: PasswordCache(),
        onUnauthorized: () async {},
        httpClient: fake,
      );
      final api = ImportApi(client);

      final msg = await api.runImport(
        hash: 'abc',
        entity: 'client',
        skipHeader: true,
        columnMap: {0: 'client.name', 1: '', 2: 'client.email'},
      );

      expect(path, '/api/v1/import');
      expect(msg, 'Import queued');
      expect(body!['hash'], 'abc');
      expect(body!['import_type'], 'client');
      expect(body!['skip_header'], true);
      final mapping =
          (body!['column_map'] as Map)['client']['mapping'] as Map;
      // Empty selections are dropped; keys are stringified indices.
      expect(mapping, {'0': 'client.name', '2': 'client.email'});
    });
  });
}
