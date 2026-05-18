import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/activity.dart';
import 'package:admin/ui/features/billing_shared/activity/activity_description.dart';
import 'package:admin/ui/features/dashboard/helpers/activity_formatter.dart';
import 'package:admin/utils/formatting.dart';

/// One synced activity / comment row, shared by every detail-screen Activity
/// tab. Renders a tone-colored icon badge, the templated + linked sentence
/// (`buildActivitySpans`), and a relative timestamp with the absolute
/// company-formatted date+time as a tooltip.
class ActivityRecordRow extends StatefulWidget {
  const ActivityRecordRow({
    required this.activity,
    required this.formatter,
    this.isLast = false,
    super.key,
  });

  final Activity activity;
  final Formatter? formatter;

  /// Suppresses the bottom divider on the final row so the card-less,
  /// flush Activity tab doesn't end with a stray rule (mirrors the entity
  /// list tiles' `isLast`).
  final bool isLast;

  @override
  State<ActivityRecordRow> createState() => _ActivityRecordRowState();
}

class _ActivityRecordRowState extends State<ActivityRecordRow> {
  ActivitySpans? _spans;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rebuildSpans();
  }

  @override
  void didUpdateWidget(ActivityRecordRow old) {
    super.didUpdateWidget(old);
    if (old.activity != widget.activity) _rebuildSpans();
  }

  void _rebuildSpans() {
    _spans?.dispose();
    final theme = Theme.of(context);
    final tokens = context.inTheme;
    final body = theme.textTheme.bodyMedium ?? const TextStyle();
    _spans = buildActivitySpans(
      context,
      widget.activity,
      base: body.copyWith(color: tokens.ink),
      strong: body.copyWith(fontWeight: FontWeight.w600, color: tokens.ink),
      link: body.copyWith(
        fontWeight: FontWeight.w600,
        color: tokens.accent,
      ),
    );
  }

  @override
  void dispose() {
    _spans?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final a = widget.activity;
    final tone = activityToneFor(a.activityTypeId);
    final (bg, fg) = activityToneColors(tokens, tone);
    final icon = a.isComment
        ? Icons.comment_outlined
        : activityIconFor(tone);

    final relative = formatRelativeTime(
      context,
      DateTime.now().difference(a.createdAt),
    );
    final absolute =
        widget.formatter?.date(
          a.createdAt.toIso8601String(),
          showTime: true,
          showSeconds: false,
        ) ??
        a.createdAt.toIso8601String();
    final meta = a.ip.isNotEmpty ? '$relative · ${a.ip}' : relative;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: widget.isLast
              ? BorderSide.none
              : BorderSide(color: tokens.border),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(InRadii.r2),
            ),
            child: Icon(icon, size: 16, color: fg),
          ),
          SizedBox(width: InSpacing.md(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(children: _spans?.spans ?? const []),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Tooltip(
                  message: absolute,
                  child: Text(
                    meta,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.ink3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
