import 'package:admin/data/services/password_cache.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordCache TTL', () {
    test('read returns the password until the TTL expires', () {
      var now = DateTime(2026, 1, 1, 12, 0, 0);
      final cache = PasswordCache(
        ttl: const Duration(minutes: 5),
        now: () => now,
      );
      cache.set('hunter2');
      expect(cache.read(), 'hunter2');

      now = now.add(const Duration(minutes: 4, seconds: 59));
      expect(cache.read(), 'hunter2');

      now = now.add(const Duration(seconds: 2));
      expect(cache.read(), isNull);
    });

    test('clear wipes the password immediately', () {
      final cache = PasswordCache()..set('hunter2');
      expect(cache.read(), 'hunter2');
      cache.clear();
      expect(cache.read(), isNull);
    });
  });

  group('PasswordCacheLifecycleObserver', () {
    test('paused clears the cache', () {
      // Regression for H5: backgrounding the app should not leave the user's
      // password recoverable in memory for the full TTL.
      final cache = PasswordCache()..set('hunter2');
      final observer = PasswordCacheLifecycleObserver(cache);

      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(cache.read(), isNull);
    });

    test('detached clears the cache', () {
      final cache = PasswordCache()..set('hunter2');
      final observer = PasswordCacheLifecycleObserver(cache);

      observer.didChangeAppLifecycleState(AppLifecycleState.detached);
      expect(cache.read(), isNull);
    });

    test('inactive and resumed leave the cache untouched', () {
      // iOS fires `inactive` for transient events (notification center pull,
      // incoming call UI) — clearing there would force constant re-prompts.
      final cache = PasswordCache()..set('hunter2');
      final observer = PasswordCacheLifecycleObserver(cache);

      observer.didChangeAppLifecycleState(AppLifecycleState.inactive);
      expect(cache.read(), 'hunter2');

      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(cache.read(), 'hunter2');
    });
  });
}
