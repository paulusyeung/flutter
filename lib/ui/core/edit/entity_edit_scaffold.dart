import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/dialogs/discard_changes_dialog.dart';
import 'package:admin/ui/core/edit/generic_edit_view_model.dart';
import 'package:admin/ui/core/unsaved_changes/unsaved_changes_scope.dart';
import 'package:admin/ui/core/widgets/form_save_scope.dart';
import 'package:admin/ui/core/widgets/notify.dart';

/// Shared chrome for an entity edit / create screen.
///
/// Owns:
///   * The AppBar (title + Save button with a saving spinner).
///   * The `FormSaveScope` wiring so Enter inside any single-line field
///     submits the form.
///   * The `PopScope` + `UnsavedChangesScope` discard-confirmation guard.
///   * The post-save side effects: success toast → navigation; non-422
///     errors → SnackBar; 422 errors leave the screen open so inline
///     `errorText` on the fields can drive the fix.
///
/// Concrete screens pass:
///   * a [GenericEditViewModel] (`ClientEditViewModel`, …)
///   * [canSave] — usually `!vm.isSaving && (vm.isCreate ? name.notEmpty : vm.isDirty)`
///   * [titleBuilder] — entity-specific title (Create / Edit · displayName)
///   * [bodyBuilder]  — the form body (cards, fields)
///   * [resetToEmpty] — called by the discard guard when the user picks
///     Discard; concrete VMs implement this with their empty-draft factory
///   * [onSaved] — what to do after a successful save. Defaults to
///     `context.pop()` for edit mode, `context.go(detailRoute)` for create.
class EntityEditScaffold<T> extends StatelessWidget {
  const EntityEditScaffold({
    super.key,
    required this.vm,
    required this.canSave,
    required this.titleBuilder,
    required this.bodyBuilder,
    required this.resetToEmpty,
    required this.onSaved,
    this.onSaveRejected,
    this.topBanner,
  });

  final GenericEditViewModel<T> vm;
  final bool canSave;
  final String Function(BuildContext context) titleBuilder;
  final Widget Function(BuildContext context) bodyBuilder;
  final VoidCallback resetToEmpty;

  /// Invoked with the saved entity. Concrete screens decide whether to pop
  /// or go to a detail route. Awaited — async cleanup (e.g. deleting a
  /// prior dead outbox row before navigating away) is safe here.
  final FutureOr<void> Function(BuildContext context, T saved) onSaved;

  /// Invoked when [GenericEditViewModel.save] returns null with non-empty
  /// `fieldErrors` (i.e. the server has rejected the save — typically a
  /// 422). The screen uses this to re-fetch the dead outbox row id so the
  /// SaveFailedBanner's Discard button can act on the *fresh* failure,
  /// not a stale link from the prior load. Awaited.
  final FutureOr<void> Function()? onSaveRejected;

  /// Optional banner pinned between the AppBar and the form body. Used by
  /// `SaveFailedBanner` to surface a prior 422 across the whole form.
  /// Renders nothing on screens that don't pass one.
  final Widget? topBanner;

  Future<bool> _confirmDiscard(BuildContext context) async {
    if (!vm.isDirty) return true;
    return showDiscardChangesDialog(context);
  }

  Future<void> _onSave(BuildContext context) async {
    final result = await vm.save();
    if (!context.mounted) return;
    if (result == null) {
      // Non-422 errors land in submitError (422 lives on fieldErrors).
      if (vm.submitError != null) {
        Notify.error(
          context,
          context.tr('could_not_save'),
          detail: vm.submitError,
        );
      } else if (vm.fieldErrors.isNotEmpty) {
        // Server rejected validation — let the screen pick up the freshly
        // created dead outbox row so the banner's Discard action knows
        // which row to delete. Fire-and-await; screen handles its own
        // mounted check.
        await onSaveRejected?.call();
      }
      return;
    }
    Notify.success(context, context.tr('saved'));
    await onSaved(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesScope(
      isDirty: () => vm.isDirty,
      source: vm,
      onDiscard: resetToEmpty,
      child: PopScope(
        canPop: !vm.isDirty,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final shouldPop = await _confirmDiscard(context);
          if (!shouldPop) return;
          if (!context.mounted) return;
          context.pop();
        },
        child: ListenableBuilder(
          listenable: vm,
          builder: (context, _) {
            return Scaffold(
              appBar: AppBar(
                title: Text(titleBuilder(context)),
                actions: [
                  TextButton(
                    onPressed: canSave ? () => _onSave(context) : null,
                    child: vm.isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.tr('save')),
                  ),
                ],
              ),
              body: FormSaveScope(
                enabled: canSave,
                onSubmit: () => _onSave(context),
                child: topBanner == null
                    ? bodyBuilder(context)
                    : Column(
                        children: [
                          topBanner!,
                          Expanded(child: bodyBuilder(context)),
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
