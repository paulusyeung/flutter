import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/billing/billing_contact.dart';
import 'package:admin/data/models/domain/billing/line_item.dart';
import 'package:admin/data/models/domain/design.dart';
import 'package:admin/data/models/domain/vendor.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_custom_fields_section.dart';
import 'package:admin/ui/core/widgets/in_date_field.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
import 'package:admin/ui/features/billing_shared/billing_doc_type.dart';
import 'package:admin/ui/features/billing_shared/contacts/billing_doc_contacts_section.dart';
import 'package:admin/ui/features/billing_shared/line_item_editor/line_item_column_config.dart';
import 'package:admin/ui/features/billing_shared/line_item_editor/line_item_editor.dart';
import 'package:admin/ui/features/billing_shared/markdown_notes_section.dart';
import 'package:admin/ui/features/billing_shared/pdf/billing_doc_pdf_view.dart';
import 'package:admin/ui/features/billing_shared/totals_widget.dart';
import 'package:admin/ui/features/purchase_orders/view_models/purchase_order_edit_view_model.dart';

/// Tabbed body for the purchase order edit screen. Same shape as the
/// quote / credit edit layouts — Details / Contacts / Items / Notes /
/// PDF — but vendor-centric (vendor picker + vendor contacts).
class PurchaseOrderEditLayout extends StatefulWidget {
  const PurchaseOrderEditLayout({super.key, required this.vm});

  final PurchaseOrderEditViewModel vm;

  @override
  State<PurchaseOrderEditLayout> createState() =>
      _PurchaseOrderEditLayoutState();
}

class _PurchaseOrderEditLayoutState extends State<PurchaseOrderEditLayout>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 5, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return AnimatedBuilder(
      animation: widget.vm,
      builder: (context, _) {
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
                ],
              ),
            ),
            Divider(height: 1, color: tokens.border),
            Padding(
              padding: EdgeInsets.all(InSpacing.md(context)),
              child: TotalsWidget(
                totals: widget.vm.totals,
                discount: widget.vm.draft.discount,
                discountIsAmount: widget.vm.draft.isAmountDiscount,
                dense: true,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DetailsTab extends StatefulWidget {
  const _DetailsTab({required this.vm});
  final PurchaseOrderEditViewModel vm;
  @override
  State<_DetailsTab> createState() => _DetailsTabState();
}

class _DetailsTabState extends State<_DetailsTab> {
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
    return SingleChildScrollView(
      padding: EdgeInsets.all(InSpacing.lg(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _VendorPicker(vm: vm),
          SizedBox(height: InSpacing.lg(context)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _number,
                  decoration: InputDecoration(
                    labelText: context.tr('purchase_order_number'),
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
                  labelText: context.tr('date'),
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
  final PurchaseOrderEditViewModel vm;

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

class _VendorPicker extends StatelessWidget {
  const _VendorPicker({required this.vm});
  final PurchaseOrderEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return StreamBuilder<List<Vendor>>(
      stream: services.vendors.watchPage(
        companyId: vm.companyId,
        loadedPages: 100,
      ),
      builder: (context, snapshot) {
        final vendors = snapshot.data ?? const <Vendor>[];
        Vendor? selected;
        for (final v in vendors) {
          if (v.id == vm.draft.vendorId) {
            selected = v;
            break;
          }
        }
        return SearchableDropdownField<Vendor>(
          label: context.tr('vendor'),
          items: vendors,
          initialValue: selected,
          displayString: (v) => v.name,
          idOf: (v) => v.id,
          onChanged: (v) => vm.setVendorId(v?.id ?? ''),
          errorText: vm.fieldErrorFor('vendor_id'),
        );
      },
    );
  }
}

class _ContactsTab extends StatelessWidget {
  const _ContactsTab({required this.vm});
  final PurchaseOrderEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.draft.vendorId.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(InSpacing.lg(context)),
          child: Text(
            context.tr('select_a_vendor_first'),
            style: TextStyle(color: context.inTheme.ink3),
          ),
        ),
      );
    }
    final services = context.read<Services>();
    return StreamBuilder<Vendor?>(
      stream: services.vendors.watch(
        companyId: vm.companyId,
        id: vm.draft.vendorId,
      ),
      builder: (context, snapshot) {
        final vendor = snapshot.data;
        if (vendor == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final selected = vm.draft.invitations
            .map((i) => i.vendorContactId)
            .where((id) => id.isNotEmpty)
            .toSet();
        return ListView(
          padding: EdgeInsets.symmetric(vertical: InSpacing.lg(context)),
          children: [
            BillingDocContactsSection(
              contacts: vendor.contacts.map((c) => c.toBilling()).toList(),
              selectedContactIds: selected,
              onChanged: (next) {
                final added = next.difference(selected);
                final removed = selected.difference(next);
                for (final id in added) {
                  vm.setVendorContactInvitation(id, true);
                }
                for (final id in removed) {
                  vm.setVendorContactInvitation(id, false);
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class _ItemsTab extends StatelessWidget {
  const _ItemsTab({required this.vm});
  final PurchaseOrderEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(InSpacing.lg(context)),
      child: LineItemEditor(
        items: vm.draft.lineItems,
        onChanged: vm.replaceLineItems,
        newItemFactory: emptyLineItem,
        config: const LineItemColumnConfig(
          showDiscount: true,
          taxColumnCount: 1,
        ),
      ),
    );
  }
}

class _NotesTab extends StatelessWidget {
  const _NotesTab({required this.vm});
  final PurchaseOrderEditViewModel vm;

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
        ),
        SizedBox(height: InSpacing.lg(context)),
        MarkdownNotesField(
          label: context.tr('footer'),
          value: vm.draft.footer,
          onChanged: vm.setFooter,
        ),
      ],
    );
  }
}

class _PdfTab extends StatelessWidget {
  const _PdfTab({required this.vm});
  final PurchaseOrderEditViewModel vm;

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
      entity: BillingDocType.purchaseOrder,
      entityNumber: vm.draft.number,
      fetcher: ({String? designId, required bool deliveryNote}) =>
          services.purchaseOrders.api.downloadPdf(
        id: vm.draft.id,
        designId: designId ??
            (vm.draft.designId.isEmpty ? null : vm.draft.designId),
      ),
    );
  }
}
