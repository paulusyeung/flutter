import 'package:admin/app/onboarding_controller.dart';
import 'package:admin/data/services/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OnboardingController', () {
    test('fresh install → completed=false (nothing persisted)', () async {
      final c = OnboardingController(storage: InMemoryTokenStorage());
      expect(c.completed, isFalse);
      await c.restore();
      expect(c.completed, isFalse);
    });

    test('markCompleted persists; a new controller restores it', () async {
      final storage = InMemoryTokenStorage();
      final c1 = OnboardingController(storage: storage);
      var notified = 0;
      c1.addListener(() => notified++);

      await c1.markCompleted();
      expect(c1.completed, isTrue);
      expect(notified, 1);
      // Idempotent — no second notify.
      await c1.markCompleted();
      expect(notified, 1);

      final c2 = OnboardingController(storage: storage);
      expect(c2.completed, isFalse, reason: 'not restored yet');
      await c2.restore();
      expect(c2.completed, isTrue, reason: 'flag survived via storage');
    });

    test('reset re-arms the tour and persists false', () async {
      final storage = InMemoryTokenStorage();
      final c = OnboardingController(storage: storage);
      await c.markCompleted();
      expect(c.completed, isTrue);

      await c.reset();
      expect(c.completed, isFalse);

      final fresh = OnboardingController(storage: storage);
      await fresh.restore();
      expect(fresh.completed, isFalse, reason: 'reset persisted');
    });
  });
}
