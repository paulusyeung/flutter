import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/search_focus_registry.dart';

void main() {
  group('SearchFocusRegistry', () {
    test('starts null', () {
      expect(SearchFocusRegistry().current, isNull);
    });

    test('stores and clears the active focus node', () {
      final registry = SearchFocusRegistry();
      final node = FocusNode();
      addTearDown(node.dispose);

      registry.current = node;
      expect(registry.current, same(node));

      registry.current = null;
      expect(registry.current, isNull);
    });
  });
}
