import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';

/// Runs an async repo mutation and surfaces success / failure via
/// [Notify]. Shared between every per-entity `*Actions.dispatch` so the
/// archive / restore / delete arms don't reinvent the try-catch +
/// `context.mounted` dance per entity.
///
/// Callers pass the resolved success message (so locale + entity-specific
/// strings like `archived_client` stay at the call site). Failures show a
/// generic `could_not_save` snackbar with the formatted error as detail —
/// matching the inline pattern this replaces.
Future<void> runMutationWithNotify(
  BuildContext context,
  Future<void> Function() op, {
  required String successMsg,
}) async {
  try {
    await op();
    if (!context.mounted) return;
    Notify.success(context, successMsg);
  } catch (e) {
    if (!context.mounted) return;
    Notify.error(context, context.tr('could_not_save'), error: e);
  }
}
