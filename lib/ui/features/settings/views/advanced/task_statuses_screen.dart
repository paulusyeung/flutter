import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/task_status.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';

/// Search keys exported for the settings sidebar search. Colocated with
/// the screen so adding / renaming a field updates both ends in one place.
const kTaskStatusesSearchKeys = <String>[
  'task_statuses',
  'name',
  'color',
  'status_order',
];

/// `/settings/task_statuses` — list every task status. Drag the handle on
/// a row to reorder (kanban columns follow this order). Tap a row to edit;
/// tap "+ New" to create.
class TaskStatusesScreen extends StatefulWidget {
  const TaskStatusesScreen({super.key});

  @override
  State<TaskStatusesScreen> createState() => _TaskStatusesScreenState();
}

class _TaskStatusesScreenState extends State<TaskStatusesScreen> {
  late final Services _services = context.read<Services>();
  late final String _companyId =
      _services.auth.session.value?.currentCompanyId ?? '';

  /// Optimistic local order. The Drift watch stream re-emits with the
  /// persisted order once `repo.reorder` lands; we keep this snapshot so
  /// the drag drop renders instantly without waiting for the round-trip.
  List<TaskStatus>? _optimistic;

  /// When true, the body includes a second "Archived" section. Toggled
  /// via the AppBar action. The archived section is non-reorderable —
  /// their `status_order` is moot until restored.
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    if (_companyId.isNotEmpty) {
      _services.taskStatuses.refreshAll(companyId: _companyId);
    }
  }

  Future<void> _onReorder(
    List<TaskStatus> rendered,
    int oldIndex,
    int newIndex,
  ) async {
    // Flutter's ReorderableListView passes a newIndex that's already shifted
    // when the item is dragged down — normalize before splicing.
    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final next = List<TaskStatus>.from(rendered);
    final moved = next.removeAt(oldIndex);
    next.insert(adjusted, moved);
    setState(() => _optimistic = next);
    try {
      await _services.taskStatuses.reorder(
        companyId: _companyId,
        orderedStatusIds: next.map((s) => s.id).toList(growable: false),
      );
    } finally {
      // Drop the optimistic snapshot — the next stream emission will paint
      // the persisted state. If reorder threw, the snapshot was wrong
      // anyway; the stream will repaint from Drift.
      if (mounted) setState(() => _optimistic = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenScaffold(
      titleKey: 'task_statuses',
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: TextButton.icon(
            icon: Icon(
              _showArchived
                  ? Icons.visibility_off_outlined
                  : Icons.archive_outlined,
              size: 18,
            ),
            label: Text(
              context.tr(_showArchived ? 'show_active' : 'show_archived'),
            ),
            onPressed: () => setState(() => _showArchived = !_showArchived),
          ),
        ),
      ],
      body: StreamBuilder<List<TaskStatus>>(
        stream: _showArchived
            ? _services.taskStatuses.watchAllIncludingArchived(
                companyId: _companyId,
              )
            : _services.taskStatuses.watchAll(companyId: _companyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final fromDrift = snapshot.data ?? const <TaskStatus>[];
          // Split active vs archived. `_optimistic` only applies to the
          // active section (the user can't drag-reorder archived rows).
          final active = (_optimistic ?? fromDrift)
              .where((s) => s.archivedAt == null && !s.isDeleted)
              .toList(growable: false);
          final archived = fromDrift
              .where((s) => s.archivedAt != null && !s.isDeleted)
              .toList(growable: false);

          if (active.isEmpty && archived.isEmpty) {
            return EmptyState(
              icon: Icons.label_outline,
              title: context.tr('no_task_statuses'),
              subtitle: context.tr('no_task_statuses_hint'),
              action: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
                icon: const Icon(Icons.add),
                label: Text(context.tr('new_task_status')),
                onPressed: () => context.go('/settings/task_statuses/new'),
              ),
            );
          }
          return SettingsFormShell(
            sections: [
              FormSection(
                title: context.tr('task_statuses'),
                spacing: 0,
                children: [
                  if (active.isNotEmpty)
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: active.length,
                      onReorder: (oldIndex, newIndex) =>
                          _onReorder(active, oldIndex, newIndex),
                      itemBuilder: (context, i) => _TaskStatusRow(
                        key: ValueKey(active[i].id),
                        status: active[i],
                        index: i,
                      ),
                    ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: Text(context.tr('new_task_status')),
                    onTap: () => context.go('/settings/task_statuses/new'),
                  ),
                ],
              ),
              if (_showArchived && archived.isNotEmpty)
                FormSection(
                  title: context.tr('archived'),
                  spacing: 0,
                  children: [
                    for (final s in archived)
                      _TaskStatusRow.archived(key: ValueKey(s.id), status: s),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TaskStatusRow extends StatelessWidget {
  const _TaskStatusRow({required this.status, required this.index, super.key})
    : _isArchived = false;

  /// Variant rendered inside the "Archived" section. Drops the drag
  /// handle (status_order is moot until restored) and renders a muted
  /// "Archived" pill on the trailing edge.
  const _TaskStatusRow.archived({required this.status, super.key})
    : index = -1,
      _isArchived = true;

  final TaskStatus status;
  final int index;
  final bool _isArchived;

  Color _parseColor(BuildContext context) {
    final tokens = context.inTheme;
    final raw = status.color.trim().replaceFirst('#', '');
    if (raw.length == 6) {
      final v = int.tryParse(raw, radix: 16);
      if (v != null) return Color(0xFF000000 | v);
    }
    return tokens.ink3;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: _parseColor(context),
              shape: BoxShape.circle,
            ),
          ),
          title: Text(
            status.name.isEmpty ? context.tr('untitled') : status.name,
          ),
          trailing: _isArchived
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.draftSoft,
                    borderRadius: BorderRadius.circular(InRadii.r1),
                  ),
                  child: Text(
                    context.tr('archived'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: tokens.draft,
                    ),
                  ),
                )
              : ReorderableDragStartListener(
                  index: index,
                  child: Tooltip(
                    message: context.tr('drag_to_reorder'),
                    child: const Icon(Icons.drag_handle),
                  ),
                ),
          onTap: () => context.go('/settings/task_statuses/${status.id}'),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
