import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/saved_view.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';

/// Prompt the user to rename [view] and write the change through
/// `services.savedViews.rename`. Reused by the bookmark sheet's per-row
/// edit pencil and by the sidebar's hover-menu Rename action.
///
/// Shape matches every other "name + Cancel/Save" dialog in the app —
/// `AlertDialog` with side-by-side actions and the `Size(64, 44)` minimum
/// override required by the global FilledButton theme (CLAUDE.md).
Future<void> showRenameSavedViewDialog(
  BuildContext context,
  SavedView view,
) async {
  final controller = TextEditingController(text: view.name);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(ctx.tr('rename')),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(labelText: ctx.tr('view_name')),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(ctx.tr('save')),
          ),
        ],
      );
    },
  );
  controller.dispose();
  if (result == null || result.isEmpty || result == view.name) return;
  if (!context.mounted) return;
  final services = context.read<Services>();
  // Capture the messenger before await so the toast can still fire after
  // the host (sheet, sidebar item) unmounts.
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await services.savedViews.rename(viewId: view.id, newName: result);
    if (!context.mounted) return;
    Notify.success(context, context.tr('saved'), messenger: messenger);
  } catch (e) {
    if (!context.mounted) return;
    Notify.error(
      context,
      context.tr('could_not_save'),
      error: e,
      messenger: messenger,
    );
  }
}

/// Confirm + delete [view] via `services.savedViews.delete`. Reused by the
/// bookmark sheet's per-row trash icon and by the sidebar's hover-menu
/// Delete action.
Future<void> showDeleteSavedViewDialog(
  BuildContext context,
  SavedView view,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.tr('delete_view')),
      content: Text(ctx.tr('confirm_delete_view')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(ctx.tr('cancel')),
        ),
        FilledButton.tonal(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(ctx.tr('delete')),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final services = context.read<Services>();
  try {
    await services.savedViews.delete(view.id);
    if (!context.mounted) return;
    Notify.success(context, context.tr('view_deleted'), messenger: messenger);
  } catch (e) {
    if (!context.mounted) return;
    Notify.error(
      context,
      context.tr('could_not_save'),
      error: e,
      messenger: messenger,
    );
  }
}
