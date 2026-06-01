import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/api_credentials.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:admin/data/services/search_api.dart';

ValueListenable<ApiCredentials?> _creds() => ValueNotifier<ApiCredentials?>(
  const ApiCredentials(baseUrl: 'https://test', token: 't'),
);

void main() {
  group('SearchApi.search', () {
    test('flattens the grouped response preserving the group key + sends '
        '?search=', () async {
      Uri? captured;
      String? method;
      final fake = MockClient((req) async {
        captured = req.url;
        method = req.method;
        return http.Response(
          jsonEncode({
            'clients': [
              {
                'name': 'Goyette and Sons',
                'type': '/client',
                'id': 'QJ0dN6dLOv',
                'path': '/clients/QJ0dN6dLOv',
              },
            ],
            'invoices': [
              {
                'name': 'Emard-Kuhn - 0025',
                'type': '/invoice',
                'id': 'z3YaOpbxql',
                'path': '/invoices/z3YaOpbxql/edit',
              },
            ],
            'settings': [
              {
                'name': 'User Details',
                'type': 'user_details',
                'id': 'User Details',
                'path': '/settings/user_details',
              },
            ],
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

      final results = await SearchApi(client).search('  acme ');

      expect(method, 'POST');
      expect(captured!.path, '/api/v1/search');
      expect(captured!.queryParameters['search'], 'acme'); // trimmed
      expect(results, hasLength(3));

      final client0 = results.firstWhere((r) => r.group == 'clients');
      expect(client0.name, 'Goyette and Sons');
      expect(client0.id, 'QJ0dN6dLOv');
      expect(client0.path, '/clients/QJ0dN6dLOv');
      expect(client0.isSettings, isFalse);

      final settings0 = results.firstWhere((r) => r.group == 'settings');
      expect(settings0.isSettings, isTrue);
      expect(settings0.path, '/settings/user_details');
    });

    test('empty query omits the search param; non-map body → []', () async {
      Uri? captured;
      final fake = MockClient((req) async {
        captured = req.url;
        return http.Response(
          '[]',
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

      final results = await SearchApi(client).search('   ');
      expect(captured!.queryParameters.containsKey('search'), isFalse);
      expect(results, isEmpty);
    });
  });
}
