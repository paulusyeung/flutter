import 'package:flutter_test/flutter_test.dart';

import 'package:admin/domain/sync/mutation.dart';

/// `add_to_inventory` is a PO-specific custom action added to the outbox.
/// These guard the wire-string round-trip — the #1 failure mode is the
/// `wireName` switch's `_ => name` fallback silently serializing the kind as
/// the camelCase enum name (`addToInventory`), which then fails to parse back
/// out of a persisted outbox row.
void main() {
  group('MutationKind.addToInventory', () {
    test('serializes to snake_case, not the enum name', () {
      expect(MutationKind.addToInventory.wireName, 'add_to_inventory');
      expect(MutationKind.addToInventory.wireName, isNot('addToInventory'));
    });

    test('round-trips through tryParse', () {
      expect(
        MutationKind.tryParse('add_to_inventory'),
        MutationKind.addToInventory,
      );
    });
  });
}
