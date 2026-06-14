import 'package:admin/data/models/api/task_api_model.dart';
import 'package:admin/data/models/domain/task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Task meta tolerant parse', () {
    test('empty-string meta decodes to null (server sends "" when unset)', () {
      final api = TaskApi.fromJson({'id': '1', 'meta': ''});
      expect(api.meta, isNull);
      expect(Task.fromApi(api).meta, isNull);
    });

    test('object meta decodes calendar_event_id', () {
      final api = TaskApi.fromJson({
        'id': '1',
        'meta': {'calendar_event_id': 'u:google:abc:e1'},
      });
      expect(api.meta?.calendarEventId, 'u:google:abc:e1');
      expect(Task.fromApi(api).meta?.calendarEventId, 'u:google:abc:e1');
    });

    test('absent meta decodes to null', () {
      expect(TaskApi.fromJson({'id': '1'}).meta, isNull);
    });

    test('meta with empty calendar_event_id maps to null on the domain', () {
      final api = TaskApi.fromJson({
        'id': '1',
        'meta': {'calendar_event_id': ''},
      });
      expect(Task.fromApi(api).meta, isNull);
    });
  });

  group('Task.toApiJson meta', () {
    test('omits meta when null', () {
      final task = Task.fromApi(TaskApi.fromJson({'id': '1'}));
      expect(task.toApiJson().containsKey('meta'), isFalse);
    });

    test('emits meta.calendar_event_id when set', () {
      final task = Task.fromApi(
        TaskApi.fromJson({
          'id': '1',
          'meta': {'calendar_event_id': 'x'},
        }),
      );
      expect(task.toApiJson()['meta'], {'calendar_event_id': 'x'});
    });
  });
}
