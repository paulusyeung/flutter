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
}
