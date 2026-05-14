import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/models/domain/project.dart';
import 'package:admin/data/models/domain/task.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_link_card.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/ui/features/tasks/widgets/running_duration_label.dart';
import 'package:admin/utils/formatting.dart';

/// Cards stacked under the detail header: Details / Budget / Client link /
/// Tasks / Custom Fields. Uses `DashboardCardShell` for chrome so the
/// detail looks the same as Product detail and the project edit form.
class ProjectDetailCards extends StatelessWidget {
  const ProjectDetailCards({
    super.key,
    required this.project,
    required this.companyId,
    this.formatter,
  });

  final Project project;
  final String companyId;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailsCard(project: project, formatter: formatter),
        SizedBox(height: InSpacing.lg(context)),
        _BudgetCard(project: project),
        if (project.clientId.isNotEmpty) ...[
          SizedBox(height: InSpacing.lg(context)),
          EntityLinkCard<Client>(
            titleKey: 'client',
            icon: Icons.person_outline,
            entityId: project.clientId,
            routePath: '/clients/${project.clientId}',
            permissionKey: 'view_client',
            watchBuilder: () => context.read<Services>().clients.watch(
              companyId: companyId,
              id: project.clientId,
            ),
            displayNameOf: (c) =>
                c.displayName.isNotEmpty ? c.displayName : c.name,
          ),
        ],
        SizedBox(height: InSpacing.lg(context)),
        _TasksCard(
          project: project,
          companyId: companyId,
          formatter: formatter,
        ),
        if (_hasAnyCustomValue(project)) ...[
          SizedBox(height: InSpacing.lg(context)),
          _CustomFieldsCard(project: project),
        ],
      ],
    );
  }
}

bool _hasAnyCustomValue(Project p) =>
    p.customValue1.isNotEmpty ||
    p.customValue2.isNotEmpty ||
    p.customValue3.isNotEmpty ||
    p.customValue4.isNotEmpty;

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
  const _DetailsCard({required this.project, required this.formatter});
  final Project project;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final p = project;
    final f = formatter;
    final dueDateText = p.dueDate == null
        ? '—'
        : (f == null ? p.dueDate!.toIso() : f.date(p.dueDate!.toIso()));
    return DashboardCardShell(
      title: context.tr('details'),
      child: Column(
        children: [
          _Row(
            label: context.tr('number'),
            value: Text(p.number.isEmpty ? '—' : p.number),
          ),
          _Row(label: context.tr('due_date'), value: Text(dueDateText)),
          _Row(
            label: context.tr('task_rate'),
            value: Text(
              f == null ? p.taskRate.toString() : f.money(p.taskRate),
            ),
          ),
          if (p.color.isNotEmpty)
            _Row(
              label: context.tr('color'),
              value: _ColorSwatchPreview(hex: p.color),
            ),
          if (p.publicNotes.isNotEmpty)
            _Row(label: context.tr('public_notes'), value: Text(p.publicNotes)),
          if (p.privateNotes.isNotEmpty)
            _Row(
              label: context.tr('private_notes'),
              value: Text(p.privateNotes),
            ),
        ],
      ),
    );
  }
}

/// "Logged X h (Y%)" / "Budgeted Z h" pair. Logged-hours color shifts at
/// 80% / 100% to flag overruns.
class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.project});
  final Project project;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final p = project;
    final hasBudget = p.budgetedHours > 0;
    final pct = hasBudget ? (p.currentHours / p.budgetedHours) * 100 : null;
    Color loggedColor;
    if (!hasBudget || pct == null) {
      loggedColor = tokens.ink;
    } else if (pct <= 80) {
      loggedColor = tokens.ink;
    } else if (pct <= 100) {
      loggedColor = tokens.draft; // amber-toned warning
    } else {
      loggedColor = tokens.overdue;
    }
    return DashboardCardShell(
      title: context.tr('budget'),
      child: Column(
        children: [
          _Row(
            label: context.tr('logged'),
            value: Text(
              hasBudget
                  ? '${_fmtHours(p.currentHours)} h (${pct!.round()}%)'
                  : '${_fmtHours(p.currentHours)} h',
              style: TextStyle(
                color: loggedColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (hasBudget)
            _Row(
              label: context.tr('budgeted'),
              value: Text(
                '${_fmtHours(p.budgetedHours)} h',
                style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ColorSwatchPreview extends StatelessWidget {
  const _ColorSwatchPreview({required this.hex});
  final String hex;

  @override
  Widget build(BuildContext context) {
    final color = _parseHex(hex);
    final tokens = context.inTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color ?? Colors.transparent,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: tokens.border),
          ),
        ),
        const SizedBox(width: 8),
        // The hex string is metadata next to the swatch — render in muted
        // monospace so it reads as a value tag, not as content.
        Text(
          hex,
          style: TextStyle(
            fontSize: 12,
            color: tokens.ink3,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _TasksCard extends StatelessWidget {
  const _TasksCard({
    required this.project,
    required this.companyId,
    required this.formatter,
  });
  final Project project;
  final String companyId;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final tokens = context.inTheme;
    return DashboardCardShell(
      title: context.tr('tasks'),
      trailing: DashboardCardFooterLink(
        label: context.tr('add_task'),
        onTap: () => context.go('/tasks/new?project=${project.id}'),
      ),
      child: StreamBuilder<List<Task>>(
        stream: services.tasks.watchForProject(
          companyId: companyId,
          projectId: project.id,
        ),
        builder: (context, snapshot) {
          final tasks = snapshot.data ?? const <Task>[];
          if (tasks.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                context.tr('no_tasks_for_project'),
                style: TextStyle(
                  color: tokens.ink3,
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < tasks.length; i++)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 6, bottom: 6),
                  child: _TaskRow(task: tasks[i]),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final identity = task.description.isNotEmpty
        ? task.description
        : (task.number.isNotEmpty
              ? '#${task.number}'
              : context.tr('no_name_fallback'));
    return InkWell(
      onTap: () => context.go('/tasks/${task.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(Icons.task_outlined, size: 16, color: tokens.ink3),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                identity,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (task.isRunning &&
                task.timeLog.isNotEmpty &&
                task.timeLog.last.start != null)
              RunningDurationLabel(
                start: task.timeLog.last.start!,
                precision: const Duration(seconds: 1),
              )
            else
              Text(
                formatDuration(task.totalDuration(), compactDays: true),
                style: TextStyle(
                  color: tokens.ink2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            const Icon(Icons.chevron_right, size: 16),
          ],
        ),
      ),
    );
  }
}

class _CustomFieldsCard extends StatelessWidget {
  const _CustomFieldsCard({required this.project});
  final Project project;

  @override
  Widget build(BuildContext context) {
    return DashboardCardShell(
      title: context.tr('custom_fields'),
      child: Column(
        children: [
          if (project.customValue1.isNotEmpty)
            _Row(
              label: context.tr('custom_value1'),
              value: Text(project.customValue1),
            ),
          if (project.customValue2.isNotEmpty)
            _Row(
              label: context.tr('custom_value2'),
              value: Text(project.customValue2),
            ),
          if (project.customValue3.isNotEmpty)
            _Row(
              label: context.tr('custom_value3'),
              value: Text(project.customValue3),
            ),
          if (project.customValue4.isNotEmpty)
            _Row(
              label: context.tr('custom_value4'),
              value: Text(project.customValue4),
            ),
        ],
      ),
    );
  }
}

String _fmtHours(double h) {
  if (h.truncate().toDouble() == h) return h.toInt().toString();
  return h.toStringAsFixed(1);
}

/// Parse a `#RRGGBB` or `RRGGBB` hex string to a [Color]. Returns null on
/// malformed input so the swatch falls back to transparent.
Color? _parseHex(String hex) {
  var s = hex.trim();
  if (s.startsWith('#')) s = s.substring(1);
  if (s.length != 6) return null;
  final v = int.tryParse(s, radix: 16);
  if (v == null) return null;
  return Color(0xFF000000 | v);
}
