import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';

/// Two-step purge confirmation. Returns true when the user taps Continue;
/// the caller then enqueues the purge mutation (which goes through the
/// outbox and triggers `ConfirmPasswordSheet` on drain). Matches the
/// React app's PurgeClientAction flow: warning modal first, password
/// prompt second.
Future<bool> showPurgeClientDialog(
  BuildContext context, {
  required String displayName,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.tr('purge_client')),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(displayName, style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(ctx.tr('purge_client_warning')),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(ctx.tr('cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(ctx.tr('continue')),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
