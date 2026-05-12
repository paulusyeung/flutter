import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/ui/core/widgets/widget_preview_support.dart';

/// Small status pill — colored dot + label on a tinted-soft background.
/// The v2 system uses this shape everywhere an entity needs a state cue
/// (deleted / archived / unsynced on the clients list; paid / overdue /
/// draft / sent on invoices once they land).
///
/// Colors are passed in by the caller so this widget stays neutral:
/// pick (`fgColor`, `bgColor`) pairs from `InTheme` (e.g.
/// `paid` + `paidSoft`, `overdue` + `overdueSoft`, `sent` + `sentSoft`).
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.fgColor,
    required this.bgColor,
    this.tooltip,
  });

  final String label;
  final Color fgColor;
  final Color bgColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: fgColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fgColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
    if (tooltip == null) return pill;
    return Tooltip(message: tooltip!, child: pill);
  }
}

@Preview(name: 'All statuses', group: 'StatusPill', theme: appPreviewTheme)
Widget previewStatusPillAll() {
  return Builder(
    builder: (context) {
      final t = context.inTheme;
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusPill(label: 'Paid', fgColor: t.paid, bgColor: t.paidSoft),
            StatusPill(
              label: 'Overdue',
              fgColor: t.overdue,
              bgColor: t.overdueSoft,
            ),
            StatusPill(label: 'Sent', fgColor: t.sent, bgColor: t.sentSoft),
            StatusPill(label: 'Draft', fgColor: t.draft, bgColor: t.draftSoft),
          ],
        ),
      );
    },
  );
}
