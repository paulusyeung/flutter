import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/billing/line_item.dart';
import 'package:admin/l10n/localization.dart';
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
    this.disabledReasonKey,
    this.rowErrors,
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

  /// When non-null, render a placeholder card with this localization
  /// key as the message instead of the editable table — used to gate
  /// the items section until a client (or vendor for PO) is picked.
  /// Avoids letting users type rows the server will reject as 422 for
  /// missing client_id.
  final String? disabledReasonKey;

  /// Per-row server validation errors keyed by line-item index. Keys
  /// inside each map mirror the API field names (`cost`, `quantity`,
  /// `product_key`, `notes`). Values are localized error messages.
  /// Surfaced inline in the desktop table and in the mobile dialog.
  final Map<int, Map<String, String>>? rowErrors;

  @override
  Widget build(BuildContext context) {
    if (disabledReasonKey != null) {
      return _DisabledItemsPlaceholder(reasonKey: disabledReasonKey!);
    }
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
            rowErrors: rowErrors,
          );
        }
        return LineItemCardListMobile(
          companyId: companyId,
          items: items,
          onChanged: onChanged,
          newItemFactory: newItemFactory,
          config: config,
        );
      },
    );
  }
}

/// Placeholder rendered in place of the line-items table when the
/// host indicates the section isn't ready yet (typically: no client
/// picked). Matches the table's outer chrome so the layout doesn't
/// shift when items become editable.
class _DisabledItemsPlaceholder extends StatelessWidget {
  const _DisabledItemsPlaceholder({required this.reasonKey});
  final String reasonKey;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(InRadii.r3),
        border: Border.all(color: tokens.border),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: InSpacing.lg(context),
        vertical: InSpacing.xl,
      ),
      child: Center(
        child: Text(
          context.tr(reasonKey),
          style: TextStyle(color: tokens.ink3, fontSize: 14),
        ),
      ),
    );
  }
}
