import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/time_entry.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/tasks/widgets/running_duration_label.dart';
import 'package:admin/utils/formatting.dart';

/// Summary row for a single `TimeEntry`. Tapping anywhere opens the full
/// `TimeEntryEditorSheet`. Running entries show the pulsing accent dot +
/// live-ticking duration; stopped entries show a static duration.
class TimeEntryRow extends StatelessWidget {
  const TimeEntryRow({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onRemove,
    this.enabled = true,
  });

  final TimeEntry entry;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final start = entry.start;
    final stop = entry.stop;
    final dateLabel = start == null
        ? '—'
        : '${start.toLocal().toString().split(' ').first} '
              '${_hhmm(start.toLocal())}'
              '${stop == null ? '' : ' – ${_hhmm(stop.toLocal())}'}';

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: InSpacing.md,
          vertical: InSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: entry.isRunning
              ? tokens.accentSoft.withValues(alpha: 0.3)
              : null,
          border: Border(bottom: BorderSide(color: tokens.border)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 220,
              child: Text(
                dateLabel,
                style: TextStyle(color: tokens.ink2, fontSize: 13),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry.description.isEmpty ? '—' : entry.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: tokens.ink, fontSize: 13),
              ),
            ),
            const SizedBox(width: 12),
            if (entry.isRunning && entry.start != null)
              RunningDurationLabel(start: entry.start!)
            else
              Text(
                formatDuration(
                  start != null && stop != null
                      ? stop.difference(start)
                      : Duration.zero,
                  compactDays: true,
                ),
                style: TextStyle(
                  color: tokens.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            if (!entry.billable) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: context.tr('non_billable'),
                child: Icon(
                  Icons.money_off_outlined,
                  size: 14,
                  color: tokens.ink3,
                ),
              ),
            ],
            if (enabled) ...[
              const SizedBox(width: 6),
              IconButton(
                tooltip: context.tr('remove'),
                icon: const Icon(Icons.close, size: 16),
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
