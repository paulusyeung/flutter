import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/task_status.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/standard_entity_actions.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/core/widgets/form_save_scope.dart';
import 'package:admin/ui/features/settings/view_models/task_status_edit_view_model.dart';
import 'package:admin/ui/features/settings/widgets/accent_swatch_grid.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';

/// `/settings/task_statuses/new` and `/settings/task_statuses/:id`.
///
/// Edit-or-create form for a single TaskStatus. Save sits in the AppBar
/// (per the rest of the settings sidebar). Existing rows expose an
/// overflow menu with Archive / Restore / Delete that routes through the
/// standard action helpers.
class TaskStatusesEditScreen extends StatefulWidget {
  const TaskStatusesEditScreen({this.existingId, super.key});

  final String? existingId;

  @override
  State<TaskStatusesEditScreen> createState() => _TaskStatusesEditScreenState();
}

class _TaskStatusesEditScreenState extends State<TaskStatusesEditScreen> {
  late final Services _services = context.read<Services>();
  late final String _companyId =
      _services.auth.session.value?.currentCompanyId ?? '';

  TaskStatusEditViewModel? _vm;
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
        _vm = TaskStatusEditViewModel(
          repo: _services.taskStatuses,
          companyId: _companyId,
        );
        _loading = false;
      });
      return;
    }
    try {
      var existing = await _services.taskStatuses
          .watch(companyId: _companyId, id: widget.existingId!)
          .first;
      if (existing == null) {
        // Deep link with a fresh local cache — retry once after a
        // server refresh before declaring "not found."
        await _services.taskStatuses.refreshAll(companyId: _companyId);
        if (!mounted) return;
        existing = await _services.taskStatuses
            .watch(companyId: _companyId, id: widget.existingId!)
            .first;
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
        _vm = TaskStatusEditViewModel(
          repo: _services.taskStatuses,
          companyId: _companyId,
          existing: existing,
        );
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
      context.go('/settings/task_statuses');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.existingId == null;
    final titleKey = isCreate ? 'new_task_status' : 'edit_task_status';

    if (_loading) {
      return SettingsScreenScaffold(
        titleKey: titleKey,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null || _vm == null) {
      return SettingsScreenScaffold(
        titleKey: titleKey,
        body: EmptyState(
          icon: Icons.error_outline,
          title: context.tr('not_found'),
          action: FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () => context.go('/settings/task_statuses'),
            child: Text(context.tr('back')),
          ),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _vm!,
      child: Consumer<TaskStatusEditViewModel>(
        builder: (context, vm, _) {
          // Block Save when name is empty — a nameless status would
          // render as its UUID on the kanban column header.
          final canSave =
              !vm.isSaving && vm.isDirty && vm.draft.name.trim().isNotEmpty;
          return SettingsScreenScaffold(
            titleKey: titleKey,
            actions: [
              if (!isCreate) _StatusOverflowMenu(status: vm.draft),
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
            body: FormSaveScope(
              onSubmit: _onSave,
              enabled: canSave,
              child: SettingsFormShell(
                sections: [
                  FormSection(
                    title: context.tr('task_status'),
                    children: [
                      _NameField(vm: vm),
                      _ColorField(vm: vm),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NameField extends StatefulWidget {
  const _NameField({required this.vm});
  final TaskStatusEditViewModel vm;

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.vm.draft.name,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = FormSaveScope.maybeOf(context);
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: context.tr('name'),
        errorText: widget.vm.fieldErrorFor('name'),
      ),
      textInputAction: TextInputAction.done,
      onChanged: widget.vm.setName,
      onSubmitted: scope == null ? null : (_) => scope.trySubmit(),
    );
  }
}

class _ColorField extends StatelessWidget {
  const _ColorField({required this.vm});
  final TaskStatusEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('color'),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          AccentSwatchGrid(
            selected: vm.draft.color,
            onSelected: vm.setColor,
            palette: kStatusSwatches,
          ),
          const SizedBox(height: InSpacing.md),
          _StatusPreview(name: vm.draft.name, color: vm.draft.color),
        ],
      ),
    );
  }
}

/// Live preview of how the status will read on a kanban column header.
/// Updates as the user types into the name field or picks a different
/// swatch — exact rendering matches what `_ColumnHeader` does in the
/// kanban (color dot + name + token-styled label).
class _StatusPreview extends StatelessWidget {
  const _StatusPreview({required this.name, required this.color});

  final String name;
  final String color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final parsed = parseAccentHex(color) ?? tokens.ink3;
    final displayName = name.trim().isEmpty ? context.tr('untitled') : name;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(InRadii.r2),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: InSpacing.md,
        vertical: InSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: parsed, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tokens.ink,
              ),
            ),
          ),
          Text('0', style: TextStyle(fontSize: 12, color: tokens.ink3)),
        ],
      ),
    );
  }
}

/// Archive / Restore / Delete overflow for existing statuses. Mirrors
/// `_GroupOverflowMenu` so success toasts follow the same convention.
class _StatusOverflowMenu extends StatelessWidget {
  const _StatusOverflowMenu({required this.status});
  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    final canArchive = status.archivedAt == null && !status.isDeleted;
    final canRestore = status.archivedAt != null || status.isDeleted;

    return PopupMenuButton<String>(
      tooltip: context.tr('more_actions'),
      onSelected: (action) async {
        switch (action) {
          case 'archive':
            await StandardEntityActions.archive(
              context: context,
              wireName: 'task_status',
              op: () => services.taskStatuses.archive(
                companyId: companyId,
                id: status.id,
              ),
            );
            if (context.mounted && context.canPop()) context.pop();
          case 'restore':
            await StandardEntityActions.restore(
              context: context,
              wireName: 'task_status',
              op: () => services.taskStatuses.restore(
                companyId: companyId,
                id: status.id,
              ),
            );
            if (context.mounted && context.canPop()) context.pop();
          case 'delete':
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(ctx.tr('delete')),
                content: Text(ctx.tr('are_you_sure')),
                actions: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(64, 40),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(ctx.tr('cancel')),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(64, 44),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(ctx.tr('delete')),
                  ),
                ],
              ),
            );
            if (confirmed != true || !context.mounted) return;
            await StandardEntityActions.delete(
              context: context,
              wireName: 'task_status',
              op: () => services.taskStatuses.delete(
                companyId: companyId,
                id: status.id,
              ),
            );
            if (context.mounted && context.canPop()) context.pop();
        }
      },
      itemBuilder: (context) => [
        if (canArchive)
          PopupMenuItem(value: 'archive', child: Text(context.tr('archive'))),
        if (canRestore)
          PopupMenuItem(value: 'restore', child: Text(context.tr('restore'))),
        PopupMenuItem(value: 'delete', child: Text(context.tr('delete'))),
      ],
    );
  }
}
