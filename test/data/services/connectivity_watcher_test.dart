import 'package:admin/data/services/connectivity_watcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConnectivityWatcher.fixed', () {
    test('isOnline reflects the construction arg', () async {
      expect(await ConnectivityWatcher.fixed(online: true).isOnline, isTrue);
      expect(await ConnectivityWatcher.fixed(online: false).isOnline, isFalse);
    });

    test('onOnline emits nothing — the fake never transitions', () async {
      // A 50ms window is plenty for `Stream.empty()` to deliver a `done`
      // event; we just want to confirm no value events ever arrive.
      final events = <void>[];
      final sub = ConnectivityWatcher.fixed(
        online: true,
      ).onOnline.listen(events.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      expect(events, isEmpty);
    });
  });
}
