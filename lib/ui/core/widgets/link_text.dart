import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/ui/core/widgets/widget_preview_support.dart';

/// Text styled as a link: underline on hover with the click cursor. Used
/// to mark clickable text inside larger tap surfaces (table cells inside a
/// `TableRowInkWell`, "View all" labels inside an `InkWell`, etc.) so the
/// word reads as a navigable link before the user mouses over it.
///
/// When [onTap] is non-null the widget also handles the tap itself; when
/// null, it's a pure visual that relies on an ancestor (`InkWell` /
/// `TableRowInkWell`) to handle the tap.
class LinkText extends StatefulWidget {
  const LinkText({
    super.key,
    required this.label,
    this.style,
    this.color,
    this.hoverColor,
    this.onTap,
    this.maxLines,
    this.overflow,
    this.enabled = true,
    this.alwaysUnderline = false,
  });

  final String label;

  /// Base text style. The widget applies `color` and the hover underline on
  /// top of it.
  final TextStyle? style;

  /// Resting color. Defaults to the [style]'s color, or `tokens.ink` if the
  /// style doesn't set one. Override to give the link a different tone.
  final Color? color;

  /// Hover color. Defaults to the same as [color] (underline alone is the
  /// hover cue); pass a brighter tone for an extra emphasis bump.
  final Color? hoverColor;

  final VoidCallback? onTap;
  final int? maxLines;
  final TextOverflow? overflow;

  /// When false, the widget renders as plain text (no hover, no underline,
  /// no cursor change). Used for disabled link states (e.g. "Refresh" while
  /// a refresh is already in flight).
  final bool enabled;

  /// When true the underline is always shown, not only on hover — an
  /// at-rest affordance for places where the link is the consequential
  /// target and hover isn't available (touch). The default (false) keeps
  /// the lighter hover-only treatment used inside dense lists.
  final bool alwaysUnderline;

  @override
  State<LinkText> createState() => _LinkTextState();
}

class _LinkTextState extends State<LinkText> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final resolvedColor = widget.color ?? widget.style?.color ?? tokens.ink;
    final resolvedHover = widget.hoverColor ?? resolvedColor;
    final base = widget.style ?? const TextStyle();
    final showUnderline =
        widget.enabled && (_hovering || widget.alwaysUnderline);
    final effective = base.copyWith(
      color: widget.enabled
          ? (_hovering ? resolvedHover : resolvedColor)
          : base.color,
      decoration: showUnderline
          ? TextDecoration.underline
          : TextDecoration.none,
      decorationColor: showUnderline
          ? (_hovering ? resolvedHover : resolvedColor)
          : null,
    );
    Widget text = Text(
      widget.label,
      style: effective,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
    if (!widget.enabled) return text;
    if (widget.onTap != null) {
      text = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: text,
      );
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: text,
    );
  }
}

/// Render [label] as a hover-underlined [LinkText] when [link] is true and
/// an [onTap] is supplied, otherwise as plain [Text]. The link variant is a
/// touch bolder (`w500`) than the surrounding cell so a cross-entity
/// reference reads as navigable at rest without an at-rest underline.
/// Shared by the `*NameLabel` widgets so column cells and mobile tiles
/// stay consistent.
Widget linkOrText({
  required bool link,
  required String label,
  VoidCallback? onTap,
  TextStyle? style,
  int? maxLines,
  TextOverflow? overflow,
}) {
  if (!link || onTap == null) {
    return Text(label, style: style, maxLines: maxLines, overflow: overflow);
  }
  return LinkText(
    label: label,
    onTap: onTap,
    style: (style ?? const TextStyle()).copyWith(fontWeight: FontWeight.w500),
    maxLines: maxLines,
    overflow: overflow,
  );
}

@Preview(name: 'Default', group: 'LinkText', theme: appPreviewTheme)
Widget previewLinkText() {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: LinkText(label: 'invoiceninja.com', onTap: () {}),
  );
}

@Preview(name: 'Disabled', group: 'LinkText', theme: appPreviewTheme)
Widget previewLinkTextDisabled() {
  return const Padding(
    padding: EdgeInsets.all(16),
    child: LinkText(label: 'Refreshing…', enabled: false),
  );
}
