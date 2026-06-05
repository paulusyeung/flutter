import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/shell/widgets/confirm_pending_outbox.dart';

/// Shared user-flow helpers for settings screens. Keeps the confirmation
/// dialogs / error snackbars consistent across the screens that expose
/// them — currently sign-out (`User Details`) and force-resync
/// (`Account Management → Overview`). Both are called from screens that
/// otherwise have no shared state, so static methods rather than a
/// ChangeNotifier are the right shape.
class SettingsActions {
  SettingsActions._();

  /// Show the sign-out confirmation dialog; if the user confirms, wipe the
  /// session (Drift + secure storage). Caller surfaces the loading state.
  ///
  /// Returns `true` when the user confirmed and the logout completed.
  static Future<bool> signOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('sign_out_question')),
        content: Text(ctx.tr('sign_out_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.tr('cancel')),
          ),
          FilledButton.tonal(
            autofocus: true,
            style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.tr('sign_out')),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return false;
    final services = context.read<Services>();
    // Warn about unsaved in-memory edits before wiping the session — mirrors
    // the company picker's sign-out guard. No-op (returns true) when nothing
    // is dirty.
    if (!await services.unsavedChangesGuard.confirmIfDirty(context)) {
      return false;
    }
    if (!context.mounted) return false;
    // Then quiesce the outbox for the active company so an unsynced offline
    // edit isn't silently dropped on logout — same guard the company picker
    // applies. (logout() settles in-flight requests but does NOT drain
    // still-pending rows before the Drift wipe, so without this they're lost.)
    final companyId = services.auth.session.value?.currentCompanyId;
    if (companyId != null) {
      final outbox = await confirmPendingOutboxIfAny(
        context,
        companyId: companyId,
      );
      if (outbox == OutboxConfirmResult.cancelled || !context.mounted) {
        return false;
      }
    }
    await services.auth.logout();
    return true;
  }

  /// Re-download every client for the active company. Used by the Account
  /// Management overview as a recovery path when the local cache feels
  /// stale; will grow as more entities become resync-capable.
  ///
  /// Reports success / failure via SnackBar. Caller surfaces the in-flight
  /// state — `await`ing this returns when the work is done (success or
  /// caught failure).
  static Future<void> forceResync(
    BuildContext context, {
    String successKey = 'resync_complete',
    String failureKey = 'resync_failed',
  }) async {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId;
    if (companyId == null) return;
    try {
      await services.clients.refreshAll(companyId: companyId, full: true);
      if (!context.mounted) return;
      Notify.success(context, context.tr(successKey));
    } catch (e) {
      if (!context.mounted) return;
      Notify.error(context, context.tr(failureKey), error: e);
    }
  }
}
