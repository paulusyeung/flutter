import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/dashboard/dashboard_activity.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/core/widgets/error_view.dart';
import 'package:admin/ui/features/dashboard/helpers/activity_formatter.dart';
import 'package:admin/ui/features/dashboard/view_models/async_section.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';

/// "Activity" feed — 5 most recent rows, tone-tinted circle + templated text +
/// meta line. Matches `screens.jsx:268–295`.
class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.section,
    required this.onViewAll,
    required this.onRetry,
  });

  final AsyncSection<List<DashboardActivity>> section;
  final VoidCallback onViewAll;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DashboardCardShell(
      title: context.tr('activity'),
      trailing: DashboardCardFooterLink(
        label: context.tr('view_all'),
        onTap: onViewAll,
      ),
      child: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (section.hasError && !section.hasData) {
      return _Constrained(
        child: ErrorView(
          message: context.tr('couldnt_load_tap_to_retry', {
            'section': context.tr('activity').toLowerCase(),
          }),
          onRetry: onRetry,
        ),
      );
    }
    final items = section.data;
    if (items == null) {
      return _ActivitySkeleton();
    }
    if (items.isEmpty) {
      return _Constrained(
        child: EmptyState(
          icon: Icons.notifications_none_outlined,
          title: context.tr('no_activity_yet'),
        ),
      );
    }
    final formatter = ActivityFormatter(context);
    final tokens = context.inTheme;
    final visible = items.take(5).toList();
    return Column(
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          _ActivityRow(render: formatter.format(visible[i])),
          if (i != visible.length - 1)
            Divider(height: 1, thickness: 1, color: tokens.border),
        ],
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.render});

  final ActivityRender render;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final (bg, fg) = activityToneColors(tokens, render.tone);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(render.icon, size: 14, color: fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  render.title,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: tokens.ink,
                    height: 1.35,
                  ),
                ),
                Text(
                  render.meta,
                  style: TextStyle(fontSize: 11, color: tokens.ink3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivitySkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Column(
      children: List.generate(5, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: tokens.surfaceAlt,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 180,
                      height: 12,
                      decoration: BoxDecoration(
                        color: tokens.surfaceAlt,
                        borderRadius: BorderRadius.circular(InRadii.r1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 80,
                      height: 10,
                      decoration: BoxDecoration(
                        color: tokens.surfaceAlt,
                        borderRadius: BorderRadius.circular(InRadii.r1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _Constrained extends StatelessWidget {
  const _Constrained({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SizedBox(height: 160, child: child);
}
