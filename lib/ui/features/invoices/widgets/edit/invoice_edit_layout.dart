import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/billing/billing_contact.dart';
import 'package:admin/data/models/domain/billing/line_item.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/models/domain/design.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_custom_fields_section.dart';
import 'package:admin/ui/core/widgets/in_date_field.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
import 'package:admin/ui/features/billing_shared/billing_doc_type.dart';
import 'package:admin/ui/features/billing_shared/contacts/billing_doc_contacts_section.dart';
import 'package:admin/ui/features/billing_shared/edit/billing_doc_edit_desktop_shell.dart';
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
  late final TabController _tab = TabController(length: 6, vsync: this);

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
    return Column(
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
              _EInvoiceTab(vm: widget.vm),
            ],
          ),
        ),
        Divider(height: 1, color: tokens.border),
        _StickyTotals(vm: widget.vm),
      ],
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
      pdfPane: _PdfPaneDesktop(vm: widget.vm),
      stickyTotals: _StickyTotals(vm: widget.vm),
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
      title: context.tr('client'),
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
      return Text(
        context.tr('select_a_client_first'),
        style: TextStyle(color: context.inTheme.ink3, fontSize: 12),
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
        if (client == null) return const SizedBox.shrink();
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
    return FormSection(
      title: context.tr('dates'),
      children: [
        InDateField(
          value: vm.draft.date?.toDateTime(),
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
          decoration: InputDecoration(
            labelText: context.tr('partial'),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: vm.setPartial,
        ),
        SizedBox(height: InSpacing.md(context)),
        InDateField(
          value: vm.draft.partialDueDate?.toDateTime(),
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
      title: context.tr('number'),
      children: [
        TextField(
          controller: _number,
          decoration: InputDecoration(
            labelText: context.tr('invoice_number'),
            hintText: vm.isCreate ? context.tr('auto_generated') : null,
            errorText: vm.fieldErrorFor('number'),
          ),
          onChanged: vm.setNumber,
        ),
        SizedBox(height: InSpacing.md(context)),
        TextField(
          controller: _poNumber,
          decoration: InputDecoration(
            labelText: context.tr('po_number'),
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
                decoration: InputDecoration(
                  labelText: context.tr('discount'),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (v) => vm.setDiscount(
                  v,
                  isAmount: vm.draft.isAmountDiscount,
                ),
              ),
            ),
            SizedBox(width: InSpacing.md(context)),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(context.tr('percent'))),
                ButtonSegment(value: true, label: Text(context.tr('amount'))),
              ],
              selected: {vm.draft.isAmountDiscount},
              onSelectionChanged: (s) => vm.setDiscount(
                _discount.text,
                isAmount: s.first,
              ),
            ),
          ],
        ),
        SizedBox(height: InSpacing.md(context)),
        _DesignPicker(vm: vm),
        SizedBox(height: InSpacing.md(context)),
        EntityCustomFieldsSection(
          keyPrefix: 'invoice',
          companyStream:
              context.read<Services>().company.watchCompany(vm.companyId),
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
    _unregisterFlush =
        widget.vm.addBeforeSaveHook(_tableController.flushPending);
    _unregisterStrip =
        widget.vm.addBeforeSaveHook(widget.vm.stripEmptyLineItems);
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
    return LineItemEditor(
      companyId: vm.companyId,
      items: vm.draft.lineItems,
      onChanged: vm.replaceLineItems,
      newItemFactory: emptyLineItem,
      config: const LineItemColumnConfig(
        showDiscount: true,
        taxColumnCount: 1,
      ),
      controller: _tableController,
    );
  }
}

class _NotesTabsCardDesktop extends StatefulWidget {
  const _NotesTabsCardDesktop({required this.vm});
  final InvoiceEditViewModel vm;

  @override
  State<_NotesTabsCardDesktop> createState() => _NotesTabsCardDesktopState();
}

class _NotesTabsCardDesktopState extends State<_NotesTabsCardDesktop>
    with SingleTickerProviderStateMixin {
  late final TabController _ctl = TabController(length: 5, vsync: this);

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
      title: context.tr('notes'),
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
            Tab(text: context.tr('e_invoice')),
          ],
        ),
        SizedBox(
          height: BillingDocEditDesktopShell.bottomPaneHeight(context),
          child: TabBarView(
            controller: _ctl,
            children: [
              MarkdownNotesField(
                label: context.tr('terms'),
                value: vm.draft.terms,
                onChanged: vm.setTerms,
                onSaveAsDefault: null,
              ),
              MarkdownNotesField(
                label: context.tr('footer'),
                value: vm.draft.footer,
                onChanged: vm.setFooter,
                onSaveAsDefault: null,
              ),
              MarkdownNotesField(
                label: context.tr('public_notes'),
                value: vm.draft.publicNotes,
                onChanged: vm.setPublicNotes,
              ),
              MarkdownNotesField(
                label: context.tr('private_notes'),
                value: vm.draft.privateNotes,
                onChanged: vm.setPrivateNotes,
              ),
              _EInvoiceTab(vm: vm),
            ],
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
      title: context.tr('pdf'),
      children: [
        SizedBox(
          height: BillingDocEditDesktopShell.bottomPaneHeight(context),
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
                  decoration: InputDecoration(
                    labelText: context.tr('partial'),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: vm.setPartial,
                ),
              ),
              SizedBox(width: InSpacing.md(context)),
              Expanded(
                child: InDateField(
                  value: vm.draft.partialDueDate?.toDateTime(),
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
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) => vm.setDiscount(
                    v,
                    isAmount: vm.draft.isAmountDiscount,
                  ),
                ),
              ),
              SizedBox(width: InSpacing.md(context)),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(context.tr('percent'))),
                  ButtonSegment(value: true, label: Text(context.tr('amount'))),
                ],
                selected: {vm.draft.isAmountDiscount},
                onSelectionChanged: (s) => vm.setDiscount(
                  _discount.text,
                  isAmount: s.first,
                ),
              ),
            ],
          ),
          SizedBox(height: InSpacing.lg(context)),
          _DesignPicker(vm: vm),
          SizedBox(height: InSpacing.lg(context)),
          EntityCustomFieldsSection(
            keyPrefix: 'invoice',
            companyStream:
                context.read<Services>().company.watchCompany(vm.companyId),
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
      child: LineItemEditor(
        companyId: vm.companyId,
        items: vm.draft.lineItems,
        onChanged: vm.replaceLineItems,
        newItemFactory: emptyLineItem,
        // M3 first cut: minimal config (qty / cost / total only). M4 wires
        // this to `company.settings.{enable_product_discount,
        // enabled_item_tax_rates, custom_fields.product1..product4}` so
        // the visible columns match the company config.
        config: const LineItemColumnConfig(
          showDiscount: true,
          taxColumnCount: 1,
        ),
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
    return ListView(
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
          // "Save as default" wires to company.settings.invoice_terms — the
          // host (Services.company) handles the cascade write. Stub for
          // M3; full wiring lands when the settings-cascade hook reaches
          // the edit screen.
          onSaveAsDefault: null,
        ),
        SizedBox(height: InSpacing.lg(context)),
        MarkdownNotesField(
          label: context.tr('footer'),
          value: vm.draft.footer,
          onChanged: vm.setFooter,
          onSaveAsDefault: null,
        ),
      ],
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
        id: vm.draft.id,
        designId: designId ??
            (vm.draft.designId.isEmpty ? null : vm.draft.designId),
        deliveryNote: deliveryNote,
      ),
    );
  }
}

// ── E-Invoice tab ────────────────────────────────────────────────────
//
// PEPPOL UBL is open-ended on the wire — `invoice.eInvoice` is a
// `Map<String, dynamic>` rather than a typed model. This tab surfaces the
// two fields most commonly edited (invoice period start + end) and the
// document type read-out (F1 / R1 / R2 for Verifactu). Other PEPPOL
// fields (buyer reference, contract document reference, project reference)
// land via inline editing on the raw map when needed — typed accessors
// are a follow-up.
class _EInvoiceTab extends StatelessWidget {
  const _EInvoiceTab({required this.vm});
  final InvoiceEditViewModel vm;

  Date? _readDate(String key) {
    // Common PEPPOL shape: `eInvoice.Invoice.InvoicePeriod.0.StartDate`.
    // The map is open-ended; surface the top-level mirror keys
    // `invoice_period_start` / `invoice_period_end` as well so the
    // server's denormalized convenience keys round-trip.
    final raw = vm.draft.eInvoice?[key];
    if (raw is String) return Date.tryParse(raw);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final backup = vm.draft.backup;
    final documentType =
        backup is Map<String, dynamic> ? backup['document_type'] : null;
    return ListView(
      padding: EdgeInsets.all(InSpacing.lg(context)),
      children: [
        if (documentType is String && documentType.isNotEmpty)
          Container(
            margin: EdgeInsets.only(bottom: InSpacing.md(context)),
            padding: EdgeInsets.all(InSpacing.md(context)),
            decoration: BoxDecoration(
              border: Border.all(color: tokens.border),
              borderRadius: BorderRadius.circular(InRadii.r2),
              color: tokens.surface,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.qr_code_2_outlined,
                  size: 18,
                  color: tokens.ink3,
                ),
                const SizedBox(width: 8),
                Text(
                  context.tr('document_type'),
                  style: TextStyle(color: tokens.ink3, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  documentType,
                  style: TextStyle(
                    color: tokens.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        InDateField(
          value: _readDate('invoice_period_start')?.toDateTime(),
          onChanged: (d) => vm.setEInvoiceField(
            'invoice_period_start',
            d == null ? null : Date(d.year, d.month, d.day).toIso(),
          ),
          labelText: context.tr('invoice_period_start'),
          clearable: true,
        ),
        SizedBox(height: InSpacing.md(context)),
        InDateField(
          value: _readDate('invoice_period_end')?.toDateTime(),
          onChanged: (d) => vm.setEInvoiceField(
            'invoice_period_end',
            d == null ? null : Date(d.year, d.month, d.day).toIso(),
          ),
          labelText: context.tr('invoice_period_end'),
          clearable: true,
        ),
        SizedBox(height: InSpacing.lg(context)),
        Text(
          context.tr('einvoice_help'),
          style: TextStyle(color: tokens.ink3, fontSize: 12),
        ),
      ],
    );
  }
}
