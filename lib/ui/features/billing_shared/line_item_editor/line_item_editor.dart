import 'package:flutter/material.dart';

import 'package:admin/data/models/domain/billing/line_item.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/features/billing_shared/line_item_editor/line_item_card_list_mobile.dart';
import 'package:admin/ui/features/billing_shared/line_item_editor/line_item_column_config.dart';
import 'package:admin/ui/features/billing_shared/line_item_editor/line_item_table_desktop.dart';

/// Entry widget for editing the line-item list on any billing-doc edit
/// screen (Invoice / Quote / Credit / PO / RecurringInvoice). Switches
/// between the desktop inline-table and the mobile card-list based on
/// the available width.
///
/// The two underlying widgets share the same `(items, onChanged,
/// newItemFactory, config)` signature so the editor itself is just a
/// `LayoutBuilder`. Both delegate to `showLineItemEditDialog` for actual
/// row editing (M3 first cut) — M3.5 / M4 introduces inline-editable
/// cells with product autocomplete on desktop.
class LineItemEditor extends StatelessWidget {
  const LineItemEditor({
    super.key,
    required this.companyId,
    required this.items,
    required this.onChanged,
    required this.newItemFactory,
    this.config = LineItemColumnConfig.minimal,
    this.controller,
  });

  /// Company scope for the desktop table's product autocomplete +
  /// company-format-settings (decimal separator).
  final String companyId;

  final List<LineItem> items;
  final ValueChanged<List<LineItem>> onChanged;

  /// Factory invoked when the user taps "Add item". The host typically
  /// returns [emptyLineItem] but can seed defaults (e.g. apply the
  /// company's default tax rate name + rate).
  final LineItem Function() newItemFactory;

  /// Which optional columns to show — driven by company settings.
  final LineItemColumnConfig config;

  /// Optional handle the host can pass in to call `flushPending()` on
  /// the desktop table at save time, ensuring the 250 ms cell debounce
  /// doesn't drop the last keystrokes. No-op on mobile (the dialog
  /// commits synchronously on tap).
  final LineItemTableDesktopController? controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = Breakpoints.isWide(constraints) &&
            constraints.maxWidth >= 700;
        if (wide) {
          return LineItemTableDesktop(
            companyId: companyId,
            items: items,
            onChanged: onChanged,
            newItemFactory: newItemFactory,
            config: config,
            controller: controller,
          );
        }
        return LineItemCardListMobile(
          items: items,
          onChanged: onChanged,
          newItemFactory: newItemFactory,
          config: config,
        );
      },
    );
  }
}
