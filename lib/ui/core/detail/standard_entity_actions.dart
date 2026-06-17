import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/core/widgets/notify_async.dart';

/// Standard repo-backed action dispatchers — archive / restore / delete /
/// purge. Each entity's `<Entity>Actions.dispatch()` calls these for the
/// universal mutations so it doesn't reimplement the
/// `runMutationWithNotify(...)` + `context.tr('archived_$entity')` dance
/// per case.
///
/// The success-message key follows the convention enforced by
/// `test/l10n/entity_translation_completeness_test.dart`: the caller
/// supplies the entity's `wireName` (e.g. `'client'`, `'product'`) and the
/// helper resolves to `archived_<wireName>` etc.
class StandardEntityActions {
  StandardEntityActions._();

  /// Archive [op]; when [undoOp] (the matching restore) is supplied the
  /// success toast offers an **Undo** that runs it. Archive ⇄ restore is a
  /// clean reversal — the FIFO outbox nets the two mutations out.
  static Future<void> archive({
    required BuildContext context,
    required String wireName,
    required Future<void> Function() op,
    Future<void> Function()? undoOp,
  }) => runMutationWithNotify(
    context,
    op,
    successMsg: context.tr('archived_$wireName'),
    successAction: _undoAction(context, wireName, undoOp),
  );

  static Future<void> restore({
    required BuildContext context,
    required String wireName,
    required Future<void> Function() op,
  }) => runMutationWithNotify(
    context,
    op,
    successMsg: context.tr('restored_$wireName'),
  );

  /// Delete [op]; when [undoOp] (the matching restore) is supplied the success
  /// toast offers an **Undo**. (Server delete is soft, so restore reverses it.)
  static Future<void> delete({
    required BuildContext context,
    required String wireName,
    required Future<void> Function() op,
    Future<void> Function()? undoOp,
  }) => runMutationWithNotify(
    context,
    op,
    successMsg: context.tr('deleted_$wireName'),
    successAction: _undoAction(context, wireName, undoOp),
  );

  static Future<void> purge({
    required BuildContext context,
    required String wireName,
    required Future<void> Function() op,
  }) => runMutationWithNotify(
    context,
    op,
    successMsg: context.tr('purged_$wireName'),
  );

  /// Build the Undo action for an archive/delete success toast. Tapping it runs
  /// [undoOp] (the restore) with its own success/failure feedback. The label +
  /// "restored" message are resolved eagerly so the callback never touches a
  /// possibly-stale `context` for localization.
  static NotifyAction? _undoAction(
    BuildContext context,
    String wireName,
    Future<void> Function()? undoOp,
  ) {
    if (undoOp == null) return null;
    final restoredMsg = context.tr('restored_$wireName');
    return NotifyAction(
      context.tr('undo'),
      () => runMutationWithNotify(context, undoOp, successMsg: restoredMsg),
    );
  }
}
