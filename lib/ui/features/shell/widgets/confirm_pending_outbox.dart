import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';

/// Result of the confirm-before-switch / confirm-before-logout flow.
enum OutboxConfirmResult { proceed, cancelled }

/// CLAUDE.md rule: "Logout / company-switch with pending non-dead outbox
/// rows prompts the user (sync now / discard / cancel). Never silently
/// drops user data." This helper centralises that prompt.
///
/// Returns [OutboxConfirmResult.proceed] when:
///   * there were no pending rows to start with,
///   * the user picked "Sync first" and the flush succeeded,
///   * the user picked "Discard" and the rows were deleted.
/// Returns [OutboxConfirmResult.cancelled] otherwise — including when the
/// flush errors out and the user is sent back to the prompt via a SnackBar.
Future<OutboxConfirmResult> confirmPendingOutboxIfAny(
  BuildContext context, {
  required String companyId,
}) async {
  final services = context.read<Services>();
  final pending = await services.sync.pendingCountFor(companyId);
  if (pending == 0) return OutboxConfirmResult.proceed;
  if (!context.mounted) return OutboxConfirmResult.cancelled;

  final choice = await showDialog<_Choice>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Unsynced changes'),
      content: Text(
        'You have $pending unsynced ${pending == 1 ? 'change' : 'changes'} on '
        'this workspace. Sync them before switching, discard them, or cancel.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(_Choice.cancel),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(_Choice.discard),
          child: const Text('Discard'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(_Choice.sync),
          child: const Text('Sync first'),
        ),
      ],
    ),
  );

  if (choice == null || choice == _Choice.cancel) {
    return OutboxConfirmResult.cancelled;
  }

  if (choice == _Choice.discard) {
    await services.sync.discardPendingFor(companyId);
    return OutboxConfirmResult.proceed;
  }

  // Sync first.
  try {
    await services.sync.flushNow(companyId: companyId);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
    }
    return OutboxConfirmResult.cancelled;
  }
  // If the flush left rows behind (404s, validation errors marked dead, etc.)
  // proceed anyway — those are now in the `dead` state and won't block.
  return OutboxConfirmResult.proceed;
}

enum _Choice { cancel, discard, sync }
