import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/domain/columns/client_columns.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/clients/view_models/client_list_view_model.dart';
import 'package:admin/ui/features/clients/widgets/client_list_tile.dart';

/// Uppercase eyebrow column labels above the table rows at wide widths.
/// Iterates the VM's current `columns` so header widths and labels stay in
/// lock-step with whatever the user has chosen via the column picker.
///
/// Doubles as the desktop sort control: every header is clickable and the
/// active one shows a ↑/↓ indicator. Backed by the DAO's `json_extract`
/// fallback so any visible column can be sorted, including payload-only
/// fields like contact name or city.
class ClientListColumnHeaders extends StatelessWidget {
  const ClientListColumnHeaders({super.key, required this.vm});

  final ClientListViewModel vm;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final labelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
      color: tokens.ink3,
    );
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
      child: Row(
        children: [
          // Leading actions slot — empty label, mirrors row's `…` menu.
          const SizedBox(width: kColWMoreMenu),
          const SizedBox(width: kColCellGap),
          // Avatar/checkbox slot. On desktop, hovering this slot reveals a
          // select-all checkbox.
          SizedBox(
            width: kColLeadingWidth,
            child: _HeaderSelectAllSlot(vm: vm),
          ),
          const SizedBox(width: kColCellGap),
          for (final col in vm.columns) ...[
            _HeaderCell(column: col, labelStyle: labelStyle, vm: vm),
            const SizedBox(width: kColCellGap),
          ],
          // Pill column: reserved, unlabeled. (Trailing more-menu slot
          // moved to leading.)
          const SizedBox(width: kColWPillSlot),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.column,
    required this.labelStyle,
    required this.vm,
  });
  final ClientColumn column;
  final TextStyle labelStyle;
  final ClientListViewModel vm;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final isActive = vm.sortField == column.id;
    final activeStyle = labelStyle.copyWith(color: tokens.ink2);
    final text = Text(
      context.tr(column.labelKey).toUpperCase(),
      style: isActive ? activeStyle : labelStyle,
    );
    final arrow = isActive
        ? Padding(
            // Hair of breathing room between label and arrow.
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
            child: Icon(
              vm.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 12,
              color: tokens.ink2,
            ),
          )
        : const SizedBox.shrink();
    // Trailing-edge arrow: after the text for start-aligned, before for
    // end-aligned. Keeps the label aligned with the cell contents below.
    final isEnd = column.align == ColumnAlign.end;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: isEnd ? [arrow, text] : [text, arrow],
    );
    final content = InkWell(
      onTap: () => vm.setSort(
        field: column.id,
        // Flip direction only when the active field is tapped again;
        // switching field keeps the current direction.
        ascending: isActive ? !vm.sortAscending : vm.sortAscending,
      ),
      child: Align(
        alignment: isEnd
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: 2),
          child: row,
        ),
      ),
    );
    if (column.isFlex) return Expanded(child: content);
    return SizedBox(width: column.width, child: content);
  }
}

/// The wide-mode column header's leading slot. Empty by default; hovers on
/// desktop reveal an empty select-all checkbox (mouse entry to multi-select
/// via `vm.selectAllVisible()`). While in multi-select the checkbox is
/// always visible and reflects whether *every* visible row is selected —
/// clicking it then toggles between "select all" and "clear".
class _HeaderSelectAllSlot extends StatefulWidget {
  const _HeaderSelectAllSlot({required this.vm});
  final ClientListViewModel vm;

  @override
  State<_HeaderSelectAllSlot> createState() => _HeaderSelectAllSlotState();
}

class _HeaderSelectAllSlotState extends State<_HeaderSelectAllSlot> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final selecting = vm.isInMultiselect;
    final allSelected =
        selecting &&
        vm.clients.isNotEmpty &&
        vm.countSelected == vm.clients.length;

    Widget child;
    VoidCallback? onTap;
    if (selecting) {
      child = SelectionCheckbox(checked: allSelected);
      onTap = () {
        if (allSelected) {
          vm.clearSelection();
        } else {
          vm.selectAllVisible();
        }
      };
    } else if (_isHovered && vm.clients.isNotEmpty) {
      child = const SelectionCheckbox(checked: false);
      onTap = vm.selectAllVisible;
    } else {
      child = const SizedBox.shrink();
    }

    return MouseRegion(
      onEnter: (_) {
        if (!_isHovered) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (_isHovered) setState(() => _isHovered = false);
      },
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: kColLeadingWidth,
          height: kColLeadingWidth,
          child: Center(child: child),
        ),
      ),
    );
  }
}
