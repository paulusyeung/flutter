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

    test('maps contact is_locked (bounce/unsubscribe) and never writes it '
        'back so a normal save cannot clear server bounce state', () {
      final api = ClientApi.fromJson({
        'id': 'a',
        'name': 'Acme',
        'contacts': [
          {'id': 'c1', 'email': 'a@x.test', 'is_locked': true},
          {'id': 'c2', 'email': 'b@x.test'},
        ],
      });

      final c = Client.fromApi(api);
      expect(c.contacts[0].isLocked, isTrue);
      expect(c.contacts[1].isLocked, isFalse, reason: 'defaults false');

      final json = c.toApiJson();
      final contactsJson =
          (json['contacts'] as List).cast<Map<String, dynamic>>();
      expect(
        contactsJson.every((m) => !m.containsKey('is_locked')),
        isTrue,
        reason: 'is_locked is server-managed; reactivation is the only writer',
      );
    });

    test('round-trips contact cc_only (defaults false, written back)', () {
      final api = ClientApi.fromJson({
        'id': 'a',
        'name': 'Acme',
        'contacts': [
          {'id': 'c1', 'email': 'a@x.test', 'cc_only': true},
          {'id': 'c2', 'email': 'b@x.test'},
        ],
      });

      final c = Client.fromApi(api);
      expect(c.contacts[0].ccOnly, isTrue);
      expect(c.contacts[1].ccOnly, isFalse, reason: 'defaults false');

      final json = c.toApiJson();
      final contactsJson =
          (json['contacts'] as List).cast<Map<String, dynamic>>();
      expect(contactsJson[0]['cc_only'], isTrue);
      expect(contactsJson[1]['cc_only'], isFalse);
    });

    test('embeds locations read-side; toApiJson omits them (written via '
        'the standalone /api/v1/locations resource)', () {
      final api = ClientApi.fromJson({
        'id': 'a',
        'name': 'Acme',
        'locations': [
          {
            'id': 'L1',
            'client_id': 'a',
            'name': 'HQ',
            'address1': '1 Main St',
            'city': 'Springfield',
            'country_id': '840',
            'is_shipping_location': true,
          },
          {
            'id': 'L2',
            'client_id': 'a',
            'name': 'Warehouse',
            'is_shipping_location': false,
          },
        ],
      });

      final c = Client.fromApi(api);
      expect(c.locations, hasLength(2));
      expect(c.locations.first.name, 'HQ');
      expect(c.locations.first.address1, '1 Main St');
      expect(c.locations.first.countryId, '840');
      expect(c.locations.first.isShippingLocation, isTrue);
      expect(c.locations[1].name, 'Warehouse');
      expect(c.locations[1].isShippingLocation, isFalse);
      // Locations are NOT part of the client save payload (React parity:
      // they're written via POST/PUT/DELETE /api/v1/locations).
      expect(c.toApiJson().containsKey('locations'), isFalse);
    });

    test('toApiJson round-trips money as fixed-precision strings', () {
      final c = Client.fromApi(
        ClientApi.fromJson({'id': 'a', 'name': 'Acme', 'balance': '99.99'}),
      );
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
