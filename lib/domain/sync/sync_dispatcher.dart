import 'package:admin/data/db/app_database.dart';
import 'package:admin/domain/sync/mutation.dart';

/// Per-entity dispatcher invoked by [SyncRepository] to send one outbox row.
///
/// The dispatcher knows how to (a) translate the outbox row's payload + kind
/// into a server call, and (b) write the canonical response back through the
/// owning repository (`applyCreateResponse`, `applyUpdateResponse`, etc.).
///
/// One dispatcher per [EntityType]; registered in `EntityRegistry`.
abstract class SyncDispatcher {
  Future<void> dispatch({required OutboxRow row, required MutationKind kind});

  /// Hard-delete the local record for a discarded never-synced offline
  /// `create` (see `SyncRepository.discardOutboxRow`). Only
  /// `BaseEntitySyncDispatcher` (the CRUD path that mints `tmp_` ids) does
  /// real work here; the user / company / settings / disabled dispatchers
  /// have no offline create-with-tmp-id flow, so a ghost create can never
  /// route through them and they implement this as a no-op.
  Future<void> deleteLocalRecord({
    required String companyId,
    required String id,
  });
}
