import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:admin/data/services/activities_api.dart';
import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/api_credentials.dart';
import 'package:admin/data/services/password_cache.dart';

ValueListenable<ApiCredentials?> _creds() => ValueNotifier<ApiCredentials?>(
  const ApiCredentials(baseUrl: 'https://test', token: 't'),
);

void main() {
  group('ActivitiesApi.fetchUserActivities', () {
    test('GETs /activities?user_id and parses the flat feed shape', () async {
      Uri? captured;
      String? capturedMethod;
      final fake = MockClient((req) async {
        captured = req.url;
        capturedMethod = req.method;
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 'O5xe73je7r',
                'activity_type_id': '4',
                'client_id': 'wMvbmOeYAl',
                'user_id': 'VolejRejNm',
                'invoice_id': 'z3YaOpbxql',
                'notes': '',
                'ip': '192.0.2.1',
                'created_at': 1778990481,
              },
              {
                'id': 'A2',
                'activity_type_id': 141,
                'user_id': 'VolejRejNm',
                'notes': 'a comment',
                'created_at': 1778990400,
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
      final api = ActivitiesApi(client);

      final rows = await api.fetchUserActivities('VolejRejNm');

      expect(capturedMethod, 'GET');
      expect(captured!.path, '/api/v1/activities');
      expect(captured!.queryParameters['user_id'], 'VolejRejNm');
      expect(rows, hasLength(2));
      // String activity_type_id coerces to int (flat feed sends both forms).
      expect(rows.first.id, 'O5xe73je7r');
      expect(rows.first.activityTypeId, 4);
      expect(rows.first.userId, 'VolejRejNm');
      expect(rows.first.invoiceId, 'z3YaOpbxql');
      expect(rows[1].activityTypeId, 141);
      expect(rows[1].notes, 'a comment');
    });

    test('tolerates a bare list body (no data envelope)', () async {
      final fake = MockClient((req) async {
        return http.Response(
          jsonEncode([
            {'id': 'X', 'activity_type_id': 5, 'created_at': 1},
          ]),
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
      final rows = await ActivitiesApi(client).fetchUserActivities('u1');

      expect(rows, hasLength(1));
      expect(rows.first.id, 'X');
      expect(rows.first.activityTypeId, 5);
    });
  });
}
