import 'dart:async';

import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/utils/formatting.dart';

/// Ticking duration label for the currently-running entry of a task.
///
/// Self-contained ticker — mirrors `freshness_label.dart`'s pattern but at
/// 1 second by default (or [precision], for the kanban cards where every
/// visible card ticking is wasteful). Cancels in `dispose`.
///
/// Optionally renders a pulsing dot alongside the duration text. The same
/// ticker drives both so they stay in lockstep without separate state.
class RunningDurationLabel extends StatefulWidget {
  const RunningDurationLabel({
    super.key,
    required this.start,
    this.precision = const Duration(seconds: 1),
    this.showDot = true,
    this.compactDays = true,
    this.style,
    this.dotSize = 8,
  });

  /// Timestamp of the running entry's start. The label renders
  /// `now − start` against the current frame's wall clock.
  final DateTime start;

  /// How often the label refreshes. 1s for the edit screen, 1min for the
  /// kanban cards (the human eye doesn't follow seconds on a card).
  final Duration precision;

  /// Render the pulsing accent dot before the label.
  final bool showDot;

  /// When elapsed exceeds 24h, format as `Xd HHh MMm` instead of
  /// `HH:MM:SS` (which gets unreadable past 24 hours).
  final bool compactDays;

  /// Override the label text style. Defaults to the screen's body small.
  final TextStyle? style;

  final double dotSize;

  @override
  State<RunningDurationLabel> createState() => _RunningDurationLabelState();
}

class _RunningDurationLabelState extends State<RunningDurationLabel>
    with SingleTickerProviderStateMixin {
  Timer? _ticker;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(widget.precision, (_) {
      if (mounted) setState(() {});
    });
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final elapsed = DateTime.now().difference(widget.start);
    // When the ticker fires less often than once a second, the seconds
    // field would freeze for ~60s at a time — looks like a bug. Drop
    // seconds from the rendered text in that case (kanban cards opt in).
    final showSeconds = widget.precision < const Duration(minutes: 1);
    final label = formatDuration(
      elapsed,
      compactDays: widget.compactDays,
      showSeconds: showSeconds,
    );
    final style =
        widget.style ??
        TextStyle(
          color: tokens.ink,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showDot) ...[
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, _) => Opacity(
              opacity: 0.45 + (_pulse.value * 0.55),
              child: Container(
                width: widget.dotSize,
                height: widget.dotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Text(label, style: style),
      ],
    );
  }
}
