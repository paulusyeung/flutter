import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/domain/sync/sync_event.dart';
import 'package:admin/ui/core/widgets/confirm_password_sheet.dart';
import 'package:admin/ui/core/widgets/conflict_resolution_sheet.dart';

final _log = Logger('SyncEventListener');

/// Wraps the shell's subtree and listens to `services.sync.events`. When a
/// [PasswordRequiredEvent] arrives, opens [ConfirmPasswordSheet]; when a
/// [ConflictEvent] arrives, opens [ConflictResolutionSheet] and routes the
/// user's choice to the appropriate repo action.
///
/// One listener per app — install once at the top of the authenticated
/// shell. Multiple instances would race to show duplicate dialogs.
class SyncEventListener extends StatefulWidget {
  const SyncEventListener({required this.child, super.key});

  final Widget child;

  @override
  State<SyncEventListener> createState() => _SyncEventListenerState();
}

class _SyncEventListenerState extends State<SyncEventListener> {
  StreamSubscription<SyncEvent>? _sub;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    // Subscribe in `didChangeDependencies` so `context.read<Services>()` is
    // available. `initState` runs before the Provider lookup is safe.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sub ??= context.read<Services>().sync.events.listen(_onEvent);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _onEvent(SyncEvent event) async {
    if (!mounted) return;
    // Suppress overlapping dialogs — the sync engine will re-emit on the
    // next attempt if the user dismisses without resolving. Without this
    // a flurry of failed rows would stack N dialogs.
    if (_dialogOpen) return;

    switch (event) {
      case PasswordRequiredEvent():
        await _handlePasswordRequired();
      case ConflictEvent():
        await _handleConflict(event);
      case ValidationFailedEvent():
      case DeadEvent():
        // These don't currently open a dialog — the Outbox screen surfaces
        // them passively. Future: badge on the sync icon.
        break;
    }
  }

  Future<void> _handlePasswordRequired() async {
    _dialogOpen = true;
    try {
      final services = context.read<Services>();
      final ok = await showConfirmPasswordSheet(
        context,
        cache: services.passwordCache,
      );
      if (!ok || !mounted) return;
      // Re-kick the drain so the parked outbox row retries immediately
      // with the freshly-populated password cache.
      final companyId = services.auth.session.value?.currentCompanyId;
      if (companyId != null) {
        unawaited(services.sync.drainOnce(companyId: companyId));
      }
    } finally {
      _dialogOpen = false;
    }
  }

  Future<void> _handleConflict(ConflictEvent event) async {
    _dialogOpen = true;
    try {
      final services = context.read<Services>();
      final companyId = services.auth.session.value?.currentCompanyId;
      final choice = await showConflictResolutionSheet(context, event: event);
      if (!mounted) return;
      switch (choice) {
        case ConflictResolution.openEntity:
          // Route to the entity's detail screen. The registry knows the
          // base path; we append the id.
          final handlers = services.entityRegistry[event.entityType];
          if (handlers != null) {
            context.go('${handlers.routePath}/${event.entityId}');
          }
        case ConflictResolution.discardMine:
          if (companyId == null) return;
          // Drop every non-dead outbox row for the company — coarse, but
          // matches what the user just asked for ("discard mine"). M2 may
          // narrow to discarding only the conflicted row's mutations.
          await services.sync.discardPendingFor(companyId);
        case ConflictResolution.useMine:
          // Re-enqueue happens implicitly: a subsequent `repo.save(...)`
          // from the detail screen will write a fresh outbox row. We
          // route the user there so they can hit Save.
          final handlers = services.entityRegistry[event.entityType];
          if (handlers != null) {
            context.go('${handlers.routePath}/${event.entityId}/edit');
          }
        case ConflictResolution.none:
          // Dismissed — leave the row parked.
          break;
      }
    } catch (e, st) {
      _log.warning('Conflict resolution failed', e, st);
    } finally {
      _dialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
