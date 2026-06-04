import 'package:flutter_test/flutter_test.dart';

import 'package:admin/domain/notifications.dart';

void main() {
  test('quote_rejected is one of the 21 modeled events (React parity)', () {
    final ids = kNotificationEvents.map((e) => e.id).toList();
    expect(ids, contains('quote_rejected'));
    expect(kNotificationEvents, hasLength(21));
  });

  group('unmodeledNotificationTokens', () {
    test('keeps self-profile + future tokens, drops modeled/global ones', () {
      final unknown = unmodeledNotificationTokens(const [
        'invoice_created_all', // known event token
        'quote_rejected_user', // known after the quote_rejected fix
        'all_notifications', // global
        'task_assigned', // self-only toggle → unmodeled
        'enable_e_invoice_received_notification', // self-only → unmodeled
        'future_event_all', // unknown future event → keep
      ]);
      expect(
        unknown,
        containsAll(<String>[
          'task_assigned',
          'enable_e_invoice_received_notification',
          'future_event_all',
        ]),
      );
      expect(unknown, isNot(contains('invoice_created_all')));
      expect(unknown, isNot(contains('quote_rejected_user')));
      expect(unknown, isNot(contains('all_notifications')));
    });
  });

  group('tokensFor', () {
    test('global "all records" serializes to exactly [all_notifications]', () {
      expect(
        tokensFor(global: NotificationGlobal.allRecords, perEvent: const {}),
        const ['all_notifications'],
      );
    });

    test('custom emits per-event _all/_user and omits "none"', () {
      final tokens = tokensFor(
        global: NotificationGlobal.custom,
        perEvent: const {
          'invoice_created': NotificationChoice.all,
          'payment_success': NotificationChoice.user,
          'quote_viewed': NotificationChoice.none,
        },
      );
      expect(
        tokens,
        containsAll(<String>['invoice_created_all', 'payment_success_user']),
      );
      expect(tokens.where((t) => t.startsWith('quote_viewed')), isEmpty);
    });
  });
}
