import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/ui/core/detail/generic_detail_view_model.dart';
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
  });

  final GenericDetailViewModel<T> vm;
  final Widget Function(BuildContext context, T item) bodyBuilder;
  final String emptyTitle;
  final String? emptySubtitle;
  final IconData emptyIcon;

  /// Optional builder for the AppBar's title slot — usually an entity
  /// actions row. Receives the resolved item; not called while resolving
  /// or in the empty state.
  final Widget Function(BuildContext context, T item)? actionsForItem;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final item = vm.item;
        return Scaffold(
          appBar: AppBar(
            titleSpacing: InSpacing.lg,
            title: (item != null && actionsForItem != null)
                ? actionsForItem!(context, item)
                : null,
          ),
          body: Builder(
            builder: (context) {
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
            },
          ),
        );
      },
    );
  }
}
