import 'package:flutter/material.dart';

import 'package:admin/domain/billing/invoice_lock.dart';
import 'package:admin/l10n/localization.dart';

/// Reason-specific "this invoice is locked" message dialog. Mirrors
/// admin-portal's `editEntity()` behaviour: instead of opening the editor on a
/// locked invoice we show *why* it's locked and never navigate. Shared by the
/// action-dispatch gate and the edit-screen entry guard so every entry point
/// (action menu, detail Edit button, list row menu, deep link) is consistent.
Future<void> showInvoiceLockedDialog(
  BuildContext context,
  InvoiceLockReason reason,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.tr('locked')),
      content: Text(context.tr(invoiceLockMessageKey(reason))),
      actions: [
        FilledButton(
          // Side-by-side / single dialog action needs an explicit minimumSize
          // (the FilledButton theme defaults to full-width) — see CLAUDE.md
          // § Design system.
          style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('close')),
        ),
      ],
    ),
  );
}
