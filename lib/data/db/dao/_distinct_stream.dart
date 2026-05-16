import 'package:collection/collection.dart';

/// Drift table watches are *table-grained*: any write to a table re-emits
/// every active query on that table even when the result set is
/// byte-identical (a write to another company, a filtered-out row, an
/// outbox-drain upsert that didn't touch a rendered field). Each spurious
/// emission then costs the repository a per-row `jsonDecode(payload)` in
/// `_fromRow` before the UI-layer guard in `GenericListViewModel` can drop
/// the no-op.
///
/// [distinctRows] collapses those identical re-emissions at the source.
/// Drift's generated row classes implement exhaustive value `==`/`hashCode`
/// over every column (including `payload`, `is_dirty`, `updated_at`), so
/// element-wise list equality here cannot swallow a real change — any
/// rendered field that differs makes the row unequal and the emission
/// passes through. The VM-side `listEquals` guard stays as defence in
/// depth; this just stops the expensive decode from running at all.
extension DistinctRowList<T> on Stream<List<T>> {
  Stream<List<T>> distinctRows() =>
      distinct((a, b) => const ListEquality<Object?>().equals(a, b));
}
