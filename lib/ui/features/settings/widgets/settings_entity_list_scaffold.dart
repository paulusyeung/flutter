import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';

/// Shared chrome for the list view of a bundled settings-CRUD entity
/// (payment_terms, task_statuses, group_settings, …). Owns the
/// `StreamBuilder`, empty state, `FormSection` container, "+ New" tile,
/// optional Show Archived toggle, and optional drag-to-reorder.
///
/// Per-screen callers supply just the row layout and the stream/refresh
/// hooks bound to their repo — list screens drop from ~120–260 lines to
/// ~30–60.
///
/// Reorder semantics: when [onReorder] is non-null, active rows render
/// inside a `ReorderableListView` and the scaffold owns the optimistic
/// snapshot so the drag drop lands instantly. The snapshot clears as
/// soon as the stream re-emits with the persisted order.
class SettingsEntityListScaffold<T> extends StatefulWidget {
  const SettingsEntityListScaffold({
    super.key,
    required this.titleKey,
    required this.sectionTitleKey,
    required this.newRoute,
    required this.newLabelKey,
    required this.emptyIcon,
    required this.emptyTitleKey,
    required this.emptyHintKey,
    required this.refreshAll,
    required this.stream,
    required this.isArchivedOf,
    required this.isDeletedOf,
    this.rowBuilder,
    this.reorderableRowBuilder,
    this.archivedRowBuilder,
    this.supportsArchive = false,
    this.onReorder,
  }) : assert(
         rowBuilder != null || reorderableRowBuilder != null,
         'Pass at least one of rowBuilder or reorderableRowBuilder',
       ),
       assert(
         onReorder == null || reorderableRowBuilder != null,
         'reorderableRowBuilder is required when onReorder is non-null',
       ),
       assert(
         !supportsArchive || rowBuilder != null || archivedRowBuilder != null,
         'When supportsArchive is true, pass either rowBuilder or '
         'archivedRowBuilder (or both) to render archived rows',
       );

  /// AppBar title and section header keys.
  final String titleKey;
  final String sectionTitleKey;

  /// `/settings/<slug>/new` for the "+ New" tile + empty-state CTA.
  final String newRoute;
  final String newLabelKey;

  /// Empty-state copy when both active and archived sections are empty.
  final IconData emptyIcon;
  final String emptyTitleKey;
  final String emptyHintKey;

  /// Fire-and-forget background refresh from the server. Called once on
  /// `initState`.
  final Future<void> Function() refreshAll;

  /// Repo watch. The scaffold flips between active-only and
  /// active+archived based on the toggle state. Callers wire as
  /// `({includeArchived}) => includeArchived
  ///     ? services.[repo].watchAllIncludingArchived(companyId: ...)
  ///     : services.[repo].watchAll(companyId: ...)`.
  final Stream<List<T>> Function({required bool includeArchived}) stream;

  /// Predicates used to split the stream into active vs archived sections.
  final bool Function(T) isArchivedOf;
  final bool Function(T) isDeletedOf;

  /// Row layout for the active section in static (non-reorderable) mode.
  /// Required unless [reorderableRowBuilder] is supplied. Set a stable
  /// `ValueKey(entity.id)` on each row to keep tap targets stable across
  /// stream emissions.
  final Widget Function(T item)? rowBuilder;

  /// Row layout when `onReorder` is non-null. Receives the row's index in
  /// the active list so the caller can wire a `ReorderableDragStartListener`.
  /// Required when [onReorder] is set; ignored otherwise.
  final Widget Function(T item, int index)? reorderableRowBuilder;

  /// Row layout for the archived section. Defaults to [rowBuilder] when
  /// omitted — but most callers want a separate variant that drops the
  /// trailing chevron / drag handle in favor of an "Archived" pill.
  final Widget Function(T item)? archivedRowBuilder;

  /// When true, the AppBar carries a Show Archived / Show Active toggle
  /// and the body renders a second FormSection for archived rows.
  final bool supportsArchive;

  /// Optional reorder hook. When non-null, the active section becomes a
  /// `ReorderableListView` whose drag drop fires this callback with the
  /// reordered list. The scaffold owns the optimistic snapshot so the UI
  /// repaints instantly. Archived rows are never reorderable
  /// (`status_order` is moot until restored).
  final Future<void> Function(List<T> reordered)? onReorder;

  @override
  State<SettingsEntityListScaffold<T>> createState() =>
      _SettingsEntityListScaffoldState<T>();
}

class _SettingsEntityListScaffoldState<T>
    extends State<SettingsEntityListScaffold<T>> {
  bool _showArchived = false;

  /// Optimistic local order. Stays around just long enough for the next
  /// stream emission to repaint with the persisted order. Only used when
  /// `widget.onReorder` is non-null.
  List<T>? _optimistic;

  @override
  void initState() {
    super.initState();
    widget.refreshAll();
  }

  Future<void> _handleReorder(
    List<T> rendered,
    int oldIndex,
    int newIndex,
  ) async {
    // Flutter's ReorderableListView passes a newIndex that's already
    // shifted when the item is dragged down — normalize before splicing.
    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final next = List<T>.from(rendered);
    final moved = next.removeAt(oldIndex);
    next.insert(adjusted, moved);
    setState(() => _optimistic = next);
    try {
      await widget.onReorder!(next);
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
      titleKey: widget.titleKey,
      actions: [
        if (widget.supportsArchive)
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
      body: StreamBuilder<List<T>>(
        stream: widget.stream(includeArchived: _showArchived),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final fromDrift = snapshot.data ?? <T>[];
          // Optimistic snapshot only applies to the active section — the
          // user can't drag-reorder archived rows.
          final activeSource = _optimistic ?? fromDrift;
          final active = activeSource
              .where((t) => !widget.isArchivedOf(t) && !widget.isDeletedOf(t))
              .toList(growable: false);
          final archived = fromDrift
              .where((t) => widget.isArchivedOf(t) && !widget.isDeletedOf(t))
              .toList(growable: false);

          if (active.isEmpty && archived.isEmpty) {
            return EmptyState(
              icon: widget.emptyIcon,
              title: context.tr(widget.emptyTitleKey),
              subtitle: context.tr(widget.emptyHintKey),
              action: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
                icon: const Icon(Icons.add),
                label: Text(context.tr(widget.newLabelKey)),
                onPressed: () => context.go(widget.newRoute),
              ),
            );
          }

          // `onReorder == null` implies `rowBuilder != null` (constructor
          // assert). When reorder is on, `reorderableRowBuilder!` is the
          // active section's builder and the static `rowBuilder` is
          // unused — `archivedRowBuilder` (or a fallback) covers archived.
          final activeSection = widget.onReorder == null
              ? _StaticRows<T>(items: active, rowBuilder: widget.rowBuilder!)
              : _ReorderableRows<T>(
                  items: active,
                  rowBuilder: widget.reorderableRowBuilder!,
                  onReorder: (o, n) => _handleReorder(active, o, n),
                );

          return SettingsFormShell(
            sections: [
              FormSection(
                title: context.tr(widget.sectionTitleKey),
                spacing: 0,
                children: [
                  if (active.isNotEmpty) activeSection,
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: Text(context.tr(widget.newLabelKey)),
                    onTap: () => context.go(widget.newRoute),
                  ),
                ],
              ),
              if (_showArchived && archived.isNotEmpty)
                FormSection(
                  title: context.tr('archived'),
                  spacing: 0,
                  children: [
                    for (final item in archived)
                      (widget.archivedRowBuilder ?? widget.rowBuilder!)(item),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Static rows + divider between each. Used when reorder is off.
class _StaticRows<T> extends StatelessWidget {
  const _StaticRows({required this.items, required this.rowBuilder});

  final List<T> items;
  final Widget Function(T item) rowBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [for (final item in items) rowBuilder(item)],
    );
  }
}

/// Active rows wrapped in a `ReorderableListView` shrink-wrapped inside the
/// `FormSection`. Per-item key is the row widget's own key — callers must
/// set a stable `ValueKey(entity.id)` on each row.
class _ReorderableRows<T> extends StatelessWidget {
  const _ReorderableRows({
    required this.items,
    required this.rowBuilder,
    required this.onReorder,
  });

  final List<T> items;
  final Widget Function(T item, int index) rowBuilder;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: items.length,
      onReorder: onReorder,
      itemBuilder: (context, i) => rowBuilder(items[i], i),
    );
  }
}
