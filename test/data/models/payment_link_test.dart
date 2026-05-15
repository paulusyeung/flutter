import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/subscription_api_model.dart';
import 'package:admin/data/models/domain/payment_link.dart';

void main() {
  group('PaymentLink.fromApi', () {
    test('parses price from a numeric wire value', () {
      const api = SubscriptionApi(id: 's_1', name: 'A', price: 9.5);
      final s = PaymentLink.fromApi(api);
      expect(s.price, Decimal.parse('9.5'));
    });

    test('parses price from a string wire value', () {
      const api = SubscriptionApi(id: 's_2', name: 'B', price: '12.34');
      final s = PaymentLink.fromApi(api);
      expect(s.price, Decimal.parse('12.34'));
    });

    test('coerces malformed price to zero', () {
      const api = SubscriptionApi(id: 's_3', name: 'C', price: 'banana');
      final s = PaymentLink.fromApi(api);
      expect(s.price, Decimal.zero);
    });

    test('defaults isDirty to false (repo overlays the local flag)', () {
      const api = SubscriptionApi(id: 's_4', name: 'D');
      expect(PaymentLink.fromApi(api).isDirty, isFalse);
    });

    test('parses webhook_configuration with []-shaped headers', () {
      // PHP serializes an empty assoc-array as `[]`; the strict cast used to
      // crash here.
      final api = SubscriptionApi.fromJson({
        'id': 's_headers_empty',
        'name': 'E',
        'webhook_configuration': {'post_purchase_headers': <dynamic>[]},
      });
      expect(api.webhookConfiguration.postPurchaseHeaders, isEmpty);
    });

    test('parses webhook_configuration with populated headers map', () {
      final api = SubscriptionApi.fromJson({
        'id': 's_headers_map',
        'name': 'F',
        'webhook_configuration': {
          'post_purchase_headers': {'X-Foo': 'bar', 'X-Num': 7},
        },
      });
      expect(
        api.webhookConfiguration.postPurchaseHeaders,
        {'X-Foo': 'bar', 'X-Num': '7'},
      );
    });

    test('round-trips webhook headers through fromApi', () {
      const api = SubscriptionApi(
        id: 's_5',
        name: 'E',
        webhookConfiguration: WebhookConfigurationApi(
          postPurchaseUrl: 'https://example.test/x',
          postPurchaseRestMethod: 'put',
          postPurchaseHeaders: {'Authorization': 'Bearer 123'},
        ),
      );
      final s = PaymentLink.fromApi(api);
      expect(s.webhookConfiguration.postPurchaseUrl, 'https://example.test/x');
      expect(s.webhookConfiguration.postPurchaseRestMethod, 'put');
      expect(
        s.webhookConfiguration.postPurchaseHeaders,
        {'Authorization': 'Bearer 123'},
      );
    });
  });

  group('PaymentLink.toApiJson', () {
    test('drops tmp_ id by default; keeps it when preserveTempId is true', () {
      final s = emptyPaymentLink().copyWith(id: 'tmp_xyz', name: 'A');
      final apiJson = s.toApiJson();
      expect(apiJson.containsKey('id'), isFalse);
      final localJson = s.toApiJson(preserveTempId: true);
      expect(localJson['id'], 'tmp_xyz');
    });

    test('keeps a real id', () {
      final s = emptyPaymentLink().copyWith(id: 'real_1', name: 'A');
      expect(s.toApiJson()['id'], 'real_1');
    });

    test('serializes Decimal price as a string', () {
      // Decimal canonicalizes — trailing zeros are dropped on parse.
      final s = emptyPaymentLink().copyWith(
        id: 'real_1',
        name: 'A',
        price: Decimal.parse('12.50'),
      );
      expect(s.toApiJson()['price'], '12.5');
    });

    test('round-trips webhook headers map verbatim', () {
      final s = emptyPaymentLink().copyWith(
        id: 'real_1',
        name: 'A',
        webhookConfiguration: const PaymentLinkWebhook(
          returnUrl: '',
          postPurchaseUrl: 'https://example.test/x',
          postPurchaseRestMethod: 'post',
          postPurchaseHeaders: {'k': 'v'},
          postPurchaseBody: '',
        ),
      );
      final webhook =
          s.toApiJson()['webhook_configuration'] as Map<String, dynamic>;
      expect(webhook['post_purchase_url'], 'https://example.test/x');
      expect(webhook['post_purchase_rest_method'], 'post');
      expect(webhook['post_purchase_headers'], {'k': 'v'});
    });

    test('round-trips comma-joined steps', () {
      final s = emptyPaymentLink().copyWith(
        id: 'real_1',
        name: 'A',
        steps: 'auth.login,cart',
      );
      expect(s.toApiJson()['steps'], 'auth.login,cart');
    });

    test('round-trips opaque plan_map', () {
      final s = emptyPaymentLink().copyWith(
        id: 'real_1',
        name: 'A',
        planMap: 'opaque',
      );
      expect(s.toApiJson()['plan_map'], 'opaque');
    });

    test('preserveTempId emits user_id / timestamps / is_deleted so the '
        'local Drift round-trip is lossless', () {
      final s = emptyPaymentLink().copyWith(
        id: 'real_1',
        userId: 'u_1',
        name: 'A',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          1700000100 * 1000,
          isUtc: true,
        ),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          1700000200 * 1000,
          isUtc: true,
        ),
        isDeleted: true,
      );
      // Outbox shape — no identity / timestamps.
      final outbox = s.toApiJson();
      expect(outbox.containsKey('user_id'), isFalse);
      expect(outbox.containsKey('created_at'), isFalse);
      expect(outbox.containsKey('updated_at'), isFalse);
      expect(outbox.containsKey('archived_at'), isFalse);
      expect(outbox.containsKey('is_deleted'), isFalse);

      // Drift round-trip shape — full identity + timestamps.
      final local = s.toApiJson(preserveTempId: true);
      expect(local['user_id'], 'u_1');
      expect(local['created_at'], 1700000100);
      expect(local['updated_at'], 1700000200);
      expect(local['is_deleted'], isTrue);
    });
  });

  group('emptyPaymentLink defaults', () {
    test('matches admin-portal defaults (frequency=monthly, cycles=-1, '
        'amount_discount=true, steps=cart+auth)', () {
      final s = emptyPaymentLink();
      expect(s.frequencyId, '5'); // kRecurringFrequencyMonthly
      expect(s.remainingCycles, -1);
      expect(s.autoBill, '');
      expect(s.isAmountDiscount, isTrue);
      expect(s.steps, 'cart,auth.login-or-register');
      expect(s.allowCancellation, isFalse);
      expect(s.trialEnabled, isFalse);
      expect(s.perSeatEnabled, isFalse);
    });
  });
}
