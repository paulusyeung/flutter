import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';

/// Inline chip rendering one [FilterToken] inside the token search field.
///
/// Two shapes:
///  * **Plain** (`token.displayComparator == null`): `<key> <value> ×` —
///    key muted, value bold. The body is one tap target ([onTap]).
///  * **Segmented** (a comparable key — `displayComparator != null`):
///    `<field> | <comparator ▾> | <value ▾> | ×` — each of the three
///    parts is its own tap target so the user can change the comparator
///    or the value independently (Sentry-style). Field is faint, the
///    comparator mid-tone, the value bold; the comparator and value
///    segments carry a ▾ affordance and a hover tint.
///
/// The trailing `×` is always its own interactive node ([onRemove]) and
/// sits OUTSIDE every other tap region so its gesture always wins.
/// [FilterTokenChip.readOnly] is a compact, fully-inert variant for the
/// narrow-mode summary row — it shows the comparator inline but no
/// carets, dividers or `×` (false affordances on an inert chip).
class FilterTokenChip extends StatelessWidget {
  const FilterTokenChip({
    required this.token,
    required this.onRemove,
    this.onTap,
    this.onComparatorTap,
    this.onValueTap,
    super.key,
  }) : readOnly = false;

  const FilterTokenChip.readOnly({required this.token, super.key})
    : onRemove = _noop,
      onTap = null,
      onComparatorTap = null,
      onValueTap = null,
      readOnly = true;

  final FilterToken token;
  final VoidCallback onRemove;

  /// Tap on the field/value of a plain chip, or the field segment of a
  /// segmented chip. Null = inert.
  final VoidCallback? onTap;

  /// Tap on the comparator segment (segmented chips only). The argument
  /// is the segment's global rect, so the caller can anchor a dropdown
  /// at it.
  final void Function(Rect anchorGlobalRect)? onComparatorTap;

  /// Tap on the value segment (segmented chips only). Same contract as
  /// [onComparatorTap].
  final void Function(Rect anchorGlobalRect)? onValueTap;

  final bool readOnly;

  static void _noop() {}

  bool get _segmented =>
      token.displayComparator != null && !readOnly && onTap != null;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final keyStyle = theme.textTheme.bodySmall?.copyWith(
      color: tokens.ink3,
      fontWeight: FontWeight.w500,
    );
    final comparatorStyle = theme.textTheme.bodySmall?.copyWith(
      color: tokens.ink2,
      fontWeight: FontWeight.w500,
    );
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
      color: tokens.ink,
      fontWeight: FontWeight.w600,
    );

    final decoration = BoxDecoration(
      color: readOnly ? tokens.surface : tokens.surfaceAlt,
      // Project rule: rounded rectangles, never pills.
      borderRadius: BorderRadius.circular(InRadii.r1),
      border: Border.all(color: tokens.border),
    );

    if (_segmented) {
      return Semantics(
        container: true,
        child: Container(
          decoration: decoration,
          padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 4, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Segment(
                onTap: onTap == null ? null : (_) => onTap!(),
                semanticLabel:
                    '${token.displayKey}, ${context.tr('filter_field')}',
                child: Text(token.displayKey.toLowerCase(), style: keyStyle),
              ),
              _divider(tokens),
              _Segment(
                onTap: onComparatorTap,
                semanticLabel:
                    '${token.displayComparator}, '
                    '${context.tr('change_comparator')}',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(token.displayComparator!, style: comparatorStyle),
                    _caret(tokens),
                  ],
                ),
              ),
              _divider(tokens),
              _Segment(
                onTap: onValueTap,
                semanticLabel:
                    '${token.displayValue}, ${context.tr('change_value')}',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _maybeTooltip(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Text(
                          token.displayValue,
                          style: valueStyle,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ),
                    _caret(tokens),
                  ],
                ),
              ),
              _closeButton(context, tokens),
            ],
          ),
        ),
      );
    }

    // ── Plain chip (non-comparable, or read-only summary) ──
    final body = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(token.displayKey.toLowerCase(), style: keyStyle),
        const SizedBox(width: 4),
        if (token.displayComparator != null) ...[
          Text(token.displayComparator!, style: comparatorStyle),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            token.displayValue,
            style: valueStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final tappableBody = onTap != null
        ? MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: body,
            ),
          )
        : body;

    return Semantics(
      button: onTap != null,
      label:
          '${context.tr('filter_label_prefix')}: '
          '${token.displayKey} '
          '${token.displayComparator == null ? '' : '${token.displayComparator} '}'
          '${token.displayValue}',
      child: Container(
        decoration: decoration,
        padding: readOnly
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
            : const EdgeInsetsDirectional.fromSTEB(10, 4, 4, 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            tappableBody,
            if (!readOnly) ...[
              const SizedBox(width: 2),
              _closeButton(context, tokens),
            ],
          ],
        ),
      ),
    );
  }

  Widget _maybeTooltip(Widget child) => token.valueTooltip == null
      ? child
      : Tooltip(message: token.valueTooltip!, child: child);

  Widget _divider(InTheme tokens) => Container(
    width: 1,
    height: 14,
    color: tokens.border,
    margin: const EdgeInsets.symmetric(horizontal: 6),
  );

  Widget _caret(InTheme tokens) => Padding(
    padding: const EdgeInsets.only(left: 1),
    child: Icon(Icons.arrow_drop_down, size: 14, color: tokens.ink3),
  );

  Widget _closeButton(BuildContext context, InTheme tokens) {
    if (readOnly) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: IconButton(
        tooltip: context.tr('clear_filter'),
        iconSize: 14,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        // 24×24 hit slop — under that, iOS HIG reports the button as
        // below the minimum touch target. Icon stays 14 px for density.
        constraints: const BoxConstraints(minHeight: 24, minWidth: 24),
        onPressed: onRemove,
        icon: Icon(Icons.close, color: tokens.ink3),
      ),
    );
  }
}

/// One tappable region of a segmented chip. Pointer cursor + a subtle
/// `surface→surfaceAlt`-style hover tint so the boundaries are
/// discoverable before the click (mirrors the suggestion menu's
/// `_Highlightable` hover model). Inert when [onTap] is null.
class _Segment extends StatefulWidget {
  const _Segment({
    required this.child,
    required this.semanticLabel,
    this.onTap,
  });

  final Widget child;
  final String semanticLabel;

  /// Receives this segment's global rect so the caller can anchor a
  /// dropdown directly at it. Null = inert.
  final void Function(Rect anchorGlobalRect)? onTap;

  @override
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: widget.child,
    );
    if (widget.onTap == null) return content;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final box = context.findRenderObject();
            if (box is! RenderBox || !box.attached) return;
            widget.onTap!(box.localToGlobal(Offset.zero) & box.size);
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _hovered ? tokens.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(InRadii.r1),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
