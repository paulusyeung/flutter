import 'dart:async';

import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';

/// "Updated 2 min ago · Refresh" line below the KPI row. Updates itself every
/// 30 seconds so the relative time stays current without an external timer.
class FreshnessLabel extends StatefulWidget {
  const FreshnessLabel({
    super.key,
    required this.lastRefreshed,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final DateTime? lastRefreshed;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  @override
  State<FreshnessLabel> createState() => _FreshnessLabelState();
}

class _FreshnessLabelState extends State<FreshnessLabel> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final last = widget.lastRefreshed;
    final label = last == null
        ? (widget.isRefreshing
              ? context.tr('loading_ellipsis')
              : context.tr('not_yet_loaded_label'))
        : context.tr('updated_relative', {
            'relative': _relativeTime(context, DateTime.now().difference(last)),
          });
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: tokens.ink3)),
        const SizedBox(width: 4),
        Text('·', style: TextStyle(fontSize: 11, color: tokens.ink3)),
        const SizedBox(width: 4),
        InkWell(
          onTap: widget.isRefreshing ? null : widget.onRefresh,
          borderRadius: BorderRadius.circular(InRadii.r1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              widget.isRefreshing
                  ? context.tr('refreshing_ellipsis')
                  : context.tr('refresh'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: tokens.ink2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _relativeTime(BuildContext context, Duration d) {
    if (d.inSeconds < 30) return context.tr('just_now').toLowerCase();
    if (d.inMinutes < 1) {
      return context.tr('seconds_ago_short', {'count': d.inSeconds.toString()});
    }
    if (d.inHours < 1) {
      return context.tr('minutes_ago_short', {'count': d.inMinutes.toString()});
    }
    if (d.inDays < 1) {
      return context.tr('hours_ago_short', {'count': d.inHours.toString()});
    }
    return context.tr('days_ago_short', {'count': d.inDays.toString()});
  }
}
