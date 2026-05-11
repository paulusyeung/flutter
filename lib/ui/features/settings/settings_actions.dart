import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';

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
        title: const Text('Sign out?'),
        content: const Text(
          'Your locally cached data will be cleared. Any unsynced edits '
          'should be synced first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return false;
    await context.read<Services>().auth.logout();
    return true;
  }

  /// Re-download every client for the active company. Used by the Account
  /// Management overview as a recovery path when the local cache feels
  /// stale; will grow as more entities become resync-capable.
  ///
  /// Reports success / failure via SnackBar. Caller surfaces the in-flight
  /// state — `await`ing this returns when the work is done (success or
  /// caught failure).
  static Future<void> forceResync(BuildContext context) async {
    final services = context.read<Services>();
    final messenger = ScaffoldMessenger.of(context);
    final companyId = services.auth.session.value?.currentCompanyId;
    if (companyId == null) return;
    try {
      await services.clients.refreshAll(companyId: companyId, full: true);
      if (!context.mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Resync complete')));
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Resync failed: $e')));
    }
  }
}
