import 'package:admin/ui/core/list/search/filter_suggestion_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Behavioral coverage for the keyboard-navigation controller shared
/// between `TokenSearchField` and `FilterSuggestionMenu`. These are pure
/// unit tests against a single ChangeNotifier — no widget tree involved.

void main() {
  group('FilterSuggestionController', () {
    test('starts empty: rowCount == 0, commit returns false', () {
      final c = FilterSuggestionController();
      expect(c.rowCount, 0);
      expect(c.commit(), isFalse);
    });

    test(
      'publishRows installs actions and resets index when count changes',
      () {
        final c = FilterSuggestionController();
        var calls = 0;
        c.publishRows([() => calls++]);
        expect(c.rowCount, 1);
        expect(c.selectedIndex, 0);

        // Mid-list selection survives a same-length publish.
        c.publishRows([
          () => calls = 100,
          () => calls = 200,
          () => calls = 300,
        ]);
        c.moveDown();
        expect(c.selectedIndex, 1);
        // Same count → index preserved.
        c.publishRows([() {}, () {}, () {}]);
        expect(c.selectedIndex, 1);

        // Different count → index resets to 0.
        c.publishRows([() {}]);
        expect(c.selectedIndex, 0);
      },
    );

    test('moveDown wraps at end; moveUp wraps at start', () {
      final c = FilterSuggestionController();
      c.publishRows([() {}, () {}, () {}]);

      c.moveDown();
      expect(c.selectedIndex, 1);
      c.moveDown();
      expect(c.selectedIndex, 2);
      c.moveDown();
      expect(c.selectedIndex, 0, reason: 'wraps past last → first');

      c.moveUp();
      expect(c.selectedIndex, 2, reason: 'wraps past first → last');
      c.moveUp();
      expect(c.selectedIndex, 1);
    });

    test('moveUp/moveDown are no-ops when empty', () {
      final c = FilterSuggestionController();
      c.moveDown();
      c.moveUp();
      expect(c.selectedIndex, 0);
      expect(c.rowCount, 0);
    });

    test('commit fires the highlighted action and returns true', () {
      final c = FilterSuggestionController();
      final hits = <int>[];
      c.publishRows([() => hits.add(0), () => hits.add(1), () => hits.add(2)]);
      c.moveDown();
      expect(c.commit(), isTrue);
      expect(hits, [1]);

      c.moveDown();
      expect(c.commit(), isTrue);
      expect(hits, [1, 2]);
    });

    test('notifies listeners on every state change', () {
      final c = FilterSuggestionController();
      var notifyCount = 0;
      c.addListener(() => notifyCount++);

      c.publishRows([() {}, () {}]);
      c.moveDown();
      c.moveUp();
      c.commit();
      expect(notifyCount, greaterThanOrEqualTo(3));
    });
  });
}
