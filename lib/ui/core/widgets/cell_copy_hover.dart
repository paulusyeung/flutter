import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/l10n/localization.dart';

/// Wraps a table cell with a hover-reveal copy icon.
///
/// When [value] is null or empty the wrapper is a no-op and the [child] is
/// rendered unchanged. Otherwise a small icon chip fades in on mouse hover
/// at the trailing edge (or leading edge for end-aligned cells, so it
/// doesn't overlap the right-justified value). Clicking the icon writes
/// [value] to the system clipboard and surfaces the standard
/// `copied_to_clipboard` snackbar.
///
/// Mouse-only — `MouseRegion`'s `onEnter`/`onExit` never fire on touch, so
/// iOS/Android render the wrapper transparently with no extra affordance.
class CellCopyHover extends StatefulWidget {
  const CellCopyHover({
    super.key,
    required this.child,
    required this.value,
    this.align = ColumnAlign.start,
  });

  final Widget child;
  final String? value;
  final ColumnAlign align;

  @override
  State<CellCopyHover> createState() => _CellCopyHoverState();
}

class _CellCopyHoverState extends State<CellCopyHover> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    if (value == null || value.isEmpty) return widget.child;

    final isEnd = widget.align == ColumnAlign.end;
    final tokens = context.inTheme;

    return MouseRegion(
      onEnter: (_) {
        if (!_hovering) setState(() => _hovering = true);
      },
      onExit: (_) {
        if (_hovering) setState(() => _hovering = false);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          Positioned.directional(
            textDirection: Directionality.of(context),
            top: 0,
            bottom: 0,
            start: isEnd ? 0 : null,
            end: isEnd ? null : 0,
            child: IgnorePointer(
              ignoring: !_hovering,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 100),
                opacity: _hovering ? 1.0 : 0.0,
                child: Center(
                  child: _CopyButton(value: value, tokens: tokens),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.value, required this.tokens});

  final String value;
  final InTheme tokens;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(InRadii.r1);
    return Tooltip(
      message: context.tr('copy'),
      waitDuration: const Duration(milliseconds: 400),
      child: Material(
        color: tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: tokens.border),
        ),
        child: InkWell(
          onTap: () => _copy(context),
          borderRadius: radius,
          child: SizedBox(
            width: 22,
            height: 22,
            child: Icon(Icons.content_copy, size: 14, color: tokens.ink3),
          ),
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = context.tr('copied_to_clipboard', {
      'value': _ellipsize(value),
    });
    await Clipboard.setData(ClipboardData(text: value));
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

String _ellipsize(String s, {int max = 40}) {
  if (s.length <= max) return s;
  return '${s.substring(0, max)}…';
}
