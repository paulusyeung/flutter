import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/task.dart';
import 'package:admin/data/models/domain/time_entry.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/tasks/widgets/running_duration_label.dart';
import 'package:admin/utils/formatting.dart';

/// Cards stacked under the detail header: Details / Time Log (read-only)
/// / Client link / Custom Fields.
class TaskDetailCards extends StatelessWidget {
  const TaskDetailCards({
    super.key,
    required this.task,
    required this.companyId,
    this.formatter,
  });

  final Task task;
  final String companyId;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailsCard(task: task, formatter: formatter),
        const SizedBox(height: InSpacing.lg),
        _TimeLogCard(task: task),
        if (task.clientId.isNotEmpty) ...[
          const SizedBox(height: InSpacing.lg),
          _ClientCard(task: task),
        ],
        if (_hasAnyCustomValue(task)) ...[
          const SizedBox(height: InSpacing.lg),
          _CustomFieldsCard(task: task),
        ],
      ],
    );
  }
}

bool _hasAnyCustomValue(Task t) =>
    t.customValue1.isNotEmpty ||
    t.customValue2.isNotEmpty ||
    t.customValue3.isNotEmpty ||
    t.customValue4.isNotEmpty;

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(InRadii.r3),
      ),
      padding: const EdgeInsets.all(InSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tokens.ink3,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: InSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: tokens.ink3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DefaultTextStyle.merge(
              child: value,
              style: TextStyle(fontSize: 13, color: tokens.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.task, required this.formatter});
  final Task task;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: context.tr('details').toUpperCase(),
      child: Column(
        children: [
          _Row(
            label: context.tr('number'),
            value: Text(task.number.isEmpty ? '—' : task.number),
          ),
          _Row(
            label: context.tr('description'),
            value: Text(task.description.isEmpty ? '—' : task.description),
          ),
          _Row(
            label: context.tr('rate'),
            value: Text(
              formatter?.money(task.rate) ?? task.rate.toStringAsFixed(2),
            ),
          ),
          _Row(
            label: context.tr('total_duration'),
            value: Text(
              formatDuration(task.totalDuration(), compactDays: true),
            ),
          ),
          if (task.isInvoiced)
            _Row(
              label: context.tr('invoice'),
              value: Text(context.tr('invoiced')),
            ),
        ],
      ),
    );
  }
}

class _TimeLogCard extends StatelessWidget {
  const _TimeLogCard({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    if (task.timeLog.isEmpty) {
      return _Card(
        title: context.tr('time_log').toUpperCase(),
        child: Text(
          context.tr('no_entries'),
          style: TextStyle(color: tokens.ink3),
        ),
      );
    }
    final entries = task.timeLog.reversed.toList(growable: false);
    return _Card(
      title: context.tr('time_log').toUpperCase(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < entries.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
              child: _TimeEntrySummary(entry: entries[i]),
            ),
        ],
      ),
    );
  }
}

class _TimeEntrySummary extends StatelessWidget {
  const _TimeEntrySummary({required this.entry});
  final TimeEntry entry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final start = entry.start;
    final stop = entry.stop;
    final dateLabel = start == null
        ? '—'
        : '${start.toLocal().toString().split(' ').first} '
              '${_hhmm(start.toLocal())}';
    return Row(
      children: [
        SizedBox(
          width: 200,
          child: Text(
            dateLabel,
            style: TextStyle(color: tokens.ink2, fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            entry.description.isEmpty ? '—' : entry.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: tokens.ink, fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        if (entry.isRunning && entry.start != null)
          RunningDurationLabel(
            start: entry.start!,
            precision: const Duration(seconds: 1),
          )
        else
          Text(
            formatDuration(
              stop == null || start == null
                  ? Duration.zero
                  : stop.difference(start),
              compactDays: true,
            ),
            style: TextStyle(
              color: tokens.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        if (!entry.billable) ...[
          const SizedBox(width: 8),
          Tooltip(
            message: context.tr('non_billable'),
            child: Icon(Icons.money_off_outlined, size: 14, color: tokens.ink3),
          ),
        ],
      ],
    );
  }

  String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final me = context.read<Services>().auth.session.value?.currentCompany;
    final canView = me?.can('view_client') ?? false;
    return _Card(
      title: context.tr('client').toUpperCase(),
      child: InkWell(
        onTap: canView ? () => context.go('/clients/${task.clientId}') : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.person_outline, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(task.clientId, overflow: TextOverflow.ellipsis),
              ),
              if (canView) const Icon(Icons.chevron_right, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomFieldsCard extends StatelessWidget {
  const _CustomFieldsCard({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: context.tr('custom_fields').toUpperCase(),
      child: Column(
        children: [
          if (task.customValue1.isNotEmpty)
            _Row(
              label: context.tr('custom_value1'),
              value: Text(task.customValue1),
            ),
          if (task.customValue2.isNotEmpty)
            _Row(
              label: context.tr('custom_value2'),
              value: Text(task.customValue2),
            ),
          if (task.customValue3.isNotEmpty)
            _Row(
              label: context.tr('custom_value3'),
              value: Text(task.customValue3),
            ),
          if (task.customValue4.isNotEmpty)
            _Row(
              label: context.tr('custom_value4'),
              value: Text(task.customValue4),
            ),
        ],
      ),
    );
  }
}
