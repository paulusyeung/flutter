import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';
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

  static Future<void> archive({
    required BuildContext context,
    required String wireName,
    required Future<void> Function() op,
  }) => runMutationWithNotify(
    context,
    op,
    successMsg: context.tr('archived_$wireName'),
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

  static Future<void> delete({
    required BuildContext context,
    required String wireName,
    required Future<void> Function() op,
  }) => runMutationWithNotify(
    context,
    op,
    successMsg: context.tr('deleted_$wireName'),
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
}
