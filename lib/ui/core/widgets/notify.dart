import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/ui/core/adaptive.dart';

/// App-wide toast / snackbar helper.
///
/// Use [Notify.success], [Notify.error], [Notify.info], [Notify.warning] in
/// place of `ScaffoldMessenger.of(context).showSnackBar(...)`. Each variant
/// renders a card on `tokens.surface` with a colored left stripe and a
/// matching leading icon, picked from the v2 status tokens so the toast
/// reads as part of the same family as `StatusPill`.
///
/// All variants float, round to [InRadii.r2], and dismiss any currently
/// visible snackbar before showing — chatty flows (rapid save → save) feel
/// responsive instead of queueing several seconds of stale messages.
///
/// Pass [messenger] when the [BuildContext] may be unmounted by the time the
/// toast needs to fire (e.g. after popping the calling sheet). Capture it
/// before the await: `final m = ScaffoldMessenger.maybeOf(context);`.
class Notify {
  Notify._();

  /// Quick green confirmation — "Saved", "Archived", etc.
  static void success(
    BuildContext context,
    String message, {
    String? detail,
    NotifyAction? action,
    ScaffoldMessengerState? messenger,
  }) => _show(
    context,
    variant: _Variant.success,
    message: message,
    detail: detail,
    action: action,
    messenger: messenger,
  );

  /// Red error notification. Pass either [detail] or [error]; if both are
  /// passed [detail] wins. [error] is run through a minimal formatter that
  /// strips common Dart exception prefixes so users don't see
  /// `Exception: ...` noise.
  static void error(
    BuildContext context,
    String message, {
    String? detail,
    Object? error,
    NotifyAction? action,
    ScaffoldMessengerState? messenger,
  }) => _show(
    context,
    variant: _Variant.error,
    message: message,
    detail: detail ?? (error == null ? null : _formatError(error)),
    action: action,
    messenger: messenger,
  );

  /// Amber warning — validation failures, soft limits.
  static void warning(
    BuildContext context,
    String message, {
    String? detail,
    NotifyAction? action,
    ScaffoldMessengerState? messenger,
  }) => _show(
    context,
    variant: _Variant.warning,
    message: message,
    detail: detail,
    action: action,
    messenger: messenger,
  );

  /// Blue informational — "Copied", "Coming soon", neutral notices.
  static void info(
    BuildContext context,
    String message, {
    String? detail,
    NotifyAction? action,
    ScaffoldMessengerState? messenger,
  }) => _show(
    context,
    variant: _Variant.info,
    message: message,
    detail: detail,
    action: action,
    messenger: messenger,
  );

  static void _show(
    BuildContext context, {
    required _Variant variant,
    required String message,
    String? detail,
    NotifyAction? action,
    ScaffoldMessengerState? messenger,
  }) {
    final m = messenger ?? ScaffoldMessenger.maybeOf(context);
    if (m == null) return;
    // On wide windows, pin the SnackBar to a fixed width so it centers
    // horizontally instead of stretching edge-to-edge. The card itself
    // can't enforce a max width here — SnackBar (floating) wraps content
    // in `Row > Expanded`, which delivers a tight constraint that overrides
    // any inner `ConstrainedBox`. `SnackBar.width` is the only knob that
    // actually narrows the bar (and it requires floating, which we use).
    final windowWidth = MediaQuery.maybeOf(context)?.size.width;
    final useFixedWidth =
        windowWidth != null && windowWidth >= Breakpoints.wide;
    m.hideCurrentSnackBar();
    m.showSnackBar(
      SnackBar(
        content: _NotifyCard(
          variant: variant,
          message: message,
          detail: detail,
          action: action,
        ),
        // The card brings its own background + padding, so blank the
        // SnackBar shell out — otherwise the theme's dark `ink` background
        // shows behind the rounded card.
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        behavior: SnackBarBehavior.floating,
        width: useFixedWidth ? 520 : null,
        duration: variant.duration,
      ),
    );
  }
}

/// Action button rendered to the right of the toast text.
class NotifyAction {
  const NotifyAction(this.label, this.onPressed);
  final String label;
  final VoidCallback onPressed;
}

enum _Variant { success, error, warning, info }

extension on _Variant {
  Duration get duration {
    switch (this) {
      case _Variant.success:
      case _Variant.info:
        return const Duration(seconds: 3);
      case _Variant.warning:
        return const Duration(seconds: 5);
      case _Variant.error:
        return const Duration(seconds: 6);
    }
  }

  IconData get icon {
    switch (this) {
      case _Variant.success:
        return Icons.check_circle_outline;
      case _Variant.error:
        return Icons.error_outline;
      case _Variant.warning:
        return Icons.warning_amber_outlined;
      case _Variant.info:
        return Icons.info_outline;
    }
  }

  Color accent(InTheme t) {
    switch (this) {
      case _Variant.success:
        return t.paid;
      case _Variant.error:
        return t.overdue;
      case _Variant.warning:
        return t.sent;
      case _Variant.info:
        return t.partial;
    }
  }
}

class _NotifyCard extends StatelessWidget {
  const _NotifyCard({
    required this.variant,
    required this.message,
    this.detail,
    this.action,
  });

  final _Variant variant;
  final String message;
  final String? detail;
  final NotifyAction? action;

  @override
  Widget build(BuildContext context) {
    final t = context.inTheme;
    final accent = variant.accent(t);
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.bodyMedium?.copyWith(
      color: t.ink,
      fontWeight: FontWeight.w600,
    );
    final detailStyle = textTheme.bodySmall?.copyWith(color: t.ink3);

    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(InRadii.r2),
          border: Border.all(color: t.border),
          boxShadow: t.shadow2,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(InRadii.r2),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accent),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: InSpacing.md(context),
                    vertical: InSpacing.md(context),
                  ),
                  child: Icon(variant.icon, color: accent, size: 20),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: InSpacing.md(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(message, style: titleStyle),
                        if (detail != null && detail!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            detail!,
                            style: detailStyle,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (action != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      right: InSpacing.sm,
                      left: InSpacing.xs,
                    ),
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.maybeOf(
                          context,
                        )?.hideCurrentSnackBar();
                        action!.onPressed();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: accent,
                        textStyle: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(action!.label.toUpperCase()),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Strip common Dart exception type prefixes so detail lines read cleanly.
/// Kept intentionally dumb — exhaustive type matching is out of scope; the
/// goal is just to drop `Exception: `, `_Exception: `, and the type-name
/// prefixes that Flutter's builtin exceptions print, then trim.
///
/// Also the public seam for error surfaces that render a message string
/// directly instead of going through [Notify.error]'s `error:` parameter
/// (list-load errors, the PDF pane) — those must never show a raw
/// `FooException: …` toString to the user.
String formatNotifyError(Object error) => _formatError(error);

String _formatError(Object error) {
  var text = error.toString().trim();
  // Most Dart exceptions print as `FooException: message`. Strip the type
  // name (optionally prefixed with `_`) plus its `: ` separator so users
  // don't see the raw class name in the detail line.
  final match = RegExp(r'^_?[A-Za-z0-9_]*Exception:\s+').firstMatch(text);
  if (match != null) {
    text = text.substring(match.end).trim();
  }
  return text;
}
