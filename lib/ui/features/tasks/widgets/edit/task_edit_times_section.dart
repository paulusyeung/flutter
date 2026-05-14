import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/time_entry.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/features/tasks/view_models/task_edit_view_model.dart';
import 'package:admin/ui/features/tasks/widgets/edit/time_entry_editor_sheet.dart';
import 'package:admin/ui/features/tasks/widgets/edit/time_entry_row.dart';
import 'package:admin/ui/features/tasks/widgets/edit/time_entry_table.dart';
import 'package:admin/ui/features/tasks/widgets/task_total_duration_label.dart';
import 'package:admin/utils/formatting.dart';

/// The time-log editor inside the Task edit form. Header row holds
/// "+ Add time" and a Start / Stop / Resume toggle button; the body lists
/// the entries newest-first.
class TaskEditTimesSection extends StatelessWidget {
  const TaskEditTimesSection({
    super.key,
    required this.vm,
    required this.locked,
    this.formatter,
  });

  final TaskEditViewModel vm;
  final bool locked;

  /// Resolved company `Formatter` for date rendering inside each row.
  /// Null in test contexts; falls back to ISO inside `TimeEntryRow`.
  final Formatter? formatter;

  Future<void> _openEditor(BuildContext context, int displayIndex) async {
    final entries = vm.draft.timeLog;
    final actualIndex = entries.length - 1 - displayIndex;
    final result = await TimeEntryEditorSheet.show(
      context,
      initial: entries[actualIndex],
      formatter: formatter,
    );
    if (result == null) return;
    if (TimeEntryEditorSheet.isRemoveSignal(result)) {
      vm.removeEntry(actualIndex);
    } else {
      vm.updateEntry(actualIndex, result);
    }
  }

  /// Mobile: open the editor sheet so the user can edit a fresh entry on
  /// a full-screen surface. Tiny inline cells aren't usable on small
  /// viewports.
  Future<void> _addEntryViaSheet(BuildContext context) async {
    final result = await TimeEntryEditorSheet.show(
      context,
      initial: TimeEntry(
        start: DateTime.now().subtract(const Duration(minutes: 30)),
        stop: DateTime.now(),
      ),
      formatter: formatter,
    );
    if (result == null) return;
    if (TimeEntryEditorSheet.isRemoveSignal(result)) return;
    vm.addEntry(
      start: result.start,
      stop: result.stop,
      description: result.description,
      billable: result.billable,
    );
  }

  /// Desktop: append a fresh entry inline with the VM's default seed
  /// (30 min back → now). The table watches the VM and surfaces a new
  /// row + focuses its start cell on the next frame.
  void _addEntryInline() {
    vm.addEntry();
  }

  Widget _timerButton(BuildContext context) {
    // Per-call minimumSize override — `FilledButton.tonal` inherits
    // `Size.fromHeight(44)` from the theme, which is infinite-width and
    // crashes when rendered in this Row. See CLAUDE.md § Design system
    // (v2) for the canonical rule + reference call site.
    final style = FilledButton.styleFrom(minimumSize: const Size(64, 44));
    if (vm.hasRunningEntry) {
      return FilledButton.tonalIcon(
        style: style,
        icon: const Icon(Icons.stop_circle_outlined),
        label: Text(context.tr('stop')),
        onPressed: locked ? null : vm.stopTimer,
      );
    }
    if (vm.hasStoppedEntries) {
      return FilledButton.tonalIcon(
        style: style,
        icon: const Icon(Icons.play_arrow_outlined),
        label: Text(context.tr('resume')),
        onPressed: locked ? null : vm.resumeTimer,
      );
    }
    return FilledButton.tonalIcon(
      style: style,
      icon: const Icon(Icons.play_arrow_outlined),
      label: Text(context.tr('start')),
      onPressed: locked ? null : vm.startTimer,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final entries = vm.draft.timeLog.reversed.toList(growable: false);
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(InRadii.r3),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = Breakpoints.isWide(constraints);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header — same on both layouts; only the "add" action's
              // entry point differs (inline on desktop, modal sheet on
              // mobile).
              Padding(
                padding: const EdgeInsets.all(InSpacing.md),
                child: Row(
                  children: [
                    Text(
                      context.tr('time_log').toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.ink3,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: InSpacing.md),
                    // Live wall-clock total — ticks every second when an
                    // entry is running, otherwise renders statically.
                    TaskTotalDurationLabel(vm: vm),
                    const Spacer(),
                    if (!locked) ...[
                      // Per-call minimumSize override: lib/app/theme.dart
                      // sets `Size.fromHeight(40)` on OutlinedButton which
                      // is `Size(double.infinity, 40)` — fine in a column,
                      // fatal in this Row. Same story for the
                      // FilledButton.tonalIcon returned by `_timerButton`.
                      // See CLAUDE.md § Design system (v2) "Default to
                      // side-by-side dialog actions" for the verbatim rule.
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(64, 40),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(context.tr('add_time')),
                        onPressed: wide
                            ? _addEntryInline
                            : () => _addEntryViaSheet(context),
                      ),
                      const SizedBox(width: InSpacing.sm),
                      _timerButton(context),
                    ],
                  ],
                ),
              ),
              Divider(height: 1, color: tokens.border),
              // Pick between the desktop table and the mobile card list.
              if (wide)
                TimeEntryTable(
                  vm: vm,
                  locked: locked,
                  formatter: formatter,
                  onAddEntry: _addEntryInline,
                )
              else if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(InSpacing.lg),
                  child: Center(
                    child: Text(
                      context.tr('no_entries'),
                      style: TextStyle(color: tokens.ink3),
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < entries.length; i++)
                      TimeEntryRow(
                        entry: entries[i],
                        enabled: !locked,
                        formatter: formatter,
                        onTap: () => _openEditor(context, i),
                        onRemove: () =>
                            vm.removeEntry(vm.draft.timeLog.length - 1 - i),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
