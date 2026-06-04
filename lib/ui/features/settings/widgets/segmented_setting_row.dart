import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';

// Width of the SizedBox we wrap every segment label in. Pins each segment's
// intrinsic width so the buttons line up across rows.
const double _kSegmentLabelWidth = 80;

// Below this row width a ~320px multi-segment SegmentedButton no longer fits in
// a ListTile's trailing slot — `_RenderListTile` throws "Trailing widget
// consumes the entire tile width". [SegmentedSettingRow] stacks the button on
// its own row under that width instead.
const double _kWideRowThreshold = 520;

/// A fixed-width, centered, single-line segment label so segmented buttons line
/// up column-to-column across settings rows. Shared by the theme rows and the
/// font-size row on Device Settings.
Widget segmentLabel(BuildContext context, String key) {
  return SizedBox(
    width: _kSegmentLabelWidth,
    child: Center(
      child: Text(
        context.tr(key),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}

/// A settings row with a leading icon, a title + subtitle, and a wide
/// [SegmentedButton] control.
///
/// On a window at least [_kWideRowThreshold] wide the control sits in the
/// `ListTile.trailing` slot (the compact, right-aligned look). Below that width
/// the button overflows the tile — `_RenderListTile` throws "Trailing widget
/// consumes the entire tile width" — so the control drops to its own full-width
/// row beneath the title, with a horizontal-scroll guard for sub-320px widths.
class SegmentedSettingRow extends StatelessWidget {
  const SegmentedSettingRow({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.control,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _kWideRowThreshold) {
          return ListTile(
            leading: leading,
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: control,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: leading,
              title: Text(title),
              subtitle: Text(subtitle),
            ),
            Padding(
              // Match ListTile's default 16px horizontal content inset so the
              // control lines up with the tile edges; horizontal scroll is a
              // guard for sub-320px widths where the button is wider than the
              // row.
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: control,
              ),
            ),
          ],
        );
      },
    );
  }
}
