import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/api_credentials.dart';
import 'package:admin/data/services/bank_accounts_api.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:admin/ui/features/bank_accounts/views/bank_account_list_screen.dart';

ValueListenable<ApiCredentials?> _creds() => ValueNotifier<ApiCredentials?>(
  const ApiCredentials(baseUrl: 'https://co.example.com/', token: 't'),
);

void main() {
  group('connectBankUrl (admin-portal parity)', () {
    test('yodlee → server-relative base (NOT a hardcoded domain)', () {
      expect(
        connectBankUrl('yodlee', 'abc', 'https://co.example.com'),
        'https://co.example.com/yodlee/onboard/abc',
      );
    });

    test('both providers strip /api/v1 + trailing slash from the base', () {
      expect(
        connectBankUrl('nordigen', 'xyz', 'https://co.example.com/'),
        'https://co.example.com/nordigen/connect/xyz',
      );
      expect(
        connectBankUrl('nordigen', 'xyz', 'https://co.example.com'),
        'https://co.example.com/nordigen/connect/xyz',
      );
      expect(
        connectBankUrl('yodlee', 'H', 'https://co.example.com/api/v1'),
        'https://co.example.com/yodlee/onboard/H',
      );
      expect(
        connectBankUrl('nordigen', 'H', 'https://co.example.com/api/v1/'),
        'https://co.example.com/nordigen/connect/H',
      );
    });

    test('hosted production base is unchanged (still invoicing.co)', () {
      expect(
        connectBankUrl('yodlee', 'H', 'https://invoicing.co/api/v1'),
        'https://invoicing.co/yodlee/onboard/H',
      );
    });
  });

  group('BankAccountsApi.oneTimeToken', () {
    test('POSTs {context,platform} and returns the hash (data or flat)',
        () async {
      Uri? captured;
      Map<String, dynamic>? body;
      final fake = MockClient((req) async {
        captured = req.url;
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({'data': {'hash': 'H123'}}),
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

      final hash =
          await BankAccountsApi(client).oneTimeToken(context: 'yodlee');

      expect(captured!.path, '/api/v1/one_time_token');
      expect(body!['context'], 'yodlee');
      expect(body!['platform'], 'flutter');
      expect(hash, 'H123');
    });

    test('tolerates a flat {hash} body; throws when absent', () async {
      ApiClient mk(Object responseBody) => ApiClient(
            credentials: _creds(),
            passwordCache: PasswordCache(),
            onUnauthorized: () async {},
            httpClient: MockClient((_) async => http.Response(
                  jsonEncode(responseBody),
                  200,
                  headers: const {'content-type': 'application/json'},
                )),
          );

      expect(
        await BankAccountsApi(mk({'hash': 'flat'}))
            .oneTimeToken(context: 'nordigen'),
        'flat',
      );
      expect(
        () => BankAccountsApi(mk({'nope': true}))
            .oneTimeToken(context: 'nordigen'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
