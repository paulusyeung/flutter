import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/value/gateway.dart';
import 'package:admin/domain/gateway_constants.dart';

void main() {
  group('GatewayOptions.fromMap', () {
    test('parses the webhooks list', () {
      final o = GatewayOptions.fromMap(const {
        'support_token_billing': true,
        'support_refunds': false,
        'webhooks': ['a.b.c', 'd.e.f'],
      });
      expect(o.supportTokenBilling, isTrue);
      expect(o.supportRefunds, isFalse);
      expect(o.webhooks, ['a.b.c', 'd.e.f']);
    });

    test('defaults webhooks to empty when absent or not a list', () {
      expect(GatewayOptions.fromMap(const {}).webhooks, isEmpty);
      expect(
        GatewayOptions.fromMap(const {'webhooks': 'nope'}).webhooks,
        isEmpty,
      );
    });
  });

  group('Gateway.supportedEvents', () {
    Gateway gw(Map<String, GatewayOptions> options) => Gateway(
      id: 'k',
      name: 'n',
      fields: '{}',
      defaultGatewayTypeId: '1',
      sortOrder: 0,
      isOffsite: false,
      isVisible: true,
      siteUrl: '',
      options: options,
    );

    test('unions across options, dedupes, order-stable', () {
      final g = gw(const {
        '1': GatewayOptions(
          supportTokenBilling: false,
          supportRefunds: false,
          webhooks: ['x', 'y'],
        ),
        '2': GatewayOptions(
          supportTokenBilling: false,
          supportRefunds: false,
          webhooks: ['y', 'z'],
        ),
      });
      expect(g.supportedEvents(), ['x', 'y', 'z']);
    });

    test('empty when no option declares webhooks', () {
      final g = gw(const {
        '1': GatewayOptions(supportTokenBilling: false, supportRefunds: false),
      });
      expect(g.supportedEvents(), isEmpty);
    });
  });

  group('gateway constants', () {
    test('kAllCreditCardTypes is all five brands OR-ed (= 31)', () {
      expect(kAllCreditCardTypes, 31);
      for (final bit in kCardTypeBits) {
        expect(kAllCreditCardTypes & bit, bit);
      }
    });

    test('kHostedHiddenGatewayKeys is exactly Express / REST / WePay', () {
      expect(kHostedHiddenGatewayKeys, {
        kGatewayPayPalExpress,
        kGatewayPayPalRest,
        kGatewayWePay,
      });
    });
  });
}
