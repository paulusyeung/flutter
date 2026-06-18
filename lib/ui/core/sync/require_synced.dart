import 'package:flutter/widgets.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';

/// Guards a server-bound action against an offline-created record that hasn't
/// synced yet. Returns `true` when [id] is a real server id (safe to proceed);
/// returns `false` — after showing the shared "sync first" toast — when [id] is
/// still a local `tmp_<uuid>` placeholder. Use as an early bail:
///
/// ```dart
/// if (!requireSynced(context, client.id)) return;
/// ```
///
/// Consolidates the `if (id.startsWith('tmp_')) { Notify.error(..., 'sync_first')
/// ; return; }` block that was copy-pasted across ~60 action call sites, so the
/// detection + wording live in one place. Detail/edit screens additionally
/// surface a persistent `SyncFirstBanner`; this toast is the fallback for the
/// contexts a banner can't reach (list-row popups, cross-entity actions).
bool requireSynced(BuildContext context, String id) {
  if (!isUnsynced(id)) return true;
  Notify.error(context, context.tr('sync_first'));
  return false;
}

/// True when [id] is a local `tmp_<uuid>` placeholder from an offline create
/// that hasn't round-tripped to the server yet (where `id_remap` swaps in the
/// real id). The single source of truth for the "is this record synced?" check.
bool isUnsynced(String id) => id.startsWith('tmp_');
