import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

import 'package:admin/app/debug_capture_store.dart';

void main() {
  group('DebugCaptureStore', () {
    test('defaults to disabled, recording is a no-op', () {
      final store = DebugCaptureStore();
      expect(store.enabled, isFalse);

      final id = store.beginRequest(
        method: 'GET',
        url: '/api/v1/clients',
        headers: const {},
      );
      expect(id, isNull);
      store.recordError(StateError('boom'), null);
      store.recordLog(LogRecord(Level.WARNING, 'msg', 'logger'));
      expect(store.networkEntries, isEmpty);
      expect(store.diagnosticEntries, isEmpty);
    });

    test('disabling pauses capture but keeps existing entries', () {
      final store = DebugCaptureStore();
      store.setEnabled(true);
      store.recordError(StateError('boom'), null);
      final id = store.beginRequest(
        method: 'GET',
        url: '/api/v1/clients',
        headers: const {},
      );
      store.completeRequest(id, statusCode: 200, duration: Duration.zero);
      expect(store.diagnosticEntries, hasLength(1));
      expect(store.networkEntries, hasLength(1));

      store.setEnabled(false);
      expect(store.enabled, isFalse);
      // Already-captured entries survive — only new captures are blocked.
      expect(store.diagnosticEntries, hasLength(1));
      expect(store.networkEntries, hasLength(1));

      // New captures while disabled are no-ops.
      store.recordError(StateError('ignored'), null);
      expect(store.diagnosticEntries, hasLength(1));
    });

    test('toggling off mid-request drops the pending in-flight', () {
      final store = DebugCaptureStore()..setEnabled(true);
      final id = store.beginRequest(
        method: 'GET',
        url: '/api/v1/clients',
        headers: const {},
      );
      store.setEnabled(false);
      store.completeRequest(id, statusCode: 200, duration: Duration.zero);
      // The pending request was dropped on disable, so completion is a no-op.
      expect(store.networkEntries, isEmpty);
    });

    test('completeRequest records status, duration, response body', () {
      final store = DebugCaptureStore()..setEnabled(true);
      final id = store.beginRequest(
        method: 'GET',
        url: 'https://example.com/api/v1/clients',
        headers: const {'Accept': 'application/json'},
      );
      expect(id, isNotNull);
      store.completeRequest(
        id,
        statusCode: 200,
        duration: const Duration(milliseconds: 123),
        responseBody: '{"data":[]}',
        responseHeaders: const {'content-type': 'application/json'},
      );
      final entry = store.networkEntries.single;
      expect(entry.method, 'GET');
      expect(entry.statusCode, 200);
      expect(entry.duration.inMilliseconds, 123);
      expect(entry.responseBody, contains('"data"'));
      expect(entry.error, isNull);
      expect(entry.succeeded, isTrue);
    });

    test('failRequest records the error and clears pending state', () {
      final store = DebugCaptureStore()..setEnabled(true);
      final id = store.beginRequest(
        method: 'POST',
        url: '/api/v1/clients',
        headers: const {},
      );
      store.failRequest(
        id,
        duration: const Duration(milliseconds: 50),
        error: Exception('boom'),
      );
      final entry = store.networkEntries.single;
      expect(entry.error, contains('boom'));
      expect(entry.statusCode, isNull);
      expect(entry.succeeded, isFalse);
    });

    test('headers are redacted on store', () {
      final store = DebugCaptureStore()..setEnabled(true);
      final id = store.beginRequest(
        method: 'GET',
        url: '/api/v1/clients',
        headers: const {
          'X-API-Token': 'secret-token',
          'Authorization': 'Bearer xxx',
          'Accept': 'application/json',
        },
      );
      store.completeRequest(
        id,
        statusCode: 200,
        duration: Duration.zero,
        responseHeaders: const {'X-API-Secret': 'hidden'},
      );
      final entry = store.networkEntries.single;
      expect(entry.requestHeaders['X-API-Token'], '<redacted>');
      expect(entry.requestHeaders['Authorization'], '<redacted>');
      expect(entry.requestHeaders['Accept'], 'application/json');
      expect(entry.responseHeaders!['X-API-Secret'], '<redacted>');
    });

    test('bodies are redacted on store', () {
      final store = DebugCaptureStore()..setEnabled(true);
      final id = store.beginRequest(
        method: 'POST',
        url: '/api/v1/login',
        headers: const {},
        requestBody: '{"email":"a@b","password":"hunter2","token":"abc"}',
      );
      store.completeRequest(
        id,
        statusCode: 200,
        duration: Duration.zero,
        responseBody: '{"token":"deadbeef","data":{}}',
      );
      final entry = store.networkEntries.single;
      expect(entry.requestBody, contains('"<redacted>"'));
      expect(entry.requestBody, isNot(contains('hunter2')));
      expect(entry.requestBody, isNot(contains('"abc"')));
      expect(entry.responseBody, contains('"<redacted>"'));
      expect(entry.responseBody, isNot(contains('deadbeef')));
    });

    test('large bodies are truncated with a marker', () {
      final store = DebugCaptureStore()..setEnabled(true);
      final huge = 'x' * (40 * 1024); // 40 KB > 32 KB cap
      final id = store.beginRequest(
        method: 'POST',
        url: '/api/v1/upload',
        headers: const {},
        requestBody: huge,
      );
      store.completeRequest(
        id,
        statusCode: 200,
        duration: Duration.zero,
        responseBody: huge,
      );
      final entry = store.networkEntries.single;
      expect(entry.requestBody, contains('<truncated'));
      expect(entry.requestBody!.length, lessThan(huge.length));
      expect(entry.responseBody, contains('<truncated'));
    });

    test('network ring evicts oldest past capacity', () {
      final store = DebugCaptureStore()..setEnabled(true);
      for (var i = 0; i < 250; i++) {
        final id = store.beginRequest(
          method: 'GET',
          url: '/api/v1/clients?page=$i',
          headers: const {},
        );
        store.completeRequest(id, statusCode: 200, duration: Duration.zero);
      }
      expect(store.networkEntries, hasLength(200));
      // Newest-first: the latest request lives at index 0.
      expect(store.networkEntries.first.url, contains('page=249'));
      expect(store.networkEntries.last.url, contains('page=50'));
    });

    test('diagnostic ring evicts oldest past capacity', () {
      final store = DebugCaptureStore()..setEnabled(true);
      for (var i = 0; i < 250; i++) {
        store.recordError(StateError('err$i'), null);
      }
      expect(store.diagnosticEntries, hasLength(200));
      expect(store.diagnosticEntries.first.message, contains('err249'));
      expect(store.diagnosticEntries.last.message, contains('err50'));
    });

    test('recordLog captures level, logger name, error', () {
      final store = DebugCaptureStore()..setEnabled(true);
      store.recordLog(
        LogRecord(
          Level.WARNING,
          'something went wrong',
          'my.logger',
          Exception('inner'),
          StackTrace.fromString('#0 frame'),
        ),
      );
      final entry = store.diagnosticEntries.single;
      expect(entry.level, 'WARNING');
      expect(entry.loggerName, 'my.logger');
      expect(entry.message, contains('something went wrong'));
      expect(entry.message, contains('inner'));
      expect(entry.stack, contains('#0 frame'));
    });

    test('clear empties both rings and notifies', () {
      final store = DebugCaptureStore()..setEnabled(true);
      var notifications = 0;
      store.addListener(() => notifications++);
      final id = store.beginRequest(
        method: 'GET',
        url: '/api/v1/clients',
        headers: const {},
      );
      store.completeRequest(id, statusCode: 200, duration: Duration.zero);
      store.recordError(StateError('boom'), null);
      expect(store.networkEntries, isNotEmpty);
      expect(store.diagnosticEntries, isNotEmpty);
      final beforeClear = notifications;
      store.clear();
      expect(store.networkEntries, isEmpty);
      expect(store.diagnosticEntries, isEmpty);
      expect(notifications, greaterThan(beforeClear));
    });

    test('completeRequest with unknown id is a no-op', () {
      final store = DebugCaptureStore()..setEnabled(true);
      store.completeRequest(99999, statusCode: 200, duration: Duration.zero);
      expect(store.networkEntries, isEmpty);
    });
  });
}
