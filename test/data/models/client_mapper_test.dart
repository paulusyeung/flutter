import 'package:admin/data/models/api/client_api_model.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Client.fromApi', () {
    test('parses money as Decimal whether server sends string or number', () {
      final fromString = ClientApi.fromJson({
        'id': 'abc',
        'name': 'Acme',
        'balance': '123.45',
        'paid_to_date': '7.89',
      });
      final fromNumber = ClientApi.fromJson({
        'id': 'abc',
        'name': 'Acme',
        'balance': 123.45,
        'paid_to_date': 7.89,
      });

      final a = Client.fromApi(fromString);
      final b = Client.fromApi(fromNumber);

      expect(a.balance, Decimal.parse('123.45'));
      expect(a.paidToDate, Decimal.parse('7.89'));
      expect(b.balance, Decimal.parse('123.45'));
      expect(b.paidToDate, Decimal.parse('7.89'));
    });

    test('treats missing money as zero, never null', () {
      final c = Client.fromApi(ClientApi.fromJson({'id': 'a', 'name': 'X'}));
      expect(c.balance, Decimal.zero);
      expect(c.paidToDate, Decimal.zero);
      expect(c.creditBalance, Decimal.zero);
    });

    test('embeds contacts and surfaces the primary one', () {
      final api = ClientApi.fromJson({
        'id': 'a',
        'name': 'Acme',
        'contacts': [
          {
            'id': 'c1',
            'first_name': 'Jane',
            'last_name': 'Doe',
            'email': 'jane@acme.test',
            'is_primary': true,
          },
          {
            'id': 'c2',
            'first_name': 'John',
            'last_name': 'Roe',
            'is_primary': false,
          },
        ],
      });

      final c = Client.fromApi(api);
      expect(c.contacts, hasLength(2));
      expect(c.contacts.first.firstName, 'Jane');
      expect(c.contacts.first.isPrimary, isTrue);
      expect(c.contacts[1].firstName, 'John');
    });

    test('toApiJson round-trips money as fixed-precision strings', () {
      final c = Client.fromApi(ClientApi.fromJson({
        'id': 'a',
        'name': 'Acme',
        'balance': '99.99',
      }));
      final json = c.toApiJson();
      expect(json['balance'], '99.99');
      expect(json['id'], 'a');
    });

    test('toApiJson omits tmp ids so the server allocates a real one', () {
      final c = Client.fromApi(
        ClientApi.fromJson({'id': 'tmp_xyz', 'name': 'New'}),
      );
      final json = c.toApiJson();
      expect(json.containsKey('id'), isFalse);
      expect(json['name'], 'New');
    });
  });
}
