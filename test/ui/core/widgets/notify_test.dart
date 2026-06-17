import 'package:flutter_test/flutter_test.dart';

import 'package:admin/ui/core/widgets/notify.dart';

// The toast *rendering* behavior (stacking, close button, hover-pause, swipe,
// layering) is covered by `toast_host_test.dart` driving the controller +
// host directly; the `Notify.* → ToastController` routing is exercised
// end-to-end by `settings_actions_test.dart` (forceResync → toast). This file
// keeps the pure `formatNotifyError` unit tests.
void main() {
  group('formatNotifyError', () {
    test('strips Exception prefix', () {
      expect(formatNotifyError(Exception('boom')), 'boom');
    });

    test('strips a custom *Exception type-name prefix', () {
      expect(
        formatNotifyError(_FakeNamedException('lookup failed')),
        'lookup failed',
      );
    });

    test('leaves plain strings untouched', () {
      expect(formatNotifyError('plain'), 'plain');
    });
  });
}

class _FakeNamedException implements Exception {
  _FakeNamedException(this.message);
  final String message;

  @override
  String toString() => 'SocketException: $message';
}
