import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/ui/core/detail/generic_detail_view_model.dart';
import 'package:admin/ui/core/list/master_detail_layout.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';

/// Shared chrome for an entity detail screen.
///
/// Owns the Scaffold + AppBar + loading/empty/content states that every
/// entity detail page wants. Concrete screens supply:
///   * a [GenericDetailViewModel] (`ClientDetailViewModel`, …)
///   * [actionsForItem]   — the AppBar title/actions widget per item
///     (typically the entity's actions row)
///   * [emptyTitle] + [emptyIcon] — shown when the watch stream resolves
///     to null (entity deleted, deep-linked to nonexistent id)
///   * [bodyBuilder] — renders the cards/sections for a resolved item
class EntityDetailScaffold<T> extends StatelessWidget {
  const EntityDetailScaffold({
    super.key,
    required this.vm,
    required this.bodyBuilder,
    required this.emptyTitle,
    this.emptySubtitle,
    this.emptyIcon = Icons.search_off_outlined,
    this.actionsForItem,
    this.embedded = false,
  });

  final GenericDetailViewModel<T> vm;
  final Widget Function(BuildContext context, T item) bodyBuilder;
  final String emptyTitle;
  final String? emptySubtitle;
  final IconData emptyIcon;

  /// Optional builder for the AppBar's title slot — usually an entity
  /// actions row. Receives the resolved item; not called while resolving
  /// or in the empty state. In embedded mode this widget is rendered as
  /// a thin header strip in place of the AppBar.
  final Widget Function(BuildContext context, T item)? actionsForItem;

  /// When `true`, the scaffold returns only the body — no outer
  /// `Scaffold`, no `AppBar`. Used when this screen is hosted inside
  /// another container (e.g. the `MasterDetailLayout` right pane on
  /// wide desktop) so the parent's chrome isn't duplicated. The actions
  /// row, if any, renders as an inline header strip above the body.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    // Auto-detect when mounted inside the master-detail right pane —
    // concrete screens never need to pass `embedded: true`. Matches
    // the same convention `EntityEditScaffold` uses.
    final inPane = MasterDetailPaneScope.isInPane(context);
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final item = vm.item;
        if (embedded || inPane) return _embeddedBody(context, item);
        return Scaffold(
          appBar: AppBar(
            titleSpacing: InSpacing.lg(context),
            title: (item != null && actionsForItem != null)
                ? actionsForItem!(context, item)
                : null,
          ),
          body: _stateBody(context, item),
        );
      },
    );
  }

  /// Embedded variant: stack a thin actions header above the same body
  /// switcher. No Scaffold / AppBar — the host shell owns the chrome.
  /// When mounted inside the slide-over pane, the pane's X + full-
  /// screen icons published via [MasterDetailPaneScope] are appended
  /// to the right of the row so they share the strip with the
  /// entity's own action buttons.
  Widget _embeddedBody(BuildContext context, T? item) {
    final tokens = context.inTheme;
    final paneActions = MasterDetailPaneScope.paneActionsOf(context);
    final hasHeaderContent = item != null && actionsForItem != null;
    final showHeader = hasHeaderContent || paneActions != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader)
          Container(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: InSpacing.lg(context),
              vertical: 8,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: tokens.border)),
            ),
            child: Row(
              children: [
                if (hasHeaderContent)
                  Expanded(child: actionsForItem!(context, item))
                else
                  const Spacer(),
                if (paneActions != null) paneActions,
              ],
            ),
          ),
        Expanded(child: _stateBody(context, item)),
      ],
    );
  }

  Widget _stateBody(BuildContext context, T? item) {
    if (item == null && vm.isResolving) {
      return const Center(child: CircularProgressIndicator());
    }
    if (item == null) {
      return EmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }
    return bodyBuilder(context, item);
  }
}
