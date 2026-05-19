import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/billing/billing_contact.dart';
import 'package:admin/data/models/domain/billing/line_item.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/data/models/domain/design.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_custom_fields_section.dart';
import 'package:admin/ui/core/widgets/in_date_field.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
import 'package:admin/ui/features/billing_shared/add_unbilled/add_unbilled_items_button.dart';
import 'package:admin/ui/features/billing_shared/billing_doc_type.dart';
import 'package:admin/ui/features/billing_shared/contacts/billing_doc_contacts_section.dart';
import 'package:admin/ui/features/billing_shared/edit/billing_doc_edit_desktop_shell.dart';
import 'package:admin/ui/features/billing_shared/edit/billing_edit_field_decoration.dart';
import 'package:admin/ui/features/billing_shared/edit/billing_doc_settings_tab.dart';
import 'package:admin/ui/features/billing_shared/edit/e_invoice_fields_tab.dart';
import 'package:admin/ui/features/billing_shared/edit/save_default_helper.dart';
import 'package:admin/ui/features/billing_shared/line_item_editor/line_item_column_config.dart';
import 'package:admin/ui/features/billing_shared/line_item_editor/line_item_editor.dart';
import 'package:admin/ui/features/billing_shared/line_item_editor/line_item_table_desktop.dart';
import 'package:admin/ui/features/billing_shared/markdown_notes_section.dart';
import 'package:admin/ui/features/billing_shared/pdf/billing_doc_pdf_view.dart';
import 'package:admin/ui/features/billing_shared/totals_widget.dart';
import 'package:admin/ui/features/invoices/view_models/invoice_edit_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';

/// Tabbed body for the invoice edit screen.
///
/// Tabs: Details / Contacts / Items / Notes / PDF / E-Invoice (last tab
/// surfaces only when company has eInvoice enabled — gated in M4).
/// Sticky-bottom [TotalsWidget] sits below the tabs and updates live from
/// `vm.totals` as the user edits.
///
/// Per CLAUDE.md, this body lives under `/invoices/...` which is *not*
/// under `/settings/...` — so the wide-screen layout stretches to fill
/// the available width rather than capping at the settings-form max.
class InvoiceEditLayout extends StatefulWidget {
  const InvoiceEditLayout({super.key, required this.vm});

  final InvoiceEditViewModel vm;

  @override
  State<InvoiceEditLayout> createState() => _InvoiceEditLayoutState();
}

class _InvoiceEditLayoutState extends State<InvoiceEditLayout>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.vm,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1024;
            return wide ? _buildDesktop(context) : _buildMobile(context);
          },
        );
      },
    );
  }

  Widget _buildMobile(BuildContext context) {
    final tokens = context.inTheme;
    // Embedded/pane mode has no Scaffold, so the TabBarView pages would
    // otherwise have no Material ancestor — every TextField / RawAutocomplete
    // in a narrow tab throws "No Material widget found". A transparency
    // Material supplies the ancestor with zero visual change (mirrors what
    // BillingDocEditDesktopShell provides for the wide layout).
    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: tokens.surface,
            child: TabBar(
              controller: _tab,
              isScrollable: true,
              tabs: [
                Tab(text: context.tr('details')),
                Tab(text: context.tr('contacts')),
                Tab(text: context.tr('items')),
                Tab(text: context.tr('notes')),
                Tab(text: context.tr('pdf')),
                Tab(text: context.tr('e_invoice')),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.border),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _DetailsTab(vm: widget.vm),
                _ContactsTab(vm: widget.vm),
                _ItemsTab(vm: widget.vm),
                _NotesTab(vm: widget.vm),
                _PdfTab(vm: widget.vm),
                EInvoiceFieldsTab<Invoice>(
                  vm: widget.vm,
                  entityKind: EInvoiceEntityKind.invoice,
                  documentType: _invoiceDocType(widget.vm.draft),
                  formatter: context.read<Services>().formatterIfReady(
                    widget.vm.companyId,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.border),
          _StickyTotals(vm: widget.vm),
        ],
      ),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return BillingDocEditDesktopShell(
      topRow: (ctx, slot) => switch (slot) {
        0 => _ClientCardDesktop(vm: widget.vm),
        1 => _DatesCardDesktop(vm: widget.vm),
        2 => _NumberCardDesktop(vm: widget.vm),
        _ => const SizedBox.shrink(),
      },
      itemsSection: _ItemsSectionDesktop(vm: widget.vm),
      notesTabsCard: _NotesTabsCardDesktop(vm: widget.vm),
      totalsCard: _TotalsCardDesktop(vm: widget.vm),
      pdfPane: _PdfPaneDesktop(vm: widget.vm),
      stickyTotals: _SlimTotalsBar(vm: widget.vm),
      isDirty: !widget.vm.isCreate && widget.vm.isDirty && !widget.vm.isSaving,
    );
  }
}

// ── Desktop multi-column cards ───────────────────────────────────────

class _ClientCardDesktop extends StatelessWidget {
  const _ClientCardDesktop({required this.vm});
  final InvoiceEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: null,
      spacing: 0,
      elevated: false,
      children: [
        _ClientPicker(vm: vm),
        SizedBox(height: InSpacing.md(context)),
        _ContactsForClient(vm: vm),
      ],
    );
  }
}

class _ContactsForClient extends StatelessWidget {
  const _ContactsForClient({required this.vm});
  final InvoiceEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.draft.clientId.isEmpty) {
      return const SizedBox.shrink();
    }
    final services = context.read<Services>();
    return StreamBuilder<Client?>(
      stream: services.clients.watch(
        companyId: vm.companyId,
        id: vm.draft.clientId,
      ),
      builder: (context, snapshot) {
        final client = snapshot.data;
        if (client == null) {
          return const LinearProgressIndicator(minHeight: 2);
        }
        final selected = vm.draft.invitations
            .map((i) => i.clientContactId)
            .where((id) => id.isNotEmpty)
            .toSet();
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240),
          child: SingleChildScrollView(
            child: BillingDocContactsSection(
              contacts: client.contacts.map((c) => c.toBilling()).toList(),
              selectedContactIds: selected,
              onChanged: (next) {
                final added = next.difference(selected);
                final removed = selected.difference(next);
                for (final id in added) {
                  vm.setContactInvitation(id, true);
                }
                for (final id in removed) {
                  vm.setContactInvitation(id, false);
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class _DatesCardDesktop extends StatefulWidget {
  const _DatesCardDesktop({required this.vm});
  final InvoiceEditViewModel vm;

  @override
  State<_DatesCardDesktop> createState() => _DatesCardDesktopState();
}

class _DatesCardDesktopState extends State<_DatesCardDesktop> {
  late final TextEditingController _partial;

  @override
  void initState() {
    super.initState();
    _partial = TextEditingController(
      text: widget.vm.draft.partial == Decimal.zero
          ? ''
          : widget.vm.draft.partial.toString(),
    );
  }

  @override
  void dispose() {
    _partial.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final fmt = context.read<Services>().formatterIfReady(vm.companyId);
    return FormSection(
      title: null,
      spacing: 0,
      elevated: false,
      children: [
        InDateField(
          value: vm.draft.date?.toDateTime(),
          formatter: fmt,
          onChanged: (d) {
            if (d == null) {
              vm.setDate(null);
            } else {
              vm.setDate(Date(d.year, d.month, d.day));
            }
          },
          labelText: context.tr('invoice_date'),
        ),
        SizedBox(height: InSpacing.md(context)),
        InDateField(
          value: vm.draft.dueDate?.toDateTime(),
          formatter: fmt,
          onChanged: (d) {
            if (d == null) {
              vm.setDueDate(null);
            } else {
              vm.setDueDate(Date(d.year, d.month, d.day));
            }
          },
          labelText: context.tr('due_date'),
          clearable: true,
        ),
        SizedBox(height: InSpacing.md(context)),
        TextField(
          controller: _partial,
          decoration: billingFieldDecoration(
            context,
            label: context.tr('partial'),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: vm.setPartial,
        ),
        if (vm.draft.partial > Decimal.zero) ...[
          SizedBox(height: InSpacing.md(context)),
          InDateField(
            value: vm.draft.partialDueDate?.toDateTime(),
            formatter: fmt,
            onChanged: (d) {
              if (d == null) {
                vm.setPartialDueDate(null);
              } else {
                vm.setPartialDueDate(Date(d.year, d.month, d.day));
              }
            },
            labelText: context.tr('partial_due_date'),
            clearable: true,
          ),
        ],
        SizedBox(height: InSpacing.md(context)),
        EntityCustomFieldsSection(
          keyPrefix: 'invoice',
          companyStream: context.read<Services>().company.watchCompany(
            vm.companyId,
          ),
          values: [
            vm.draft.customValue1,
            vm.draft.customValue2,
            vm.draft.customValue3,
            vm.draft.customValue4,
          ],
          onChanged: [
            vm.setCustomValue1,
            vm.setCustomValue2,
            vm.setCustomValue3,
            vm.setCustomValue4,
          ],
          wrapInCard: false,
          slots: const [1, 3],
        ),
      ],
    );
  }
}

class _NumberCardDesktop extends StatefulWidget {
  const _NumberCardDesktop({required this.vm});
  final InvoiceEditViewModel vm;

  @override
  State<_NumberCardDesktop> createState() => _NumberCardDesktopState();
}

class _NumberCardDesktopState extends State<_NumberCardDesktop> {
  late final TextEditingController _number;
  late final TextEditingController _poNumber;
  late final TextEditingController _discount;

  @override
  void initState() {
    super.initState();
    _number = TextEditingController(text: widget.vm.draft.number);
    _poNumber = TextEditingController(text: widget.vm.draft.poNumber);
    _discount = TextEditingController(
      text: widget.vm.draft.discount == Decimal.zero
          ? ''
          : widget.vm.draft.discount.toString(),
    );
  }

  @override
  void dispose() {
    _number.dispose();
    _poNumber.dispose();
    _discount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    return FormSection(
      title: null,
      spacing: 0,
      elevated: false,
      children: [
        TextField(
          controller: _number,
          decoration: billingFieldDecoration(
            context,
            label: context.tr('invoice_number'),
            hint: vm.isCreate ? context.tr('auto_generated') : null,
            errorText: vm.fieldErrorFor('number'),
          ),
          onChanged: vm.setNumber,
        ),
        SizedBox(height: InSpacing.md(context)),
        TextField(
          controller: _poNumber,
          decoration: billingFieldDecoration(
            context,
            label: context.tr('po_number'),
            errorText: vm.fieldErrorFor('po_number'),
          ),
          onChanged: vm.setPoNumber,
        ),
        SizedBox(height: InSpacing.md(context)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: _discount,
                decoration: billingFieldDecoration(
                  context,
                  label: context.tr('discount'),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (v) =>
                    vm.setDiscount(v, isAmount: vm.draft.isAmountDiscount),
              ),
            ),
            SizedBox(width: InSpacing.md(context)),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(context.tr('percent'))),
                ButtonSegment(value: true, label: Text(context.tr('amount'))),
              ],
              selected: {vm.draft.isAmountDiscount},
              onSelectionChanged: (s) =>
                  vm.setDiscount(_discount.text, isAmount: s.first),
            ),
          ],
        ),
        SizedBox(height: InSpacing.md(context)),
        EntityCustomFieldsSection(
          keyPrefix: 'invoice',
          companyStream: context.read<Services>().company.watchCompany(
            vm.companyId,
          ),
          values: [
            vm.draft.customValue1,
            vm.draft.customValue2,
            vm.draft.customValue3,
            vm.draft.customValue4,
          ],
          onChanged: [
            vm.setCustomValue1,
            vm.setCustomValue2,
            vm.setCustomValue3,
            vm.setCustomValue4,
          ],
          wrapInCard: false,
          slots: const [2, 4],
        ),
      ],
    );
  }
}

class _ItemsSectionDesktop extends StatefulWidget {
  const _ItemsSectionDesktop({required this.vm});
  final InvoiceEditViewModel vm;

  @override
  State<_ItemsSectionDesktop> createState() => _ItemsSectionDesktopState();
}

class _ItemsSectionDesktopState extends State<_ItemsSectionDesktop> {
  final _tableController = LineItemTableDesktopController();
  VoidCallback? _unregisterFlush;
  VoidCallback? _unregisterStrip;

  @override
  void initState() {
    super.initState();
    // Flush in-flight cell debounces before save; then drop trailing
    // blank rows so the always-on-screen ghost row never ships.
    _unregisterFlush = widget.vm.addBeforeSaveHook(
      _tableController.flushPending,
    );
    _unregisterStrip = widget.vm.addBeforeSaveHook(
      widget.vm.stripEmptyLineItems,
    );
  }

  @override
  void dispose() {
    _unregisterFlush?.call();
    _unregisterStrip?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(bottom: InSpacing.md(context)),
            child: AddUnbilledItemsButton(
              companyId: vm.companyId,
              clientId: vm.draft.clientId,
              onAdd: (added) => _appendUnbilledLineItems(vm, added),
            ),
          ),
        ),
        LineItemEditor(
          companyId: vm.companyId,
          items: vm.draft.lineItems,
          onChanged: vm.replaceLineItems,
          newItemFactory: emptyLineItem,
          config: const LineItemColumnConfig(
            showDiscount: true,
            taxColumnCount: 1,
          ),
          controller: _tableController,
          rowErrors: vm.lineItemRowErrors,
        ),
      ],
    );
  }
}

/// Drops trailing blank/ghost rows, appends the chosen unbilled line items,
/// and writes back through the VM. The line-item editor re-adds its own
/// trailing blank row.
void _appendUnbilledLineItems(InvoiceEditViewModel vm, List<LineItem> added) {
  final base = vm.draft.lineItems.where((i) => !i.isBlank).toList();
  vm.replaceLineItems([...base, ...added]);
}

class _NotesTabsCardDesktop extends StatefulWidget {
  const _NotesTabsCardDesktop({required this.vm});
  final InvoiceEditViewModel vm;

  @override
  State<_NotesTabsCardDesktop> createState() => _NotesTabsCardDesktopState();
}

class _NotesTabsCardDesktopState extends State<_NotesTabsCardDesktop>
    with SingleTickerProviderStateMixin {
  late final TabController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final tokens = context.inTheme;
    return FormSection(
      title: null,
      spacing: 0,
      elevated: false,
      children: [
        TabBar(
          controller: _ctl,
          isScrollable: true,
          labelColor: tokens.ink,
          unselectedLabelColor: tokens.ink3,
          tabs: [
            Tab(text: context.tr('terms')),
            Tab(text: context.tr('footer')),
            Tab(text: context.tr('public_notes')),
            Tab(text: context.tr('private_notes')),
            Tab(text: context.tr('settings')),
            Tab(text: context.tr('e_invoice')),
          ],
        ),
        Divider(height: 1, color: tokens.border),
        SizedBox(
          height: BillingDocEditDesktopShell.notesPaneHeight(context),
          // Widget-order (not geometry) Tab traversal across the notes
          // sub-tabs: TabBarView leaves non-current pages built-but-unlaid,
          // and reading-order traversal would call `FocusNode.rect` on the
          // unlaid markdown-field host nodes → `hasSize` assertion. Notes
          // fields are in source order so the Tab sequence is unchanged.
          child: FocusTraversalGroup(
            policy: WidgetOrderTraversalPolicy(),
            child: TabBarView(
              controller: _ctl,
              children: [
                MarkdownNotesField(
                  label: context.tr('terms'),
                  showLabel: false,
                  expand: true,
                  value: vm.draft.terms,
                  onChanged: vm.setTerms,
                  onSaveAsDefault: (v) => saveBillingDocDefault(
                    context,
                    companyId: vm.companyId,
                    value: v,
                    fieldKey: 'invoice_terms',
                    successKey: 'updated_default_terms',
                    apply: (s, val) => s.copyWith(invoiceTerms: val),
                  ),
                ),
                MarkdownNotesField(
                  label: context.tr('footer'),
                  showLabel: false,
                  expand: true,
                  value: vm.draft.footer,
                  onChanged: vm.setFooter,
                  onSaveAsDefault: (v) => saveBillingDocDefault(
                    context,
                    companyId: vm.companyId,
                    value: v,
                    fieldKey: 'invoice_footer',
                    successKey: 'updated_default_footer',
                    apply: (s, val) => s.copyWith(invoiceFooter: val),
                  ),
                ),
                MarkdownNotesField(
                  label: context.tr('public_notes'),
                  showLabel: false,
                  expand: true,
                  value: vm.draft.publicNotes,
                  onChanged: vm.setPublicNotes,
                ),
                MarkdownNotesField(
                  label: context.tr('private_notes'),
                  showLabel: false,
                  expand: true,
                  value: vm.draft.privateNotes,
                  onChanged: vm.setPrivateNotes,
                ),
                SingleChildScrollView(
                  child: BillingDocSettingsTab(
                    companyId: vm.companyId,
                    designId: vm.draft.designId,
                    onDesignChanged: vm.setDesignId,
                    userId: vm.draft.assignedUserId,
                    onUserChanged: vm.setAssignedUserId,
                    projectId: vm.draft.projectId,
                    onProjectChanged: vm.setProjectId,
                    vendorId: vm.draft.vendorId,
                    onVendorChanged: vm.setVendorId,
                    exchangeRate: vm.draft.exchangeRate.toString(),
                    onExchangeRateChanged: vm.setExchangeRate,
                    autoBillEnabled: vm.draft.autoBillEnabled,
                    onAutoBillEnabledChanged: vm.setAutoBillEnabled,
                  ),
                ),
                EInvoiceFieldsTab<Invoice>(
                  vm: vm,
                  entityKind: EInvoiceEntityKind.invoice,
                  documentType: _invoiceDocType(vm.draft),
                  formatter: context.read<Services>().formatterIfReady(
                    vm.companyId,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PdfPaneDesktop extends StatelessWidget {
  const _PdfPaneDesktop({required this.vm});
  final InvoiceEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: null,
      spacing: 0,
      elevated: false,
      children: [
        SizedBox(
          height: BillingDocEditDesktopShell.fullWidthPdfHeight(context),
          child: _PdfTab(vm: vm),
        ),
      ],
    );
  }
}

class _StickyTotals extends StatelessWidget {
  const _StickyTotals({required this.vm});
  final InvoiceEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(InSpacing.md(context)),
      child: TotalsWidget(
        totals: vm.totals,
        discount: vm.draft.discount,
        discountIsAmount: vm.draft.isAmountDiscount,
        partial: vm.draft.partial,
        dense: true,
      ),
    );
  }
}

/// Full subtotal/tax/discount/total breakdown card for the desktop
/// bottom-right column (mirrors the old admin-portal totals card).
class _TotalsCardDesktop extends StatelessWidget {
  const _TotalsCardDesktop({required this.vm});
  final InvoiceEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return TotalsWidget(
      totals: vm.totals,
      discount: vm.draft.discount,
      discountIsAmount: vm.draft.isAmountDiscount,
      partial: vm.draft.partial,
      bordered: false,
    );
  }
}

/// Slim single-line "Total" bar pinned at the very bottom of the
/// desktop edit screen (the full breakdown lives in
/// [_TotalsCardDesktop]).
class _SlimTotalsBar extends StatelessWidget {
  const _SlimTotalsBar({required this.vm});
  final InvoiceEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return TotalsWidget(
      totals: vm.totals,
      discount: vm.draft.discount,
      discountIsAmount: vm.draft.isAmountDiscount,
      partial: vm.draft.partial,
      dense: true,
      slim: true,
    );
  }
}

// ── Details tab ──────────────────────────────────────────────────────

class _DetailsTab extends StatefulWidget {
  const _DetailsTab({required this.vm});
  final InvoiceEditViewModel vm;

  @override
  State<_DetailsTab> createState() => _DetailsTabState();
}

class _DetailsTabState extends State<_DetailsTab> {
  late final TextEditingController _number;
  late final TextEditingController _poNumber;
  late final TextEditingController _partial;
  late final TextEditingController _discount;

  @override
  void initState() {
    super.initState();
    _number = TextEditingController(text: widget.vm.draft.number);
    _poNumber = TextEditingController(text: widget.vm.draft.poNumber);
    _partial = TextEditingController(
      text: widget.vm.draft.partial == Decimal.zero
          ? ''
          : widget.vm.draft.partial.toString(),
    );
    _discount = TextEditingController(
      text: widget.vm.draft.discount == Decimal.zero
          ? ''
          : widget.vm.draft.discount.toString(),
    );
  }

  @override
  void dispose() {
    _number.dispose();
    _poNumber.dispose();
    _partial.dispose();
    _discount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final fmt = context.read<Services>().formatterIfReady(vm.companyId);
    return SingleChildScrollView(
      padding: EdgeInsets.all(InSpacing.lg(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ClientPicker(vm: vm),
          SizedBox(height: InSpacing.lg(context)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _number,
                  decoration: InputDecoration(
                    labelText: context.tr('invoice_number'),
                    hintText: vm.isCreate ? context.tr('auto_generated') : null,
                    errorText: vm.fieldErrorFor('number'),
                  ),
                  onChanged: vm.setNumber,
                ),
              ),
              SizedBox(width: InSpacing.md(context)),
              Expanded(
                child: TextField(
                  controller: _poNumber,
                  decoration: InputDecoration(
                    labelText: context.tr('po_number'),
                    errorText: vm.fieldErrorFor('po_number'),
                  ),
                  onChanged: vm.setPoNumber,
                ),
              ),
            ],
          ),
          SizedBox(height: InSpacing.md(context)),
          Row(
            children: [
              Expanded(
                child: InDateField(
                  value: vm.draft.date?.toDateTime(),
                  formatter: fmt,
                  onChanged: (d) {
                    if (d == null) {
                      vm.setDate(null);
                    } else {
                      vm.setDate(Date(d.year, d.month, d.day));
                    }
                  },
                  labelText: context.tr('invoice_date'),
                ),
              ),
              SizedBox(width: InSpacing.md(context)),
              Expanded(
                child: InDateField(
                  value: vm.draft.dueDate?.toDateTime(),
                  formatter: fmt,
                  onChanged: (d) {
                    if (d == null) {
                      vm.setDueDate(null);
                    } else {
                      vm.setDueDate(Date(d.year, d.month, d.day));
                    }
                  },
                  labelText: context.tr('due_date'),
                  clearable: true,
                ),
              ),
            ],
          ),
          SizedBox(height: InSpacing.md(context)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _partial,
                  decoration: InputDecoration(labelText: context.tr('partial')),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: vm.setPartial,
                ),
              ),
              SizedBox(width: InSpacing.md(context)),
              Expanded(
                child: InDateField(
                  value: vm.draft.partialDueDate?.toDateTime(),
                  formatter: fmt,
                  onChanged: (d) {
                    if (d == null) {
                      vm.setPartialDueDate(null);
                    } else {
                      vm.setPartialDueDate(Date(d.year, d.month, d.day));
                    }
                  },
                  labelText: context.tr('partial_due_date'),
                  clearable: true,
                ),
              ),
            ],
          ),
          SizedBox(height: InSpacing.md(context)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _discount,
                  decoration: InputDecoration(
                    labelText: context.tr('discount'),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (v) =>
                      vm.setDiscount(v, isAmount: vm.draft.isAmountDiscount),
                ),
              ),
              SizedBox(width: InSpacing.md(context)),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(context.tr('percent')),
                  ),
                  ButtonSegment(value: true, label: Text(context.tr('amount'))),
                ],
                selected: {vm.draft.isAmountDiscount},
                onSelectionChanged: (s) =>
                    vm.setDiscount(_discount.text, isAmount: s.first),
              ),
            ],
          ),
          SizedBox(height: InSpacing.lg(context)),
          _DesignPicker(vm: vm),
          SizedBox(height: InSpacing.lg(context)),
          EntityCustomFieldsSection(
            keyPrefix: 'invoice',
            companyStream: context.read<Services>().company.watchCompany(
              vm.companyId,
            ),
            values: [
              vm.draft.customValue1,
              vm.draft.customValue2,
              vm.draft.customValue3,
              vm.draft.customValue4,
            ],
            onChanged: [
              vm.setCustomValue1,
              vm.setCustomValue2,
              vm.setCustomValue3,
              vm.setCustomValue4,
            ],
            cardTitle: context.tr('custom_fields'),
          ),
        ],
      ),
    );
  }
}

class _DesignPicker extends StatelessWidget {
  const _DesignPicker({required this.vm});
  final InvoiceEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return StreamBuilder<List<Design>>(
      stream: services.designs.watchAll(companyId: vm.companyId),
      builder: (context, snapshot) {
        final designs = snapshot.data ?? const <Design>[];
        Design? selected;
        for (final d in designs) {
          if (d.id == vm.draft.designId) {
            selected = d;
            break;
          }
        }
        return SearchableDropdownField<Design>(
          label: context.tr('design'),
          items: designs,
          initialValue: selected,
          displayString: (d) => d.name,
          idOf: (d) => d.id,
          onChanged: (d) => vm.setDesignId(d?.id ?? ''),
        );
      },
    );
  }
}

class _ClientPicker extends StatelessWidget {
  const _ClientPicker({required this.vm});
  final InvoiceEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = vm.companyId;
    // Watch the client list from the repo. The dropdown handles the
    // searchability; the caller only needs a snapshot list.
    return StreamBuilder<List<Client>>(
      stream: services.clients.watchPage(
        companyId: companyId,
        loadedPages: 100,
      ),
      builder: (context, snapshot) {
        final clients = snapshot.data ?? const <Client>[];
        Client? selected;
        for (final c in clients) {
          if (c.id == vm.draft.clientId) {
            selected = c;
            break;
          }
        }
        return SearchableDropdownField<Client>(
          label: context.tr('client'),
          items: clients,
          initialValue: selected,
          displayString: (c) => c.displayName.isEmpty ? c.name : c.displayName,
          idOf: (c) => c.id,
          onChanged: (c) => vm.setClientId(c?.id ?? ''),
          errorText: vm.fieldErrorFor('client_id'),
        );
      },
    );
  }
}

// ── Contacts tab ─────────────────────────────────────────────────────

class _ContactsTab extends StatelessWidget {
  const _ContactsTab({required this.vm});
  final InvoiceEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.draft.clientId.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(InSpacing.lg(context)),
          child: Text(
            context.tr('select_a_client_first'),
            style: TextStyle(color: context.inTheme.ink3),
          ),
        ),
      );
    }
    final services = context.read<Services>();
    return StreamBuilder<Client?>(
      stream: services.clients.watch(
        companyId: vm.companyId,
        id: vm.draft.clientId,
      ),
      builder: (context, snapshot) {
        final client = snapshot.data;
        if (client == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final selected = vm.draft.invitations
            .map((i) => i.clientContactId)
            .where((id) => id.isNotEmpty)
            .toSet();
        return ListView(
          padding: EdgeInsets.symmetric(vertical: InSpacing.lg(context)),
          children: [
            BillingDocContactsSection(
              contacts: client.contacts.map((c) => c.toBilling()).toList(),
              selectedContactIds: selected,
              onChanged: (next) {
                final added = next.difference(selected);
                final removed = selected.difference(next);
                for (final id in added) {
                  vm.setContactInvitation(id, true);
                }
                for (final id in removed) {
                  vm.setContactInvitation(id, false);
                }
              },
            ),
          ],
        );
      },
    );
  }
}

// ── Items tab ────────────────────────────────────────────────────────

class _ItemsTab extends StatelessWidget {
  const _ItemsTab({required this.vm});
  final InvoiceEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(InSpacing.lg(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(bottom: InSpacing.md(context)),
              child: AddUnbilledItemsButton(
                companyId: vm.companyId,
                clientId: vm.draft.clientId,
                onAdd: (added) => _appendUnbilledLineItems(vm, added),
              ),
            ),
          ),
          LineItemEditor(
            companyId: vm.companyId,
            items: vm.draft.lineItems,
            onChanged: vm.replaceLineItems,
            newItemFactory: emptyLineItem,
            // M3 first cut: minimal config (qty / cost / total only). M4
            // wires this to `company.settings.{enable_product_discount,
            // enabled_item_tax_rates, custom_fields.product1..product4}`
            // so the visible columns match the company config.
            config: const LineItemColumnConfig(
              showDiscount: true,
              taxColumnCount: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notes tab ────────────────────────────────────────────────────────

class _NotesTab extends StatelessWidget {
  const _NotesTab({required this.vm});
  final InvoiceEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    // Widget-order Tab traversal: this ListView leaves off-screen markdown
    // fields built-but-unlaid, and reading-order traversal would call
    // `FocusNode.rect` on their host nodes → `hasSize` assertion. Source
    // order == visual order here, so the Tab sequence is unchanged.
    return FocusTraversalGroup(
      policy: WidgetOrderTraversalPolicy(),
      child: ListView(
        padding: EdgeInsets.all(InSpacing.lg(context)),
        children: [
          MarkdownNotesField(
            label: context.tr('public_notes'),
            value: vm.draft.publicNotes,
            onChanged: vm.setPublicNotes,
          ),
          SizedBox(height: InSpacing.lg(context)),
          MarkdownNotesField(
            label: context.tr('private_notes'),
            value: vm.draft.privateNotes,
            onChanged: vm.setPrivateNotes,
          ),
          SizedBox(height: InSpacing.lg(context)),
          MarkdownNotesField(
            label: context.tr('terms'),
            value: vm.draft.terms,
            onChanged: vm.setTerms,
            onSaveAsDefault: (v) => saveBillingDocDefault(
              context,
              companyId: vm.companyId,
              value: v,
              fieldKey: 'invoice_terms',
              successKey: 'updated_default_terms',
              apply: (s, val) => s.copyWith(invoiceTerms: val),
            ),
          ),
          SizedBox(height: InSpacing.lg(context)),
          MarkdownNotesField(
            label: context.tr('footer'),
            value: vm.draft.footer,
            onChanged: vm.setFooter,
            onSaveAsDefault: (v) => saveBillingDocDefault(
              context,
              companyId: vm.companyId,
              value: v,
              fieldKey: 'invoice_footer',
              successKey: 'updated_default_footer',
              apply: (s, val) => s.copyWith(invoiceFooter: val),
            ),
          ),
        ],
      ),
    );
  }
}

// ── PDF tab ──────────────────────────────────────────────────────────

class _PdfTab extends StatelessWidget {
  const _PdfTab({required this.vm});
  final InvoiceEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.isCreate || vm.draft.id.isEmpty || vm.draft.id.startsWith('tmp_')) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(InSpacing.lg(context)),
          child: Text(
            context.tr('save_first_to_preview'),
            style: TextStyle(color: context.inTheme.ink3),
          ),
        ),
      );
    }
    final services = context.read<Services>();
    return BillingDocPdfView(
      entity: BillingDocType.invoice,
      entityNumber: vm.draft.number,
      fetcher: ({String? designId, required bool deliveryNote}) =>
          services.invoices.api.downloadPdf(
            entityJson: vm.draft.toApiJson(),
            designId:
                designId ??
                (vm.draft.designId.isEmpty ? null : vm.draft.designId),
            deliveryNote: deliveryNote,
          ),
    );
  }
}

// The shared e-invoice tab lives in
// `billing_shared/edit/e_invoice_fields_tab.dart` (used by invoice / credit
// / recurring). Invoices additionally surface a Verifactu document-type
// chip derived from the server-only `backup` map — credit / recurring don't
// carry that, so the chip is invoice-only via this helper.
String? _invoiceDocType(Invoice d) {
  final b = d.backup;
  final v = b is Map<String, dynamic> ? b['document_type'] : null;
  return v is String ? v : null;
}
