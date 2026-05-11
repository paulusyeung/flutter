import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/core/widgets/error_view.dart';
import 'package:admin/ui/features/dashboard/view_models/async_section.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/ui/features/dashboard/widgets/list_card_skeleton.dart';

/// Generic dashboard list card. Pass the title, the per-row models, the body
/// builder, and the empty-state copy. Handles loading/empty/error states and
/// the 5-row preview + "All X" footer link.
///
/// The body slot is **edge-flush** — the shell adds no padding around the
/// `bodyBuilder` result. This lets a `DashboardEntityTable` header strip
/// stretch the full width of the card. Skeleton / empty / error states inside
/// this widget add their own padding so they don't visually touch the border.
class DashboardListCard<T> extends StatelessWidget {
  const DashboardListCard({
    super.key,
    required this.title,
    required this.section,
    required this.bodyBuilder,
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

  /// Builds the data body once the section is ready and non-empty. Receives
  /// the already-sliced preview list (length ≤ [preview]). Each card supplies
  /// a `DashboardEntityTable` for its row layout.
  final Widget Function(BuildContext, List<T>) bodyBuilder;

  final String footerLabel;
  final String emptyTitle;
  final IconData emptyIcon;
  final String? emptySubtitle;
  final Widget? emptyAction;
  final VoidCallback? onViewAll;
  final VoidCallback? onRetry;
  final int preview;

  static const EdgeInsets _statePadding = EdgeInsets.symmetric(
    horizontal: InSpacing.lg,
    vertical: InSpacing.md,
  );

  @override
  Widget build(BuildContext context) {
    return DashboardCardShell(
      title: title,
      trailing: section.hasData && (section.data?.isNotEmpty ?? false)
          ? DashboardCardFooterLink(label: footerLabel, onTap: onViewAll)
          : null,
      padding: EdgeInsets.zero,
      child: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (section.hasError && !section.hasData) {
      return Padding(
        padding: _statePadding,
        child: SizedBox(
          height: 200,
          child: ErrorView(
            message: context.tr('couldnt_load_tap_to_retry', {
              'section': title.toLowerCase(),
            }),
            onRetry: onRetry,
          ),
        ),
      );
    }
    final items = section.data;
    if (items == null) {
      return const Padding(
        padding: _statePadding,
        child: ListCardSkeleton(),
      );
    }
    if (items.isEmpty) {
      return Padding(
        padding: _statePadding,
        child: SizedBox(
          height: 200,
          child: EmptyState(
            icon: emptyIcon,
            title: emptyTitle,
            subtitle: emptySubtitle,
            action: emptyAction,
          ),
        ),
      );
    }
    final visible = items.take(preview).toList();
    return bodyBuilder(context, visible);
  }
}
