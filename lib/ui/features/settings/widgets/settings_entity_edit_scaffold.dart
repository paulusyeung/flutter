import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/generic_edit_view_model.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/core/dialogs/discard_changes_dialog.dart';
import 'package:admin/ui/core/unsaved_changes/unsaved_changes_scope.dart';
import 'package:admin/ui/core/widgets/form_save_scope.dart';
import 'package:admin/ui/features/settings/widgets/settings_entity_overflow_menu.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';

/// Shared chrome for a single-entity settings edit/create screen
/// (payment_terms, task_statuses, group_settings, …). Owns the entire
/// load → vm-build → save lifecycle so each per-entity screen only
/// declares its [bodyBuilder] + [canSave] gate + the closures that bind
/// the scaffold to that entity's repo.
///
/// Lifecycle:
/// 1. `initState` — if [existingId] is null, build a fresh-create VM via
///    [vmFactory]. Otherwise call [watchById] and take the first emission;
///    on `null` (deep-link before Drift has the row), fire [refreshAll]
///    and retry once before declaring `not_found`.
/// 2. `build` — render the standard AppBar (overflow + Save) and wrap the
///    [bodyBuilder] in `FormSaveScope` + `SettingsFormShell`.
/// 3. Save — call `vm.save()`; on success `pop` to [backRoute].
class SettingsEntityEditScaffold<T, VM extends GenericEditViewModel<T>>
    extends StatefulWidget {
  const SettingsEntityEditScaffold({
    super.key,
    required this.existingId,
    required this.backRoute,
    required this.createTitleKey,
    required this.editTitleKey,
    required this.wireName,
    required this.watchById,
    required this.refreshAll,
    required this.onArchive,
    required this.onRestore,
    required this.onDelete,
    required this.vmFactory,
    required this.canSave,
    this.bodyBuilder,
    this.customBodyBuilder,
    this.guardUnsavedChanges = false,
    this.onDiscard,
    required this.isArchivedOf,
    required this.isDeletedOf,
  }) : assert(
         (bodyBuilder == null) != (customBodyBuilder == null),
         'Provide exactly one of bodyBuilder or customBodyBuilder.',
       );

  /// Null in create mode, entity id in edit mode.
  final String? existingId;

  /// Path to send the user back to on save or "not_found" — e.g.
  /// `'/settings/payment_terms'`.
  final String backRoute;

  /// Localization keys for the AppBar title in create / edit modes.
  final String createTitleKey;
  final String editTitleKey;

  /// Entity slug used for archive/restore/delete toasts. See
  /// [SettingsEntityOverflowMenu].
  final String wireName;

  /// Read a single entity by id. Implemented by callers as
  /// `(id) => services.<repo>.watch(companyId: companyId, id: id)`.
  final Stream<T?> Function(String id) watchById;

  /// Refresh the repo from the server. Used as the retry hook when a
  /// deep-link lands on an id Drift hasn't seen yet.
  final Future<void> Function() refreshAll;

  /// Archive / Restore / Delete operations bound to the entity id.
  final Future<void> Function(String id) onArchive;
  final Future<void> Function(String id) onRestore;
  final Future<void> Function(String id) onDelete;

  /// Build the ViewModel for the create or edit screen. `existing` is null
  /// on create.
  final VM Function({T? existing}) vmFactory;

  /// Save-button gate, evaluated on every `Consumer<VM>` rebuild. Typical
  /// shape: `!vm.isSaving && vm.isDirty && vm.draft.name.trim().isNotEmpty`.
  final bool Function(VM) canSave;

  /// Form body. Rendered inside `FormSaveScope` + `SettingsFormShell` so
  /// callers just declare their `FormSection`s and fields. Returns a list
  /// of sections — most screens emit a single section, but tax_rates +
  /// designs likely want a primary card plus a secondary "Advanced" card.
  /// Mutually exclusive with [customBodyBuilder].
  final List<Widget> Function(BuildContext, VM)? bodyBuilder;

  /// Opt-out of the 720 px `SettingsFormShell` cap. When set, the scaffold
  /// renders this widget full-width inside `FormSaveScope` only — no
  /// `SettingsFormShell`. Used by screens that own their own layout (e.g.
  /// the Custom Design editor's editor + live-preview two-pane, which must
  /// stretch past 720 px on a wide window). Mutually exclusive with
  /// [bodyBuilder].
  final Widget Function(BuildContext, VM)? customBodyBuilder;

  /// Opt-in confirm-on-pop guard. When true the screen wraps in
  /// `UnsavedChangesScope` + `PopScope` so a back / system-back with
  /// `vm.isDirty` prompts the standard discard dialog before leaving. Off by
  /// default so existing settings-entity screens (reached via the sidebar,
  /// which routes through the shell's own guard) are unaffected. Turn it on
  /// for screens pushed as a bare `MaterialPageRoute` (no shell guard).
  final bool guardUnsavedChanges;

  /// Resets the draft to its last-saved state. Required when
  /// [guardUnsavedChanges] is true — the discard dialog calls it so picked
  /// "Discard" doesn't leave stale edits behind on a preserved route.
  final void Function(VM)? onDiscard;

  /// Lifecycle accessors on `T`. The scaffold uses them to decide which
  /// overflow-menu items to show. Wired by callers as
  /// `(t) => t.archivedAt != null` / `(t) => t.isDeleted`.
  final bool Function(T) isArchivedOf;
  final bool Function(T) isDeletedOf;

  @override
  State<SettingsEntityEditScaffold<T, VM>> createState() =>
      _SettingsEntityEditScaffoldState<T, VM>();
}

class _SettingsEntityEditScaffoldState<T, VM extends GenericEditViewModel<T>>
    extends State<SettingsEntityEditScaffold<T, VM>> {
  VM? _vm;
  bool _loading = true;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.existingId == null) {
      setState(() {
        _vm = widget.vmFactory();
        _loading = false;
      });
      return;
    }
    try {
      var existing = await widget.watchById(widget.existingId!).first;
      if (existing == null) {
        // Deep link with a fresh local cache — retry once after a server
        // refresh before declaring "not found." Mirrors the trick each
        // hand-rolled edit screen used to carry inline.
        await widget.refreshAll();
        if (!mounted) return;
        existing = await widget.watchById(widget.existingId!).first;
      }
      if (!mounted) return;
      if (existing == null) {
        setState(() {
          _loadError = 'not_found';
          _loading = false;
        });
        return;
      }
      setState(() {
        _vm = widget.vmFactory(existing: existing);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  Future<void> _onSave() async {
    final vm = _vm;
    if (vm == null) return;
    final saved = await vm.save();
    if (saved == null || !mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(widget.backRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.existingId == null;
    final titleKey = isCreate ? widget.createTitleKey : widget.editTitleKey;

    if (_loading) {
      return SettingsScreenScaffold(
        titleKey: titleKey,
        leading: const BackButton(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null || _vm == null) {
      return SettingsScreenScaffold(
        titleKey: titleKey,
        leading: const BackButton(),
        body: EmptyState(
          icon: Icons.error_outline,
          title: context.tr('not_found'),
          action: FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () => context.go(widget.backRoute),
            child: Text(context.tr('back')),
          ),
        ),
      );
    }

    return ChangeNotifierProvider<VM>.value(
      value: _vm!,
      child: Consumer<VM>(
        builder: (context, vm, _) {
          final canSave = widget.canSave(vm);
          final body = FormSaveScope(
            onSubmit: _onSave,
            enabled: canSave,
            child: widget.customBodyBuilder != null
                ? widget.customBodyBuilder!(context, vm)
                : SettingsFormShell(
                    sections: widget.bodyBuilder!(context, vm),
                  ),
          );
          final scaffold = SettingsScreenScaffold(
            titleKey: titleKey,
            leading: const BackButton(),
            actions: [
              if (!isCreate)
                SettingsEntityOverflowMenu(
                  isArchived: widget.isArchivedOf(vm.draft),
                  isDeleted: widget.isDeletedOf(vm.draft),
                  wireName: widget.wireName,
                  onArchive: () => widget.onArchive(widget.existingId!),
                  onRestore: () => widget.onRestore(widget.existingId!),
                  onDelete: () => widget.onDelete(widget.existingId!),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 36),
                  ),
                  onPressed: canSave ? _onSave : null,
                  child: vm.isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.tr('save')),
                ),
              ),
            ],
            body: body,
          );
          if (!widget.guardUnsavedChanges) return scaffold;
          return UnsavedChangesScope(
            isDirty: () => vm.isDirty,
            source: vm,
            onDiscard: () => widget.onDiscard?.call(vm),
            child: PopScope(
              canPop: !vm.isDirty,
              onPopInvokedWithResult: (didPop, _) async {
                if (didPop) return;
                final shouldPop = await showDiscardChangesDialog(context);
                if (!shouldPop || !context.mounted) return;
                widget.onDiscard?.call(vm);
                Navigator.of(context).pop();
              },
              child: scaffold,
            ),
          );
        },
      ),
    );
  }
}
