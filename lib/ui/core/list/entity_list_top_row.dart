import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/entity_column_picker_sheet.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/saved_views_button.dart';

/// Wide-mode page header: primary "new" action, token search field, columns
/// picker — all in one row. Rendered inside the AppBar's `flexibleSpace` slot
/// by [EntityListNormalAppBar] (NOT `title`, whose intrinsic-width layout
/// pass is incompatible with `Expanded`).
///
/// Generic over the [GenericListViewModel] so every entity list screen
/// shares the same chrome — only the per-entity [searchField] differs.
class EntityListTopRow<T> extends StatelessWidget {
  const EntityListTopRow({
    required this.vm,
    required this.newRoute,
    required this.newLabelKey,
    required this.searchField,
    super.key,
  });

  final GenericListViewModel<T> vm;

  /// Route the "New X" button navigates to (e.g. `/clients/new`).
  final String newRoute;

  /// Localization key for the primary button label (e.g. `new_client`).
  final String newLabelKey;

  /// Feature-built token search field. Each entity supplies its own
  /// `FilterKey` set, so the widget is built by the caller.
  final Widget searchField;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Primary action leads the row. The `minimumSize` override fixes a
        // Flutter flex-first-pass sizing bug — without a finite minimum,
        // `_RenderInputPadding` collapses to invalid constraints when an
        // `Expanded` sibling sits next to it.
        FilledButton.icon(
          onPressed: () => context.go(newRoute),
          icon: const Icon(Icons.add, size: 18),
          label: Text(context.tr(newLabelKey)),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        const SizedBox(width: 16),
        // The token field carries every filter dimension. Capped on very
        // wide screens so the search field doesn't stretch to fill the row
        // — but the `Expanded` slot still consumes the remaining width.
        // `Align(centerStart)` parks the (capped) field against the
        // FilledButton; the unused space sits between the field and the
        // Columns button, keeping the Columns button glued to the row's
        // trailing edge (24 px from the screen, flush with the table card
        // below). Without the `Align`, the inner alignment defaults pulled
        // the Columns button inward as the window widened past 720 px.
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: searchField,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SavedViewsButton<T>(vm: vm),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () => _openColumnsPicker(context),
          icon: const Icon(Icons.view_column_outlined, size: 14),
          label: Text(
            context.tr('columns'),
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: tokens.ink2,
            side: BorderSide(color: tokens.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: const Size(0, 36),
          ),
        ),
      ],
    );
  }

  void _openColumnsPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EntityColumnPickerSheet<T>(
        initial: vm.columnIds,
        allColumns: vm.allColumns,
        onApply: vm.setColumns,
        onReset: vm.resetColumns,
      ),
    );
  }
}
