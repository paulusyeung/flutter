import 'package:flutter/widgets.dart';

import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/repositories/sync_repository.dart';

/// Triggers an outbox drain when the app returns to the foreground.
///
/// Without this, a mutation written while the app was backgrounded sits in
/// the outbox until the next user action triggers a drain. Combined with the
/// connectivity listener and the post-`enqueueMutation` hook, this closes
/// the last common gap where the user sees the "unsynced changes" dialog
/// despite having been online.
///
/// Mirrors [PasswordCacheLifecycleObserver]: the lifecycle hook is the only
/// state, the work itself is delegated to existing repositories.
class SyncLifecycleObserver with WidgetsBindingObserver {
  SyncLifecycleObserver({required this.auth, required this.sync});

  final AuthRepository auth;
  final SyncRepository sync;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final companyId = auth.session.value?.currentCompanyId;
    if (companyId == null || companyId.isEmpty) return;
    // Fire-and-forget: the row will retry on its own backoff if the drain
    // fails. We never want lifecycle callbacks to throw.
    sync.drainOnce(companyId: companyId);
  }
}
