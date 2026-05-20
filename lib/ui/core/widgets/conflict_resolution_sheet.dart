import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/domain/sync/sync_event.dart';
import 'package:admin/l10n/localization.dart';

/// Resolution chosen by the user when [showConflictResolutionSheet] returns.
///
/// The caller decides what each option means in concrete terms — the sheet
/// itself just collects the user's intent.
enum ConflictResolution {
  /// Keep the local row's pending changes, re-enqueue them as a fresh
  /// outbox mutation (the original parked row is discarded).
  useMine,

  /// Drop the local pending changes; the next sync pull will surface the
  /// server's version.
  discardMine,

  /// Open the entity's detail screen so the user can inspect the diff
  /// themselves before deciding.
  openEntity,

  /// User dismissed the sheet without choosing. Caller should leave the
  /// outbox row parked for now and prompt again on the next event.
  none,
}

/// Modal sheet shown when [SyncRepository] emits a [ConflictEvent] (HTTP
/// 409). Offers three resolution paths plus dismiss. The sheet doesn't
/// touch the outbox or the database — the caller wires the choice to
/// `repo.save(...)`/`discardPendingFor(...)`/`context.go(...)`.
Future<ConflictResolution> showConflictResolutionSheet(
  BuildContext context, {
  required ConflictEvent event,
}) async {
  final result = await showDialog<ConflictResolution>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final tokens = ctx.inTheme;
      return AlertDialog(
        title: Text(ctx.tr('conflict_detected_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ctx.tr('conflict_detected_message'),
              style: TextStyle(color: tokens.ink2),
            ),
            if (event.message.isNotEmpty) ...[
              const SizedBox(height: InSpacing.sm),
              Text(
                event.message,
                style: TextStyle(color: tokens.ink3, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(ConflictResolution.openEntity),
            child: Text(ctx.tr('open_entity')),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
            onPressed: () =>
                Navigator.of(ctx).pop(ConflictResolution.discardMine),
            child: Text(ctx.tr('discard_my_changes')),
          ),
          FilledButton(
            autofocus: true,
            style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () => Navigator.of(ctx).pop(ConflictResolution.useMine),
            child: Text(ctx.tr('use_my_changes')),
          ),
        ],
      );
    },
  );
  return result ?? ConflictResolution.none;
}
