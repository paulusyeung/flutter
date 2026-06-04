import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/system_log_api_model.dart';
import 'package:admin/data/models/domain/system_log.dart';

SystemLog _log({
  required int categoryId,
  required int eventId,
  required int typeId,
}) => SystemLog.fromApi(
  SystemLogApi(
    id: 'x',
    companyId: 'c1',
    eventId: eventId,
    categoryId: categoryId,
    typeId: typeId,
    createdAt: 1700000000,
    updatedAt: 1700000000,
  ),
);

void main() {
  group('SystemLog.categoryKey', () {
    test(
      'every documented React category id maps to the same translation key',
      () {
        // Mirrors `SystemLog.tsx:76-82`.
        const expectations = <int, String>{
          1: 'gateway_id',
          2: 'email',
          3: 'webhook',
          4: 'pdf',
          5: 'security',
        };
        for (final entry in expectations.entries) {
          expect(
            _log(categoryId: entry.key, eventId: 0, typeId: 0).categoryKey,
            entry.value,
            reason: 'category ${entry.key}',
          );
        }
      },
    );

    test('unknown ids fall back to "unknown"', () {
      expect(
        _log(categoryId: 99, eventId: 0, typeId: 0).categoryKey,
        'unknown',
      );
    });
  });

  group('SystemLog.eventKey', () {
    test('every React event id maps to its translation key', () {
      // Mirrors `SystemLog.tsx:84-101` — deliberately uses React's keys
      // (`success`, `failure`, `email_delivery`, `opened`, `login_failure`)
      // rather than v1's (`gateway_success`, `email_delivered`, …).
      const expectations = <int, String>{
        10: 'payment_failure',
        11: 'payment_success',
        21: 'success',
        22: 'failure',
        23: 'error',
        30: 'email_send',
        31: 'email_retry_queue',
        32: 'email_bounced',
        33: 'email_spam_complaint',
        34: 'email_delivery',
        35: 'opened',
        40: 'webhook_response',
        41: 'webhook_success',
        50: 'pdf',
        60: 'login_failure',
        61: 'user',
      };
      for (final entry in expectations.entries) {
        expect(
          _log(categoryId: 0, eventId: entry.key, typeId: 0).eventKey,
          entry.value,
          reason: 'event ${entry.key}',
        );
      }
    });
  });

  group('SystemLog.tone', () {
    test('success/failure/warning/neutral assignments are stable', () {
      SystemLogTone toneOf(int id) =>
          _log(categoryId: 0, eventId: id, typeId: 0).tone;
      // Successes
      for (final id in [11, 21, 34, 35, 41]) {
        expect(toneOf(id), SystemLogTone.success, reason: 'event $id');
      }
      // Failures
      for (final id in [10, 22, 32, 33, 60]) {
        expect(toneOf(id), SystemLogTone.failure, reason: 'event $id');
      }
      // Warnings
      for (final id in [23, 31]) {
        expect(toneOf(id), SystemLogTone.warning, reason: 'event $id');
      }
      // Everything else
      for (final id in [30, 40, 50, 61, 99]) {
        expect(toneOf(id), SystemLogTone.neutral, reason: 'event $id');
      }
    });
  });

  group('SystemLog.typeDisplay', () {
    test('translation-key types', () {
      final mapping = <int, String>{
        300: 'paypal',
        301: 'payment_type_stripe',
        302: 'ledger',
        303: 'failure',
        304: 'checkout_com',
        306: 'custom',
        309: 'wepay',
        321: 'gocardless',
        323: 'paypal',
      };
      for (final entry in mapping.entries) {
        final result = _log(
          categoryId: 0,
          eventId: 0,
          typeId: entry.key,
        ).typeDisplay();
        expect(result.isKey, isTrue, reason: 'type ${entry.key} should be key');
        expect(result.value, entry.value, reason: 'type ${entry.key}');
      }
    });

    test('literal-name types', () {
      final mapping = <int, String>{
        305: 'auth.net',
        307: 'Braintree',
        310: 'PayFast',
        311: 'PayTrace',
        312: 'Mollie',
        313: 'eWay',
        314: 'Forte',
        320: 'Square',
        322: 'Razorpay',
        400: 'Quota exceeded',
        401: 'Upstream failure',
        500: 'Webhook response',
        600: 'PDF Failure',
        // Deliberately corrected: React ships the typo 'PDF Sucess'
        // (SystemLog.tsx:125); we diverge to show the user the right word.
        601: 'PDF Success',
        701: 'Modified',
        702: 'Deleted',
        800: 'Login Success',
        801: 'Login Failure',
      };
      for (final entry in mapping.entries) {
        final result = _log(
          categoryId: 0,
          eventId: 0,
          typeId: entry.key,
        ).typeDisplay();
        expect(
          result.isKey,
          isFalse,
          reason: 'type ${entry.key} should be literal',
        );
        expect(result.value, entry.value, reason: 'type ${entry.key}');
      }
    });

    test('unknown type falls back to "Undefined Type"', () {
      final result = _log(
        categoryId: 0,
        eventId: 0,
        typeId: 9999,
      ).typeDisplay();
      expect(result.isKey, isFalse);
      expect(result.value, 'Undefined Type');
    });
  });

  group('SystemLog.fromApi', () {
    test('unix seconds → UTC DateTime', () {
      final log = SystemLog.fromApi(
        const SystemLogApi(
          id: 'a',
          companyId: 'c',
          eventId: 30,
          categoryId: 2,
          typeId: 303,
          createdAt: 1700000000,
          updatedAt: 1700000100,
        ),
      );
      expect(log.createdAt.isUtc, isTrue);
      expect(log.createdAt.millisecondsSinceEpoch, 1700000000 * 1000);
      expect(log.updatedAt.millisecondsSinceEpoch, 1700000100 * 1000);
    });
  });
}
