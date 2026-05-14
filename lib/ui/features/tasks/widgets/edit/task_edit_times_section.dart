import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/time_entry.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/tasks/view_models/task_edit_view_model.dart';
import 'package:admin/ui/features/tasks/widgets/edit/time_entry_editor_sheet.dart';
import 'package:admin/ui/features/tasks/widgets/edit/time_entry_row.dart';

/// The time-log editor inside the Task edit form. Header row holds
/// "+ Add time" and a Start / Stop / Resume toggle button; the body lists
/// the entries newest-first.
class TaskEditTimesSection extends StatelessWidget {
  const TaskEditTimesSection({
    super.key,
    required this.vm,
    required this.locked,
  });

  final TaskEditViewModel vm;
  final bool locked;

  Future<void> _openEditor(BuildContext context, int displayIndex) async {
    final entries = vm.draft.timeLog;
    final actualIndex = entries.length - 1 - displayIndex;
    final result = await TimeEntryEditorSheet.show(
      context,
      initial: entries[actualIndex],
    );
    if (result == null) return;
    if (TimeEntryEditorSheet.isRemoveSignal(result)) {
      vm.removeEntry(actualIndex);
    } else {
      vm.updateEntry(actualIndex, result);
    }
  }

  Future<void> _addEntry(BuildContext context) async {
    final result = await TimeEntryEditorSheet.show(
      context,
      initial: TimeEntry(
        start: DateTime.now().subtract(const Duration(minutes: 30)),
        stop: DateTime.now(),
      ),
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

  Widget _timerButton(BuildContext context) {
    if (vm.hasRunningEntry) {
      return FilledButton.tonalIcon(
        icon: const Icon(Icons.stop_circle_outlined),
        label: Text(context.tr('stop')),
        onPressed: locked ? null : vm.stopTimer,
      );
    }
    if (vm.hasStoppedEntries) {
      return FilledButton.tonalIcon(
        icon: const Icon(Icons.play_arrow_outlined),
        label: Text(context.tr('resume')),
        onPressed: locked ? null : vm.resumeTimer,
      );
    }
    return FilledButton.tonalIcon(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
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
                const Spacer(),
                if (!locked) ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(context.tr('add_time')),
                    onPressed: () => _addEntry(context),
                  ),
                  const SizedBox(width: InSpacing.sm),
                  _timerButton(context),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: tokens.border),
          if (entries.isEmpty)
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
            for (var i = 0; i < entries.length; i++)
              TimeEntryRow(
                entry: entries[i],
                enabled: !locked,
                onTap: () => _openEditor(context, i),
                onRemove: () => vm.removeEntry(vm.draft.timeLog.length - 1 - i),
              ),
        ],
      ),
    );
  }
}
