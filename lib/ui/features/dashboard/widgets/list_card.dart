import 'package:flutter/material.dart';

import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/core/widgets/error_view.dart';
import 'package:admin/ui/features/dashboard/view_models/async_section.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/ui/features/dashboard/widgets/list_card_skeleton.dart';
import 'package:admin/ui/features/dashboard/widgets/list_row_tile.dart';

/// Generic dashboard list card. Pass the title, the per-row models, the row
/// builder, and the empty-state copy. Handles loading/empty/error states and
/// the 5-row preview + "All X" footer link.
class DashboardListCard<T> extends StatelessWidget {
  const DashboardListCard({
    super.key,
    required this.title,
    required this.section,
    required this.rowBuilder,
    required this.footerLabel,
    required this.emptyTitle,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptySubtitle,
    this.emptyAction,
    this.onViewAll,
    this.onRetry,
    this.preview = 5,
  });

  final String title;
  final AsyncSection<List<T>> section;
  final DashboardListRowTile Function(BuildContext, T) rowBuilder;
  final String footerLabel;
  final String emptyTitle;
  final IconData emptyIcon;
  final String? emptySubtitle;
  final Widget? emptyAction;
  final VoidCallback? onViewAll;
  final VoidCallback? onRetry;
  final int preview;

  @override
  Widget build(BuildContext context) {
    return DashboardCardShell(
      title: title,
      trailing: section.hasData && (section.data?.isNotEmpty ?? false)
          ? DashboardCardFooterLink(label: footerLabel, onTap: onViewAll)
          : null,
      child: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (section.hasError && !section.hasData) {
      return SizedBox(
        height: 200,
        child: ErrorView(
          message: "Couldn't load $title. Tap to retry.",
          onRetry: onRetry,
        ),
      );
    }
    final items = section.data;
    if (items == null) {
      return const ListCardSkeleton();
    }
    if (items.isEmpty) {
      return SizedBox(
        height: 200,
        child: EmptyState(
          icon: emptyIcon,
          title: emptyTitle,
          subtitle: emptySubtitle,
          action: emptyAction,
        ),
      );
    }
    final visible = items.take(preview).toList();
    return Column(
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          rowBuilder(context, visible[i]),
          if (i != visible.length - 1)
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).dividerColor,
            ),
        ],
      ],
    );
  }
}
