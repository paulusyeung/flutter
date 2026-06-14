import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/api/calendar_connection_api_model.dart';
import 'package:admin/utils/formatting.dart';

/// One calendar-event chip in a day cell. Visually distinct from task chips (a
/// tinted accent fill + event icon) so the two data sources read apart. Tapping
/// opens the convert-to-task sheet.
///
/// Uses a [GestureDetector] (not `InkWell`) deliberately: an `InkWell` over a
/// tinted accent fill paints an opaque hover overlay on macOS — the known
/// `accentSoft` quirk — so we drive the tap directly.
class CalendarEventChip extends StatelessWidget {
  const CalendarEventChip({
    super.key,
    required this.event,
    required this.onTap,
    this.formatter,
  });

  final CalendarEvent event;
  final VoidCallback onTap;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final time = _timeLabel();
    final label = time == null ? event.title : '$time  ${event.title}';
    return Tooltip(
      message: event.title,
      waitDuration: const Duration(milliseconds: 300),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: tokens.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(InRadii.r1),
            border: Border.all(color: tokens.accent.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event, size: 10, color: tokens.accent),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: tokens.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _timeLabel() {
    if (event.allDay) return null;
    final start = event.startLocal;
    if (start == null) return null;
    final military = formatter?.settings.enableMilitaryTime ?? false;
    return formatTimeOfDay(start.hour, start.minute, military: military);
  }
}
