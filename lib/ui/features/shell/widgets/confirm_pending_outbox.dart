import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';

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
  var pending = await services.sync.pendingCountFor(companyId);
  if (pending == 0) return OutboxConfirmResult.proceed;

  // Online happy path: try to drain silently. If everything goes through
  // we skip the dialog entirely — the warning was only useful when we had
  // unsynced changes the user was about to abandon. The drain itself is
  // best-effort; any rows left behind (offline, 422 marked dead, conflict
  // parked) fall through to the dialog so the user still gets a chance
  // to cancel / discard before leaving the company.
  if (await services.connectivity.isOnline) {
    try {
      await services.sync.flushNow(companyId: companyId);
    } catch (_) {
      // Fall through to the dialog — the user should see why the implicit
      // flush failed rather than have us silently swallow it.
    }
    pending = await services.sync.pendingCountFor(companyId);
    if (pending == 0) return OutboxConfirmResult.proceed;
  }

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
          autofocus: true,
          style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: () => Navigator.of(ctx).pop(_Choice.sync),
          child: Text(ctx.tr('sync_first_action')),
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

  // Sync first. Drain in a bounded loop rather than a single pass: an
  // offline-created parent + its dependent sync over CONSECUTIVE passes
  // (pass 1 dispatches the parent and re-arms the dependent — see
  // `OutboxDao.rewriteTempIdInPayloads` — pass 2 dispatches the dependent),
  // so a single `flushNow` + count check would cancel logout on a chain
  // that's actually healthy. Loop while the pending count keeps dropping;
  // stop as soon as a pass makes no progress (genuinely stuck: offline
  // backoff, conflict- or password-parked, or dead-referencing).
  var remaining = await services.sync.pendingCountFor(companyId);
  const maxPasses = 10; // backstop; real chains are 2-3 deep
  for (var pass = 0; pass < maxPasses && remaining > 0; pass++) {
    try {
      await services.sync.flushNow(companyId: companyId);
    } catch (e) {
      if (context.mounted) {
        Notify.error(context, context.tr('sync_failed'), error: e);
      }
      return OutboxConfirmResult.cancelled;
    }
    final next = await services.sync.pendingCountFor(companyId);
    if (next == 0) return OutboxConfirmResult.proceed;
    if (next >= remaining) break; // no progress this pass → stalled
    remaining = next;
  }
  // Rows still pending after the loop couldn't be sent (offline, parked, or
  // referencing a record that failed). Proceeding would let the post-logout
  // Drift wipe destroy them even though the user asked to sync, so cancel:
  // they can retry, resolve, or come back and pick "Discard". Dead rows
  // don't count here — they're terminal and surfaced on the Outbox screen.
  if (remaining > 0) {
    if (context.mounted) {
      Notify.error(context, context.tr('sync_failed'));
    }
    return OutboxConfirmResult.cancelled;
  }
  return OutboxConfirmResult.proceed;
}

enum _Choice { cancel, discard, sync }
