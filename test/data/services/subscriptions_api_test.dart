import 'dart:convert';

import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/api_credentials.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:admin/data/services/subscriptions_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ApiClient _client(MockClient http) => ApiClient(
  credentials: ValueNotifier<ApiCredentials?>(
    const ApiCredentials(baseUrl: 'https://test', token: 't'),
  ),
  passwordCache: PasswordCache(),
  onUnauthorized: () async {},
  httpClient: http,
);

void main() {
  group('SubscriptionsApi.checkSteps', () {
    test(
      'returns the step ordering errors from the server\'s 422 envelope '
      '(`{errors: {steps: [...]}}`, matching React Steps.tsx:76-78)',
      () async {
        http.Request? captured;
        final fake = MockClient((req) async {
          captured = req;
          return http.Response(
            jsonEncode({
              'message': 'Validation Failed',
              'errors': {
                'steps': [
                  'Cart step requires auth.login earlier',
                  'Duplicate step',
                ],
              },
            }),
            422,
            headers: {'content-type': 'application/json'},
          );
        });
        final api = SubscriptionsApi(_client(fake));

        final errors = await api.checkSteps(['cart', 'auth.login']);

        // Body is the comma-joined string (per React Steps.tsx:73).
        expect(captured, isNotNull);
        expect(captured!.method, 'POST');
        expect(captured!.url.path, '/api/v1/subscriptions/steps/check');
        final body = jsonDecode(captured!.body) as Map<String, dynamic>;
        expect(body['steps'], 'cart,auth.login');

        expect(errors, [
          'Cart step requires auth.login earlier',
          'Duplicate step',
        ]);
      },
    );

    test('returns empty list on a 200 (the ordering is valid)', () async {
      final fake = MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'ok'}),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      final errors = await SubscriptionsApi(_client(fake)).checkSteps(['cart']);
      expect(errors, isEmpty);
    });

    test('returns empty list when the 422 envelope has no `steps` field '
        '(server flagged something other than steps)', () async {
      final fake = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message': 'Validation Failed',
            'errors': {
              'name': ['Name is required'],
            },
          }),
          422,
          headers: {'content-type': 'application/json'},
        ),
      );
      final errors = await SubscriptionsApi(_client(fake)).checkSteps(['cart']);
      expect(errors, isEmpty);
    });

    test(
      'returns empty list (and skips the round-trip) for an empty input',
      () async {
        var calls = 0;
        final fake = MockClient((_) async {
          calls++;
          return http.Response('{}', 200);
        });
        final errors = await SubscriptionsApi(
          _client(fake),
        ).checkSteps(const []);
        expect(errors, isEmpty);
        expect(calls, 0, reason: 'no HTTP call for empty step list');
      },
    );
  });

  group('SubscriptionsApi.listSteps', () {
    test('flattens the keyed-object response shape `{id: {id,label,deps}}` '
        'into a list (matches React Steps.tsx step catalog parsing)', () async {
      final fake = MockClient((req) async {
        expect(req.method, 'GET');
        expect(req.url.path, '/api/v1/subscriptions/steps');
        return http.Response(
          jsonEncode({
            'auth.login': {
              'id': 'auth.login',
              'label': 'Login',
              'dependencies': <String>[],
            },
            'cart': {
              'id': 'cart',
              'label': 'Cart',
              'dependencies': ['auth.login'],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final steps = await SubscriptionsApi(_client(fake)).listSteps();

      expect(steps, hasLength(2));
      expect(steps.map((s) => s.id).toSet(), {'auth.login', 'cart'});
      final cart = steps.firstWhere((s) => s.id == 'cart');
      expect(cart.dependencies, ['auth.login']);
    });
  });
}
