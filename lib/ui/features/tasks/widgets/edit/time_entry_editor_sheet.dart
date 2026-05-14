import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/time_entry.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/utils/formatting.dart';

/// Full editor for a single `TimeEntry`. Modal — opens as a bottom sheet on
/// narrow screens (`<600 px`) and an `AlertDialog` on wide. Returns the
/// committed entry to the caller, or `null` if the user cancelled.
///
/// Returns the literal value `_kRemoveSentinel` (a special TimeEntry value
/// produced by [_RemoveSentinel]) when the user taps Remove — the caller
/// distinguishes via the static helper [isRemoveSignal].
class TimeEntryEditorSheet extends StatefulWidget {
  const TimeEntryEditorSheet({
    super.key,
    required this.initial,
    this.allowBillableToggle = true,
    this.allowRemove = true,
    this.formatter,
  });

  final TimeEntry initial;
  final bool allowBillableToggle;
  final bool allowRemove;

  /// Resolved company `Formatter` for the start-date button label.
  /// Falls back to ISO when null.
  final Formatter? formatter;

  /// Public entry point — shows the modal and resolves with the committed
  /// entry, `null` if cancelled, or a sentinel that the caller can detect
  /// via [isRemoveSignal] (Remove was tapped).
  static Future<TimeEntry?> show(
    BuildContext context, {
    required TimeEntry initial,
    bool allowBillableToggle = true,
    bool allowRemove = true,
    Formatter? formatter,
  }) async {
    final isWide = MediaQuery.sizeOf(context).width >= 600;
    if (isWide) {
      return showDialog<TimeEntry>(
        context: context,
        builder: (ctx) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: TimeEntryEditorSheet(
              initial: initial,
              allowBillableToggle: allowBillableToggle,
              allowRemove: allowRemove,
              formatter: formatter,
            ),
          ),
        ),
      );
    }
    return showModalBottomSheet<TimeEntry>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: TimeEntryEditorSheet(
          initial: initial,
          allowBillableToggle: allowBillableToggle,
          allowRemove: allowRemove,
          formatter: formatter,
        ),
      ),
    );
  }

  /// Sentinel detection — the Remove button resolves with a `TimeEntry`
  /// whose start AND stop are both `_removeFlag` (a fixed epoch second
  /// in the year 1970). Callers check via this helper.
  static bool isRemoveSignal(TimeEntry? value) =>
      value != null &&
      value.start != null &&
      value.start!.millisecondsSinceEpoch == _removeMillis &&
      value.stop != null &&
      value.stop!.millisecondsSinceEpoch == _removeMillis;

  static const int _removeMillis = -1;
  static final TimeEntry removeSentinel = TimeEntry(
    start: DateTime.fromMillisecondsSinceEpoch(_removeMillis, isUtc: true),
    stop: DateTime.fromMillisecondsSinceEpoch(_removeMillis, isUtc: true),
    description: '',
    billable: false,
  );

  @override
  State<TimeEntryEditorSheet> createState() => _TimeEntryEditorSheetState();
}

class _TimeEntryEditorSheetState extends State<TimeEntryEditorSheet> {
  late DateTime _start;
  late DateTime _stop;
  late bool _isRunning;
  late TextEditingController _description;
  late TextEditingController _duration;
  late bool _billable;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = widget.initial.start ?? now.subtract(const Duration(minutes: 30));
    _isRunning = widget.initial.isRunning;
    _stop = widget.initial.stop ?? now;
    _description = TextEditingController(text: widget.initial.description);
    _duration = TextEditingController(
      text: formatDuration(_stop.difference(_start), compactDays: true),
    );
    _billable = widget.initial.billable;
  }

  @override
  void dispose() {
    _description.dispose();
    _duration.dispose();
    super.dispose();
  }

  void _onDurationChanged(String raw) {
    final parsed = parseDurationInput(raw);
    if (parsed == null) return;
    setState(() {
      _stop = _start.add(parsed);
      _isRunning = false;
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start.toLocal(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _start = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _start.hour,
        _start.minute,
      );
    });
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start.toLocal()),
    );
    if (picked == null) return;
    setState(() {
      _start = DateTime(
        _start.year,
        _start.month,
        _start.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _pickStopTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_stop.toLocal()),
    );
    if (picked == null) return;
    setState(() {
      _stop = DateTime(
        _stop.year,
        _stop.month,
        _stop.day,
        picked.hour,
        picked.minute,
      );
      _isRunning = false;
      _duration.text = formatDuration(
        _stop.difference(_start),
        compactDays: true,
      );
    });
  }

  void _commit() {
    Navigator.of(context).pop(
      TimeEntry(
        start: _start,
        stop: _isRunning ? null : _stop,
        description: _description.text,
        billable: _billable,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(InSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('time_entry'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: tokens.ink,
              ),
            ),
            const SizedBox(height: InSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    onPressed: _pickStartDate,
                    label: Text(_formatDate(_start.toLocal())),
                  ),
                ),
                const SizedBox(width: InSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time, size: 16),
                    onPressed: _pickStartTime,
                    label: Text(_hhmm(_start.toLocal())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: InSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.stop_circle_outlined, size: 16),
                    onPressed: _isRunning ? null : _pickStopTime,
                    label: Text(
                      _isRunning
                          ? context.tr('running')
                          : _hhmm(_stop.toLocal()),
                    ),
                  ),
                ),
                const SizedBox(width: InSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _duration,
                    decoration: InputDecoration(
                      labelText: context.tr('duration'),
                      hintText: '1h 30m',
                    ),
                    onChanged: _onDurationChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: InSpacing.md),
            TextField(
              controller: _description,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(labelText: context.tr('description')),
            ),
            if (widget.allowBillableToggle) ...[
              const SizedBox(height: InSpacing.sm),
              SwitchListTile(
                title: Text(context.tr('billable')),
                value: _billable,
                onChanged: (v) => setState(() => _billable = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
            const SizedBox(height: InSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.allowRemove) ...[
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(64, 40),
                      foregroundColor: tokens.overdue,
                    ),
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(TimeEntryEditorSheet.removeSentinel),
                    child: Text(context.tr('remove')),
                  ),
                  const SizedBox(width: InSpacing.md),
                ],
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 40),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.tr('cancel')),
                ),
                const SizedBox(width: InSpacing.md),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 44),
                  ),
                  onPressed: _commit,
                  child: Text(context.tr('done')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _formatDate(DateTime d) {
    final iso =
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    final f = widget.formatter;
    return f == null ? iso : f.date(iso);
  }
}
