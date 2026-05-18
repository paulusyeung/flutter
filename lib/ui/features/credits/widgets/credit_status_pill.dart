import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/credit_status.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/status_bounce_overlay.dart';
import 'package:admin/ui/core/widgets/status_pill.dart';

/// Compact status badge for the credits list + detail screens. Mirrors the
/// invoice / quote status pill shape; color mapping reflects credits'
/// lifecycle (no "paid" — applied is the terminal state and is green).
class CreditStatusPill extends StatelessWidget {
  const CreditStatusPill({
    super.key,
    required this.statusId,
    this.dotSize = 8,
    this.textStyle,
    this.hasBounce = false,
  });

  final String statusId;
  final double dotSize;
  final TextStyle? textStyle;

  /// Overlays a red alert badge when an invitation bounced/errored
  /// (`credit.hasBouncedInvitation`).
  final bool hasBounce;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final colors = _colorsForStatus(tokens, statusId);
    final name = context.tr(creditStatusLabelKey(statusId));
    return StatusBounceOverlay(
      hasBounce: hasBounce,
      child: StatusPill(
        label: name,
        fgColor: colors.fg,
        bgColor: colors.bg,
        dotSize: dotSize,
        textStyle: textStyle ?? TextStyle(fontSize: 13, color: tokens.ink),
      ),
    );
  }
}

({Color fg, Color bg}) _colorsForStatus(InTheme tokens, String id) {
  switch (id) {
    case '4': // applied
      return (fg: tokens.paid, bg: tokens.paidSoft);
    case '3': // partial
      return (fg: tokens.partial, bg: tokens.partialSoft);
    case '2': // sent
    case '-2': // viewed (computed)
      return (fg: tokens.sent, bg: tokens.sentSoft);
    case '1': // draft
    default:
      return (fg: tokens.draft, bg: tokens.draftSoft);
  }
}
