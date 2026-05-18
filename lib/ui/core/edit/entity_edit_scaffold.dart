import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/dialogs/discard_changes_dialog.dart';
import 'package:admin/ui/core/edit/generic_edit_view_model.dart';
import 'package:admin/ui/core/list/master_detail_layout.dart';
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
    this.embedded = false,
    this.actionsBuilder,
    this.saveParamFor,
    this.onAfterSaveAction,
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

  /// When `true`, the scaffold returns only its body — no outer
  /// `Scaffold`, no `AppBar`. The Save button moves to a thin header
  /// strip rendered above the form body. Used when this edit screen is
  /// hosted inside another container (e.g. the `MasterDetailLayout`
  /// right pane on wide desktop) so the parent's chrome isn't
  /// duplicated.
  final bool embedded;

  /// Builds the overflow entity-action bar shown next to Save in the
  /// AppBar (and the embedded / pane header strips). The per-entity caller
  /// owns the action enum `A`; it returns an `EntityOverflowActionBar<A>`
  /// and wires each item's `onTap` to the supplied type-erased sink. Null
  /// on screens that don't surface an action bar (back-compat default).
  final Widget Function(
    BuildContext context,
    void Function(Object action) onTap,
  )?
  actionsBuilder;

  /// Classifies an action as SAVE-PARAM. Non-null result => the action is
  /// performed *by* the save request via these query params (the server
  /// creates/updates and acts atomically). Null => AFTER-SAVE (save first,
  /// then run [onAfterSaveAction]). Null overall => every action is
  /// after-save (entities with no save-param actions omit this).
  final Map<String, String>? Function(Object action)? saveParamFor;

  /// Runs the entity's existing `<E>Actions.dispatch` for an AFTER-SAVE
  /// action against the freshly-saved (or, on the skip-redundant-save
  /// path, the unchanged) entity. The per-entity closure casts `action`
  /// back to its enum.
  final Future<void> Function(
    BuildContext context,
    T saved,
    Object action,
  )?
  onAfterSaveAction;

  Future<bool> _confirmDiscard(BuildContext context) async {
    if (!vm.isDirty) return true;
    return showDiscardChangesDialog(context);
  }

  /// Runs `vm.save()` and surfaces failures (non-422 SnackBar, 422
  /// dead-row re-link). Returns the saved entity on success, null on
  /// failure. Does **not** toast success or navigate — the caller decides
  /// (plain Save navigates via [onSaved]; an AFTER-SAVE action dispatches
  /// instead).
  Future<T?> _runSave(BuildContext context) async {
    final result = await vm.save();
    if (!context.mounted) return null;
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
      return null;
    }
    return result;
  }

  /// Plain Save (Save button / Enter / ⌘S) and the SAVE-PARAM action path:
  /// save, then on success toast + navigate via [onSaved]. For a SAVE-PARAM
  /// action the caller has already stashed the query on the VM, so the same
  /// save round-trip carries the action — nothing extra runs afterward.
  Future<void> _onSave(BuildContext context) async {
    final result = await _runSave(context);
    if (result == null || !context.mounted) return;
    Notify.success(context, context.tr('saved'));
    await onSaved(context, result);
  }

  /// Overflow action-bar tap. Three buckets (see plan / CLAUDE.md):
  ///   * SAVE-PARAM  — server performs it via the save request's query.
  ///   * AFTER-SAVE  — save first, then `<E>Actions.dispatch`.
  ///   * skip-save   — unchanged existing record + after-save action:
  ///                   dispatch directly, no redundant outbox row.
  Future<void> _onAction(BuildContext context, Object action) async {
    if (vm.isSaving) return;
    final query = saveParamFor?.call(action);

    if (query != null) {
      // SAVE-PARAM: the action *is* the change to persist, so it must not
      // require `isDirty` (some screens fold `isDirty` into `canSave` — a
      // mark-sent on an untouched existing record must still go through).
      // The `vm.isSaving` guard at the top of _onAction already covers the
      // busy case; in create mode still enforce the screen's create-validity
      // gate (e.g. invoice needs a client) since `canSave` carries it.
      if (vm.isCreate && !canSave) return;
      vm.setPendingSaveQuery(query);
      await _onSave(context);
      return;
    }

    // AFTER-SAVE / SECOND-REQUEST.
    final wasCreate = vm.isCreate;
    if (!wasCreate && !vm.isDirty) {
      // Skip-redundant-save: nothing to persist — dispatch straight away
      // (matches old admin-portal `isOld && !isChanged && isClientSide`).
      await onAfterSaveAction?.call(context, vm.draft, action);
      return;
    }
    // Must persist first; same validity gate as Save.
    if (!canSave) return;
    final saved = await _runSave(context);
    if (saved == null || !context.mounted) return;
    if (wasCreate) {
      // On create the entity only has a temp id; server-bound actions will
      // toast `sync_first` and return. Run the action (informative), then
      // leave create mode via the normal post-save navigation so a second
      // Save can't create a duplicate.
      await onAfterSaveAction?.call(context, saved, action);
      if (!context.mounted) return;
      Notify.success(context, context.tr('saved'));
      await onSaved(context, saved);
      return;
    }
    // Editing an existing record: real id — dispatch owns its own
    // toast/navigation (clone → go to new, email → sheet, …).
    await onAfterSaveAction?.call(context, saved, action);
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
            final saveLabel = context.tr('save');
            final isMac = defaultTargetPlatform == TargetPlatform.macOS;
            final shortcut = isMac ? '⌘S' : 'Ctrl+S';
            final saveButton = Tooltip(
              message: '$saveLabel ($shortcut)',
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, 44),
                ),
                onPressed: canSave ? () => _onSave(context) : null,
                // Reserve the button's resting width while saving so the
                // spinner swap doesn't visibly jitter the AppBar.
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 80),
                  alignment: Alignment.center,
                  child: vm.isSaving
                      ? const SizedBox(
                          width: 36,
                          height: 16,
                          child: Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : Text(saveLabel),
                ),
              ),
            );
            // Overflow entity-action bar (Email / Mark sent / Clone / …).
            // Built by the per-entity caller. It is wrapped in `Flexible` /
            // `Align` at each render site (never a fixed-width box) so the
            // embedded `OverflowView` receives the *actual* remaining width
            // and collapses extras into a "More" menu instead of overflowing
            // a narrow AppBar / slide-over pane.
            final actionsWidget = actionsBuilder?.call(
              context,
              (action) => _onAction(context, action),
            );
            final body = Shortcuts(
              shortcuts: const <ShortcutActivator, Intent>{
                SingleActivator(LogicalKeyboardKey.keyS, meta: true):
                    _SaveFormIntent(),
                SingleActivator(LogicalKeyboardKey.keyS, control: true):
                    _SaveFormIntent(),
              },
              child: Actions(
                actions: <Type, Action<Intent>>{
                  _SaveFormIntent: CallbackAction<_SaveFormIntent>(
                    onInvoke: (_) {
                      // Mirror the Save button — same gate, same handler.
                      // Pressing ⌘S while the form is invalid or already
                      // saving is a silent no-op.
                      if (canSave) _onSave(context);
                      return null;
                    },
                  ),
                },
                child: FormSaveScope(
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
              ),
            );
            // Embedded mode: no Scaffold / AppBar — render an inline
            // header strip with the title + Save button so the host
            // shell's chrome owns the window-level slots. Auto-detect
            // when mounted inside a master-detail right pane so
            // concrete screens never need to pass `embedded: true`.
            final inPane = MasterDetailPaneScope.isInPane(context);
            if (embedded || inPane) {
              // When mounted inside the slide-over pane, the layout
              // publishes its X + full-screen icons through the scope.
              // Render them at the trailing end of the header so they
              // share a row with Save instead of floating overlay on
              // top of it.
              final paneActions = MasterDetailPaneScope.paneActionsOf(
                context,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsetsDirectional.only(
                      start: 16,
                      end: 4,
                      top: 4,
                      bottom: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            titleBuilder(context),
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              saveButton,
                              if (actionsWidget != null) ...[
                                const SizedBox(width: 8),
                                Flexible(child: actionsWidget),
                              ],
                            ],
                          ),
                        ),
                        if (paneActions != null) ...[
                          const SizedBox(width: 8),
                          paneActions,
                        ],
                      ],
                    ),
                  ),
                  Expanded(child: body),
                ],
              );
            }
            return Scaffold(
              appBar: AppBar(
                titleSpacing: 16,
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        titleBuilder(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          saveButton,
                          if (actionsWidget != null) ...[
                            const SizedBox(width: 8),
                            Flexible(child: actionsWidget),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              body: body,
            );
          },
        ),
      ),
    );
  }
}

class _SaveFormIntent extends Intent {
  const _SaveFormIntent();
}
