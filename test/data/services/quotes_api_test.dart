import 'dart:convert';

import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/api_credentials.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:admin/data/services/quotes_api.dart';
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

void main() {
  // Launch-blocker regression. The quote "First reminder" email must resolve
  // to the server's IRREGULAR settings key on the immediate `/emails` path
  // (`email_quote_template_reminder1`), and to the BARE name on the scheduled
  // `task_schedulers` path (`reminder1`, the `Quote/SendEmail` match arm).
  // The old single token `quote_reminder1` 422-parked the immediate send and
  // silently sent the INITIAL template on the scheduled one.
  group('QuotesApi email template wire mapping', () {
    Future<Map<String, dynamic>> capture(
      Future<void> Function(QuotesApi api) run,
    ) async {
      http.BaseRequest? captured;
      final fake = MockClient((req) async {
        captured = req;
        return http.Response('', 200); // empty → mutate returns null
      });
      await run(QuotesApi(_client(fake)));
      return jsonDecode((captured! as http.Request).body)
          as Map<String, dynamic>;
    }

    test('email(quote_reminder1) → POST /api/v1/emails '
        '{template: email_quote_template_reminder1}', () async {
      final body = await capture(
        (api) => api.email(
          id: 'q_1',
          template: 'quote_reminder1',
          idempotencyKey: 'k',
        ),
      );
      expect(body['entity'], 'quote');
      expect(body['entity_id'], 'q_1');
      expect(body['template'], 'email_quote_template_reminder1');
    });

    test('email(quote) → email_template_quote; email(custom1) → '
        'email_template_custom1 (regular keys unaffected)', () async {
      final initial = await capture(
        (api) => api.email(id: 'q_1', template: 'quote', idempotencyKey: 'k'),
      );
      expect(initial['template'], 'email_template_quote');

      final custom = await capture(
        (api) => api.email(id: 'q_1', template: 'custom1', idempotencyKey: 'k'),
      );
      expect(custom['template'], 'email_template_custom1');
    });

    test('scheduleEmail(quote_reminder1) → task_schedulers '
        'parameters.template == reminder1 (bare)', () async {
      final body = await capture(
        (api) => api.scheduleEmail(
          id: 'q_1',
          template: 'quote_reminder1',
          sendAt: '2030-01-15T10:00:00.000',
          idempotencyKey: 'k',
        ),
      );
      expect(body['template'], 'email_record');
      final params = body['parameters'] as Map<String, dynamic>;
      expect(params['entity'], 'quote');
      expect(params['entity_id'], 'q_1');
      expect(params['template'], 'reminder1');
    });

    test(
      'scheduleEmail(quote) passes the bare name through unchanged',
      () async {
        final body = await capture(
          (api) => api.scheduleEmail(
            id: 'q_1',
            template: 'quote',
            sendAt: '2030-01-15T10:00:00.000',
            idempotencyKey: 'k',
          ),
        );
        final params = body['parameters'] as Map<String, dynamic>;
        expect(params['template'], 'quote');
      },
    );
  });
}
