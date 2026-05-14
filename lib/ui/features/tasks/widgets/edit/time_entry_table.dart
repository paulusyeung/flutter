import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/time_entry.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/tasks/view_models/task_edit_view_model.dart';
import 'package:admin/ui/features/tasks/widgets/running_duration_label.dart';
import 'package:admin/utils/formatting.dart';

/// Desktop time-log editor: a tabular layout with inline-editable cells
/// per entry plus a full-width description `TextField` underneath. Lives
/// alongside the mobile [TimeEntryRow] list — `TaskEditTimesSection`
/// switches between them on `Breakpoints.isWide(constraints)`.
///
/// Cells are private to this file (`_DateCell`, `_TimeCell`,
/// `_DurationCell`, `_BillableCell`, `_DeleteCell`). Promote to a shared
/// directory only when a second entity (invoice line items, expense
/// items) needs the same shapes.
class TimeEntryTable extends StatelessWidget {
  const TimeEntryTable({
    super.key,
    required this.vm,
    required this.locked,
    required this.onAddEntry,
    this.formatter,
  });

  final TaskEditViewModel vm;
  final bool locked;

  /// Called when the trailing "+ Add time" row is tapped. The parent
  /// section already owns the editor-sheet seed defaults; routing through
  /// the same handler keeps both paths consistent.
  final VoidCallback onAddEntry;

  final Formatter? formatter;

  static const double _wDate = 120;
  static const double _wTime = 88;
  static const double _wDuration = 110;
  static const double _wBillable = 48;
  static const double _wDelete = 40;
  static const double _gap = InSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final entries = vm.draft.timeLog.reversed.toList(growable: false);

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Headers(tokens: tokens),
        Divider(height: 1, color: tokens.border),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: InSpacing.lg),
            child: Center(
              child: Text(
                context.tr('no_entries'),
                style: TextStyle(color: tokens.ink3),
              ),
            ),
          )
        else
          for (var i = 0; i < entries.length; i++)
            _EntryBlock(
              key: ValueKey(
                'entry-${entries[i].start?.millisecondsSinceEpoch ?? -i}',
              ),
              vm: vm,
              entry: entries[i],
              actualIndex: vm.draft.timeLog.length - 1 - i,
              locked: locked,
              formatter: formatter,
            ),
        if (!locked) ...[
          Divider(height: 1, color: tokens.border),
          _AddTimeRow(onTap: onAddEntry),
        ],
      ],
    );

    // Lock-state pattern matches `_ClientPicker` / `_StatusPicker` in
    // task_edit_layout.dart — IgnorePointer kills hit-testing without
    // graying out individual fields, Opacity reads as "muted content".
    return IgnorePointer(
      ignoring: locked,
      child: Opacity(opacity: locked ? 0.5 : 1, child: body),
    );
  }
}

class _Headers extends StatelessWidget {
  const _Headers({required this.tokens});
  final InTheme tokens;

  Widget _label(
    BuildContext context,
    String key, {
    double? width,
    bool flex = false,
  }) {
    final text = Text(
      context.tr(key).toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: tokens.ink3,
        letterSpacing: 0.4,
      ),
    );
    if (flex) return Expanded(child: text);
    return SizedBox(width: width, child: text);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: InSpacing.md,
        vertical: InSpacing.sm,
      ),
      child: Row(
        children: [
          _label(context, 'date', width: TimeEntryTable._wDate),
          const SizedBox(width: TimeEntryTable._gap),
          _label(context, 'start_time', width: TimeEntryTable._wTime),
          const SizedBox(width: TimeEntryTable._gap),
          _label(context, 'end_time', width: TimeEntryTable._wTime),
          const SizedBox(width: TimeEntryTable._gap),
          _label(context, 'duration', width: TimeEntryTable._wDuration),
          const SizedBox(width: TimeEntryTable._gap),
          _label(context, 'billable', width: TimeEntryTable._wBillable),
          const SizedBox(width: TimeEntryTable._gap),
          // Delete column has no header label — the icon is self-evident.
          const SizedBox(width: TimeEntryTable._wDelete),
        ],
      ),
    );
  }
}

class _EntryBlock extends StatelessWidget {
  const _EntryBlock({
    super.key,
    required this.vm,
    required this.entry,
    required this.actualIndex,
    required this.locked,
    required this.formatter,
  });

  final TaskEditViewModel vm;
  final TimeEntry entry;
  final int actualIndex;
  final bool locked;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final isRunning = entry.isRunning;
    return Container(
      decoration: BoxDecoration(
        color: isRunning ? tokens.accentSoft.withValues(alpha: 0.3) : null,
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: InSpacing.md,
        vertical: InSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: TimeEntryTable._wDate,
                child: _DateCell(
                  vm: vm,
                  entry: entry,
                  actualIndex: actualIndex,
                  formatter: formatter,
                ),
              ),
              const SizedBox(width: TimeEntryTable._gap),
              SizedBox(
                width: TimeEntryTable._wTime,
                child: _TimeCell(
                  vm: vm,
                  entry: entry,
                  actualIndex: actualIndex,
                  field: _TimeField.start,
                ),
              ),
              const SizedBox(width: TimeEntryTable._gap),
              SizedBox(
                width: TimeEntryTable._wTime,
                child: _TimeCell(
                  vm: vm,
                  entry: entry,
                  actualIndex: actualIndex,
                  field: _TimeField.stop,
                ),
              ),
              const SizedBox(width: TimeEntryTable._gap),
              SizedBox(
                width: TimeEntryTable._wDuration,
                child: _DurationCell(
                  vm: vm,
                  entry: entry,
                  actualIndex: actualIndex,
                ),
              ),
              const SizedBox(width: TimeEntryTable._gap),
              SizedBox(
                width: TimeEntryTable._wBillable,
                child: _BillableCell(
                  vm: vm,
                  entry: entry,
                  actualIndex: actualIndex,
                ),
              ),
              const SizedBox(width: TimeEntryTable._gap),
              SizedBox(
                width: TimeEntryTable._wDelete,
                child: locked
                    ? const SizedBox.shrink()
                    : _DeleteCell(vm: vm, actualIndex: actualIndex),
              ),
            ],
          ),
          const SizedBox(height: InSpacing.sm),
          _DescriptionField(vm: vm, entry: entry, actualIndex: actualIndex),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Cells
// ─────────────────────────────────────────────────────────────────────

class _DateCell extends StatelessWidget {
  const _DateCell({
    required this.vm,
    required this.entry,
    required this.actualIndex,
    required this.formatter,
  });

  final TaskEditViewModel vm;
  final TimeEntry entry;
  final int actualIndex;
  final Formatter? formatter;

  String _label() {
    final start = entry.start;
    if (start == null) return '—';
    final local = start.toLocal();
    final iso =
        '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    final f = formatter;
    return f == null ? iso : f.date(iso);
  }

  Future<void> _pick(BuildContext context) async {
    final base = entry.start?.toLocal() ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked == null) return;
    // Preserve the existing time-of-day; if the entry has no start yet,
    // anchor at the picked date midnight + 9am as a sensible default.
    final hour = entry.start?.toLocal().hour ?? 9;
    final minute = entry.start?.toLocal().minute ?? 0;
    final nextStart = DateTime(
      picked.year,
      picked.month,
      picked.day,
      hour,
      minute,
    );
    // Shift stop alongside start so the entry's duration is preserved.
    // Without this, moving an entry's date past its stop time leaves
    // `stop - start` negative and the duration cell renders garbage.
    // Skip for running entries (stop == null).
    DateTime? nextStop;
    final oldStart = entry.start;
    final oldStop = entry.stop;
    if (oldStop != null) {
      if (oldStart != null) {
        nextStop = nextStart.add(oldStop.difference(oldStart));
      } else {
        nextStop = oldStop;
      }
    }
    vm.updateEntry(
      actualIndex,
      entry.copyWith(start: nextStart, stop: nextStop),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      onPressed: () => _pick(context),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          _label(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

enum _TimeField { start, stop }

class _TimeCell extends StatelessWidget {
  const _TimeCell({
    required this.vm,
    required this.entry,
    required this.actualIndex,
    required this.field,
  });

  final TaskEditViewModel vm;
  final TimeEntry entry;
  final int actualIndex;
  final _TimeField field;

  String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _label(BuildContext context) {
    final target = field == _TimeField.start ? entry.start : entry.stop;
    if (target == null) {
      // For a running entry, the stop cell renders the localized
      // "Running" label.
      if (field == _TimeField.stop && entry.isRunning) {
        return context.tr('running');
      }
      return '—';
    }
    return _hhmm(target.toLocal());
  }

  Future<void> _pick(BuildContext context) async {
    final base =
        (field == _TimeField.start ? entry.start : entry.stop)?.toLocal() ??
        DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
    );
    if (picked == null) return;
    final next = DateTime(
      base.year,
      base.month,
      base.day,
      picked.hour,
      picked.minute,
    );
    if (field == _TimeField.start) {
      vm.updateEntry(actualIndex, entry.copyWith(start: next));
    } else {
      vm.updateEntry(actualIndex, entry.copyWith(stop: next));
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = field == _TimeField.stop && entry.isRunning;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      onPressed: disabled ? null : () => _pick(context),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          _label(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

class _DurationCell extends StatefulWidget {
  const _DurationCell({
    required this.vm,
    required this.entry,
    required this.actualIndex,
  });

  final TaskEditViewModel vm;
  final TimeEntry entry;
  final int actualIndex;

  @override
  State<_DurationCell> createState() => _DurationCellState();
}

class _DurationCellState extends State<_DurationCell> {
  late final TextEditingController _controller;
  String _externalText = '';

  @override
  void initState() {
    super.initState();
    _externalText = _format(widget.entry);
    _controller = TextEditingController(text: _externalText);
  }

  @override
  void didUpdateWidget(covariant _DurationCell old) {
    super.didUpdateWidget(old);
    final next = _format(widget.entry);
    // Re-seed only when the external value changed *and* the user isn't
    // currently typing (controller text out of sync). Avoids cursor
    // jumps on every parent rebuild.
    if (next != _externalText && next != _controller.text) {
      _externalText = next;
      _controller.text = next;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(TimeEntry e) {
    if (e.isRunning) return ''; // running cell uses RunningDurationLabel
    final s = e.start;
    final p = e.stop;
    if (s == null || p == null) return '';
    return formatDuration(p.difference(s), compactDays: true);
  }

  void _onChanged(String raw) {
    final parsed = parseDurationInput(raw);
    if (parsed == null) return;
    final s = widget.entry.start;
    if (s == null) return;
    final nextStop = s.add(parsed);
    // Stash the *canonical* duration text before the VM update so the
    // `didUpdateWidget` re-seed branch sees `next == _externalText` and
    // skips overwriting the controller (which would jump the cursor to
    // end on every keystroke). Mirrors _DescriptionField's pattern.
    _externalText = formatDuration(nextStop.difference(s), compactDays: true);
    widget.vm.updateEntry(
      widget.actualIndex,
      widget.entry.copyWith(stop: nextStop),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entry.isRunning && widget.entry.start != null) {
      // Running entries can't have their stop time written directly via
      // the duration cell — show the live ticker instead.
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: RunningDurationLabel(start: widget.entry.start!),
      );
    }
    return SizedBox(
      height: 36,
      child: TextField(
        controller: _controller,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          fontSize: 12,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        onChanged: _onChanged,
      ),
    );
  }
}

class _BillableCell extends StatelessWidget {
  const _BillableCell({
    required this.vm,
    required this.entry,
    required this.actualIndex,
  });

  final TaskEditViewModel vm;
  final TimeEntry entry;
  final int actualIndex;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final billable = entry.billable;
    return IconButton(
      tooltip: context.tr(billable ? 'billable' : 'non_billable'),
      icon: Icon(
        billable ? Icons.attach_money : Icons.money_off_outlined,
        size: 18,
        color: billable ? tokens.accent : tokens.ink3,
      ),
      onPressed: () =>
          vm.updateEntry(actualIndex, entry.copyWith(billable: !billable)),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}

class _DeleteCell extends StatelessWidget {
  const _DeleteCell({required this.vm, required this.actualIndex});

  final TaskEditViewModel vm;
  final int actualIndex;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: context.tr('remove'),
      icon: const Icon(Icons.close, size: 16),
      onPressed: () => vm.removeEntry(actualIndex),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 36),
    );
  }
}

class _DescriptionField extends StatefulWidget {
  const _DescriptionField({
    required this.vm,
    required this.entry,
    required this.actualIndex,
  });

  final TaskEditViewModel vm;
  final TimeEntry entry;
  final int actualIndex;

  @override
  State<_DescriptionField> createState() => _DescriptionFieldState();
}

class _DescriptionFieldState extends State<_DescriptionField> {
  late final TextEditingController _controller;
  String _externalText = '';

  @override
  void initState() {
    super.initState();
    _externalText = widget.entry.description;
    _controller = TextEditingController(text: _externalText);
  }

  @override
  void didUpdateWidget(covariant _DescriptionField old) {
    super.didUpdateWidget(old);
    final next = widget.entry.description;
    if (next != _externalText && next != _controller.text) {
      _externalText = next;
      _controller.text = next;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      minLines: 1,
      maxLines: 3,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: context.tr('description'),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      onChanged: (v) {
        _externalText = v;
        widget.vm.updateEntry(
          widget.actualIndex,
          widget.entry.copyWith(description: v),
        );
      },
    );
  }
}

class _AddTimeRow extends StatelessWidget {
  const _AddTimeRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: InSpacing.md,
          vertical: InSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(Icons.add, size: 18, color: tokens.ink3),
            const SizedBox(width: 8),
            Text(
              context.tr('add_time'),
              style: TextStyle(
                color: tokens.ink3,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
