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

    test('publishRows installs actions and resets index when keys change', () {
      final c = FilterSuggestionController();
      var calls = 0;
      c.publishRows([() => calls++], ['k:a']);
      expect(c.rowCount, 1);
      expect(c.selectedIndex, 0);

      // Different keys, different length → reset.
      c.publishRows(
        [() => calls = 100, () => calls = 200, () => calls = 300],
        ['k:a', 'k:b', 'k:c'],
      );
      c.moveDown();
      expect(c.selectedIndex, 1);

      // Re-publishing the SAME keys with FRESH closures preserves the
      // index. The menu does this on every rebuild that doesn't change
      // the underlying row set (e.g. VM `notifyListeners` during a
      // network roundtrip); without this, the user couldn't settle a
      // highlight long enough to commit it.
      c.publishRows([() {}, () {}, () {}], ['k:a', 'k:b', 'k:c']);
      c.moveDown();
      expect(c.selectedIndex, 2);
      c.publishRows([() {}, () {}, () {}], ['k:a', 'k:b', 'k:c']);
      expect(c.selectedIndex, 2, reason: 'identical keys preserve index');

      // Same length but a key at any position differs → reset. The
      // user has highlighted row 2; typing a character prunes to a
      // different set of 3 rows; Enter should commit row 0 of the
      // new set, not row 2 of the stale set.
      c.publishRows([() {}, () {}, () {}], ['k:x', 'k:y', 'k:z']);
      expect(c.selectedIndex, 0, reason: 'any key change resets the highlight');

      // Different count → reset.
      c.publishRows([() {}], ['k:a']);
      expect(c.selectedIndex, 0);
    });

    test('moveDown wraps at end; moveUp wraps at start', () {
      final c = FilterSuggestionController();
      c.publishRows([() {}, () {}, () {}], ['a', 'b', 'c']);

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

    test('setSelectedIndex updates the highlight and notifies', () {
      final c = FilterSuggestionController();
      c.publishRows([() {}, () {}, () {}], ['a', 'b', 'c']);
      var notifyCount = 0;
      c.addListener(() => notifyCount++);

      c.setSelectedIndex(2);
      expect(c.selectedIndex, 2);
      expect(notifyCount, 1);

      // No notification when the index is unchanged.
      c.setSelectedIndex(2);
      expect(notifyCount, 1);
    });

    test('setSelectedIndex no-ops on out-of-range', () {
      final c = FilterSuggestionController();
      c.publishRows([() {}, () {}], ['a', 'b']);
      c.setSelectedIndex(5);
      expect(c.selectedIndex, 0, reason: 'out of range → ignored');
      c.setSelectedIndex(-1);
      expect(c.selectedIndex, 0, reason: 'negative → ignored');
    });

    test('commit fires the highlighted action and returns true', () {
      final c = FilterSuggestionController();
      final hits = <int>[];
      c.publishRows(
        [() => hits.add(0), () => hits.add(1), () => hits.add(2)],
        ['a', 'b', 'c'],
      );
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

      c.publishRows([() {}, () {}], ['a', 'b']);
      c.moveDown();
      c.moveUp();
      c.commit();
      expect(notifyCount, greaterThanOrEqualTo(3));
    });
  });
}
