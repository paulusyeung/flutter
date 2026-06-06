import 'package:flutter/widgets.dart';

/// Max width for a single-column entity form / detail card stack. When an
/// edit layout or detail grid falls back to one column (slide-over pane, or
/// a full-width pane narrower than [Breakpoints.entityFormMultiColumn]), the
/// column is centered and capped here so fields don't stretch edge-to-edge.
///
/// 820 px matches the long-standing task-edit cap (its time-log table needs
/// ~792 px), keeping every entity form on one number.
const double kEntityFormMaxWidth = 820;

/// Centers [child] and caps its width at [maxWidth] (default
/// [kEntityFormMaxWidth]). A no-op when the available width is already below
/// [maxWidth] (e.g. the 440–560 px slide-over pane), so it only bites on a
/// wide full-width pane.
///
/// `Center(ConstrainedBox(...))` shrink-wraps on any unbounded axis, so this
/// is safe inside a vertical `SingleChildScrollView` or a stretch `Column`.
class CenteredFormColumn extends StatelessWidget {
  const CenteredFormColumn({
    super.key,
    required this.child,
    this.maxWidth = kEntityFormMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
