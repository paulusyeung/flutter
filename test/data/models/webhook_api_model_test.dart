import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/webhook_api_model.dart';

void main() {
  group('WebhookApi.fromJson', () {
    test('parses []-shaped empty headers without crashing', () {
      // PHP serializes an empty assoc-array as `[]`; the strict cast used
      // to crash here.
      final api = WebhookApi.fromJson({
        'id': 'w_1',
        'event_id': '1',
        'target_url': 'https://example.test/hook',
        'headers': <dynamic>[],
      });
      expect(api.headers, isEmpty);
      expect(api.id, 'w_1');
    });

    test('parses populated headers map, stringifying values', () {
      final api = WebhookApi.fromJson({
        'id': 'w_2',
        'headers': {'X-Foo': 'bar', 'X-Num': 7},
      });
      expect(api.headers, {'X-Foo': 'bar', 'X-Num': '7'});
    });

    test('falls back to empty map when headers key is missing', () {
      final api = WebhookApi.fromJson({'id': 'w_3'});
      expect(api.headers, isEmpty);
    });
  });
}
