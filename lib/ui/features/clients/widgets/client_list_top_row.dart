import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/entity_column_picker_sheet.dart';
import 'package:admin/ui/features/clients/view_models/client_list_view_model.dart';
import 'package:admin/ui/features/clients/widgets/client_token_search_field.dart';

/// The wide-mode page header: primary action, token search field, columns
/// picker — all in one row. Rendered inside the AppBar's `flexibleSpace`
/// slot (NOT `title`, whose intrinsic-width layout pass is incompatible
/// with `Expanded`).
class ClientListTopRow extends StatefulWidget {
  const ClientListTopRow({required this.vm, super.key});

  final ClientListViewModel vm;

  @override
  State<ClientListTopRow> createState() => _ClientListTopRowState();
}

class _ClientListTopRowState extends State<ClientListTopRow> {
  /// Anchors the filter dropdown's LEFT edge to the "+ New Client"
  /// button (the leftmost element of this row). Without this, the popup
  /// would drop from the field's outer left mid-row, which reads as
  /// "centered". Passed into `ClientTokenSearchField` → `TokenSearchField`.
  final GlobalKey _popupAnchorKey = GlobalKey();

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
          key: _popupAnchorKey,
          onPressed: () => context.go('/clients/new'),
          icon: const Icon(Icons.add, size: 18),
          label: Text(context.tr('new_client')),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        const SizedBox(width: 16),
        // The token field carries every filter dimension — status, custom
        // fields, country, etc. Capped on very wide screens so the columns
        // button doesn't drift to the far edge.
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ClientTokenSearchField(
              vm: widget.vm,
              wide: true,
              popupAnchorKey: _popupAnchorKey,
            ),
          ),
        ),
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
      builder: (_) => EntityColumnPickerSheet(
        initial: widget.vm.columnIds,
        allColumns: widget.vm.allColumns,
        onApply: widget.vm.setColumns,
        onReset: widget.vm.resetColumns,
      ),
    );
  }
}
