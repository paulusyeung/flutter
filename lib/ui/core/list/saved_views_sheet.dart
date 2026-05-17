import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/saved_view.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/saved_view_dialogs.dart';
import 'package:admin/ui/core/list/saved_view_icons.dart';
import 'package:admin/ui/core/widgets/form_save_scope.dart';
import 'package:admin/ui/core/widgets/notify.dart';

/// Bottom-sheet body for managing saved views on a list screen. Owns:
///   * a name input + Save action (creates a new view from the VM's current
///     filter+sort+search+columns state — captured via
///     [GenericListViewModel.savedViewSnapshot]);
///   * a list of existing views for this `(companyId, entityType)` with
///     per-row apply / update-with-current / rename / delete actions.
///
/// Apply does not toast — the visible filter chips re-rendering is enough
/// feedback, and a toast on every tap reads as noise. Save / update / delete
/// do toast (mutations the user might want to second-guess).
class SavedViewsSheet<T> extends StatefulWidget {
  const SavedViewsSheet({required this.vm, super.key});

  final GenericListViewModel<T> vm;

  @override
  State<SavedViewsSheet<T>> createState() => _SavedViewsSheetState<T>();
}

class _SavedViewsSheetState<T> extends State<SavedViewsSheet<T>> {
  final TextEditingController _name = TextEditingController();
  String? _iconKey;
  bool _saving = false;
  late String _initialCompanyId;
  AuthRepository? _auth;

  @override
  void initState() {
    super.initState();
    _initialCompanyId = widget.vm.companyId;
    _name.addListener(_rebuild);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen to session changes so a company switch made via the picker
    // (which is reachable while this sheet is open) dismisses us before we
    // can write a row keyed to the wrong company.
    final auth = context.read<Services>().auth;
    if (_auth != auth) {
      _auth?.session.removeListener(_onSession);
      _auth = auth;
      auth.session.addListener(_onSession);
    }
  }

  void _onSession() {
    final current = _auth?.session.value?.currentCompanyId;
    if (current != null && current != _initialCompanyId && mounted) {
      Navigator.of(context).maybePop();
    }
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _auth?.session.removeListener(_onSession);
    _name.removeListener(_rebuild);
    _name.dispose();
    super.dispose();
  }

  bool get _canSave => _name.text.trim().isNotEmpty && !_saving;

  Future<void> _save() async {
    if (!_canSave) return;
    final services = context.read<Services>();
    final name = _name.text.trim();
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await services.savedViews.create(
        companyId: widget.vm.companyId,
        entityType: widget.vm.entityType,
        name: name,
        snapshot: widget.vm.savedViewSnapshot(),
        iconKey: _iconKey,
      );
      if (!mounted) return;
      _name.clear();
      setState(() => _iconKey = null);
      Notify.success(context, context.tr('view_saved'), messenger: messenger);
    } catch (e) {
      if (!mounted) return;
      Notify.error(
        context,
        context.tr('could_not_save'),
        error: e,
        messenger: messenger,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickCreateIcon() async {
    final choice = await showSavedViewIconPicker(context, current: _iconKey);
    if (choice == null || !mounted) return;
    setState(() => _iconKey = choice.key);
  }

  Future<void> _apply(SavedView view) async {
    final services = context.read<Services>();
    final navigator = Navigator.of(context);
    try {
      await services.savedViews.apply(view.id);
      if (!mounted) return;
      unawaited(navigator.maybePop());
    } catch (e) {
      if (!mounted) return;
      Notify.error(context, context.tr('could_not_save'), error: e);
    }
  }

  Future<void> _update(SavedView view) async {
    // No confirm dialog — the user just clicked the refresh icon next to a
    // specific row, intent is unambiguous. Mistakes are recoverable via the
    // Undo action on the success toast.
    final services = context.read<Services>();
    final messenger = ScaffoldMessenger.maybeOf(context);
    final previous = view.snapshot;
    try {
      await services.savedViews.updateSnapshot(
        viewId: view.id,
        snapshot: widget.vm.savedViewSnapshot(),
      );
      if (!mounted) return;
      Notify.success(
        context,
        context.tr('view_updated'),
        messenger: messenger,
        action: NotifyAction(context.tr('undo'), () {
          // Best-effort restore — if the view has been deleted in the
          // meantime, updateSnapshot is a no-op against the missing id.
          unawaited(
            services.savedViews.updateSnapshot(
              viewId: view.id,
              snapshot: previous,
            ),
          );
        }),
      );
    } catch (e) {
      if (!mounted) return;
      Notify.error(
        context,
        context.tr('could_not_save'),
        error: e,
        messenger: messenger,
      );
    }
  }

  Future<void> _rename(SavedView view) =>
      showRenameSavedViewDialog(context, view);

  Future<void> _delete(SavedView view) =>
      showDeleteSavedViewDialog(context, view);

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                context.tr('saved_views'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            // Save row — name input + Save button. FormSaveScope so Enter in
            // the field fires Save (only when the name is non-empty and we're
            // not already saving).
            FormSaveScope(
              onSubmit: _save,
              enabled: _canSave,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _IconTile(
                      iconKey: _iconKey,
                      enabled: !_saving,
                      onTap: _pickCreateIcon,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NameField(controller: _name, enabled: !_saving),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(64, 44),
                      ),
                      onPressed: _canSave ? _save : null,
                      icon: _saving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.bookmark_add_outlined, size: 16),
                      label: Text(context.tr('save_view')),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: StreamBuilder<List<SavedView>>(
                stream: services.savedViews.watchForEntity(
                  widget.vm.companyId,
                  widget.vm.entityType,
                ),
                builder: (context, snap) {
                  final views = snap.data ?? const <SavedView>[];
                  if (views.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        context.tr('no_saved_views_for_entity'),
                        style: TextStyle(color: Theme.of(context).hintColor),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: views.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final view = views[i];
                      return _SavedViewRow(
                        view: view,
                        onApply: () => _apply(view),
                        onUpdate: () => _update(view),
                        onRename: () => _rename(view),
                        onDelete: () => _delete(view),
                        onChooseIcon: () =>
                            showChooseSavedViewIconDialog(context, view),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.tr('close')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.controller, required this.enabled});
  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scope = FormSaveScope.maybeOf(context);
    return TextField(
      controller: controller,
      enabled: enabled,
      autofocus: true,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: context.tr('view_name'),
        isDense: true,
      ),
      onSubmitted: scope == null ? null : (_) => scope.trySubmit(),
    );
  }
}

/// Square tappable icon preview for the create row — mirrors the
/// swatch-left-of-field layout `ColorField` uses. Tap opens the shared icon
/// grid picker; null [iconKey] shows the default bookmark.
class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.iconKey,
    required this.enabled,
    required this.onTap,
  });

  final String? iconKey;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(InRadii.r2),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(InRadii.r2),
          border: Border.all(color: tokens.border),
        ),
        child: Icon(savedViewIcon(iconKey), size: 20, color: tokens.ink2),
      ),
    );
  }
}

class _SavedViewRow extends StatelessWidget {
  const _SavedViewRow({
    required this.view,
    required this.onApply,
    required this.onUpdate,
    required this.onRename,
    required this.onDelete,
    required this.onChooseIcon,
  });

  final SavedView view;
  final VoidCallback onApply;
  final VoidCallback onUpdate;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onChooseIcon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // The leading icon is the thing being changed — tap it directly to
      // pick a new one, rather than crowding the trailing row with a 4th
      // button.
      leading: IconButton(
        tooltip: context.tr('choose_icon'),
        icon: Icon(savedViewIcon(view.iconKey)),
        onPressed: onChooseIcon,
      ),
      title: Text(view.name),
      onTap: onApply,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: context.tr('update_view'),
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: onUpdate,
          ),
          IconButton(
            tooltip: context.tr('rename'),
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: onRename,
          ),
          IconButton(
            tooltip: context.tr('delete_view'),
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
