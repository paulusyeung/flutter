import 'package:admin/data/models/api/email_history_api_model.dart';
import 'package:admin/data/models/domain/email_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmailHistoryRecord.fromApi', () {
    test('parses the React clientHistory shape, snake_case keys included', () {
      final api = EmailHistoryRecordApi.fromJson({
        'entity': 'invoice',
        'entity_id': 'inv1',
        'subject': 'Invoice #1',
        'recipients': 'jane@acme.test',
        'events': [
          {
            'date': '2026-05-01 10:00:00',
            'delivery_message': 'hard bounce',
            'recipient': 'jane@acme.test',
            'server': 'mx.acme.test',
            'server_ip': '1.2.3.4',
            'status': 'bounced',
            'bounce_id': 'bid-123',
          },
          {
            'date': '2026-05-02 09:00:00',
            'status': 'delivered',
          },
        ],
      });

      final r = EmailHistoryRecord.fromApi(api);
      expect(r.entity, 'invoice');
      expect(r.entityId, 'inv1');
      expect(r.subject, 'Invoice #1');
      expect(r.recipients, 'jane@acme.test');
      expect(r.events, hasLength(2));

      final bounced = r.events[0];
      expect(bounced.deliveryMessage, 'hard bounce');
      expect(bounced.serverIp, '1.2.3.4');
      expect(bounced.bounceId, 'bid-123');
      expect(bounced.canReactivate, isTrue);

      final delivered = r.events[1];
      expect(delivered.bounceId, isEmpty);
      expect(delivered.canReactivate, isFalse);
    });

    test('tolerates a missing events array', () {
      final api = EmailHistoryRecordApi.fromJson({'entity': 'invoice'});
      final r = EmailHistoryRecord.fromApi(api);
      expect(r.events, isEmpty);
    });
  });
}
