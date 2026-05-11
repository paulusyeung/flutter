import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';

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
      title: Text(ctx.tr('unsynced_changes')),
      content: Text(
        ctx.tr(
          pending == 1
              ? 'unsynced_changes_body_singular'
              : 'unsynced_changes_body_plural',
          {'count': pending.toString()},
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(_Choice.cancel),
          child: Text(ctx.tr('cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(_Choice.discard),
          child: Text(ctx.tr('discard')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(_Choice.sync),
          child: Text(ctx.tr('sync_first')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('sync_failed_with_error', {'error': e.toString()}),
          ),
        ),
      );
    }
    return OutboxConfirmResult.cancelled;
  }
  // If the flush left rows behind (404s, validation errors marked dead, etc.)
  // proceed anyway — those are now in the `dead` state and won't block.
  return OutboxConfirmResult.proceed;
}

enum _Choice { cancel, discard, sync }
