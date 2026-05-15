import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';

/// Builder for one of the three top-row card slots on the desktop
/// billing-doc edit shell. The per-entity layout supplies the slot
/// contents — see `_ClientCard` / `_DatesCard` / `_NumberCard` in
/// `invoice_edit_layout.dart` and friends.
typedef TopRowSlotBuilder = Widget Function(BuildContext context, int slot);

/// Desktop multi-column layout for the five billing-doc edit screens
/// (invoice / quote / credit / purchase_order / recurring_invoice).
///
/// Layout from top to bottom:
/// 1. Top row: three [TopRowSlotBuilder] cards side-by-side.
/// 2. Items section: the host's `LineItemEditor` (full-width, inline
///    edit table on desktop).
/// 3. Bottom row: a tabbed notes/terms/footer/eInvoice card on the
///    left + the host's PDF preview pane on the right.
/// 4. Sticky totals strip pinned at the bottom.
///
/// Each slot is intentionally a builder rather than a Widget so the
/// host controls per-entity quirks (vendor vs client picker, recurring
/// frequency block, credit hiding due dates, …) without the shell
/// having to know about any specific entity's fields.
class BillingDocEditDesktopShell extends StatelessWidget {
  const BillingDocEditDesktopShell({
    super.key,
    required this.topRow,
    required this.itemsSection,
    required this.notesTabsCard,
    required this.pdfPane,
    required this.stickyTotals,
    this.isDirty = false,
  });

  final TopRowSlotBuilder topRow;
  final Widget itemsSection;
  final Widget notesTabsCard;
  final Widget pdfPane;
  final Widget stickyTotals;

  /// When true, overlays a small "unsaved changes" banner over the PDF
  /// pane so the user knows the preview is stale. Driven by `vm.isDirty`
  /// from the per-entity layout.
  final bool isDirty;

  /// Shared height used by the bottom-row notes-tabs card AND the PDF
  /// preview pane so the two children of the bottom row line up
  /// vertically (no awkward step). Per-entity layouts call this for
  /// both `_NotesTabsCardDesktop` and `_PdfPaneDesktop`.
  static double bottomPaneHeight(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return (h * 0.5).clamp(360.0, 640.0);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(InSpacing.lg(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top row: client / dates / number-discount-design-customs.
                // The Number card carries 6+ fields (number, PO, discount,
                // design, custom 1-4) so it gets more horizontal room than
                // the Client and Dates cards.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: topRow(context, 0)),
                    SizedBox(width: InSpacing.md(context)),
                    Expanded(flex: 2, child: topRow(context, 1)),
                    SizedBox(width: InSpacing.md(context)),
                    Expanded(flex: 3, child: topRow(context, 2)),
                  ],
                ),
                SizedBox(height: InSpacing.md(context)),
                itemsSection,
                SizedBox(height: InSpacing.lg(context)),
                // Bottom row: notes-tabs card (flex 3) + PDF pane (flex 2).
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: notesTabsCard),
                    SizedBox(width: InSpacing.md(context)),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isDirty)
                            Container(
                              margin: EdgeInsets.only(
                                bottom: InSpacing.sm,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: InSpacing.md(context),
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: tokens.surfaceAlt,
                                borderRadius: BorderRadius.circular(InRadii.r1),
                                border: Border.all(color: tokens.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: tokens.ink2,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      context.tr('preview_reflects_last_save'),
                                      style: TextStyle(
                                        color: tokens.ink2,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          pdfPane,
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: tokens.border),
        stickyTotals,
      ],
    );
  }
}
