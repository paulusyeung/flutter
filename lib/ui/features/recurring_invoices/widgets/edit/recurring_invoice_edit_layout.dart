import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:admin/ui/features/recurring_invoices/view_models/recurring_invoice_edit_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';

/// Tabbed body for the recurring-invoice edit screen. Adds a Schedule
/// tab to the Quote/Credit/PO layout for frequency + next_send_date +
/// remaining_cycles + auto_bill.
class RecurringInvoiceEditLayout extends StatefulWidget {
  const RecurringInvoiceEditLayout({super.key, required this.vm});

  final RecurringInvoiceEditViewModel vm;

  @override
  State<RecurringInvoiceEditLayout> createState() =>
      _RecurringInvoiceEditLayoutState();
}

class _RecurringInvoiceEditLayoutState extends State<RecurringInvoiceEditLayout>
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

  Widget _stickyTotals(BuildContext context) => Padding(
        padding: EdgeInsets.all(InSpacing.md(context)),
        child: TotalsWidget(
          totals: widget.vm.totals,
          discount: widget.vm.draft.discount,
          discountIsAmount: widget.vm.draft.isAmountDiscount,
          dense: true,
        ),
      );

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
              Tab(text: context.tr('schedule')),
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
              _ScheduleTab(vm: widget.vm),
              _ContactsTab(vm: widget.vm),
              _ItemsTab(vm: widget.vm),
              _NotesTab(vm: widget.vm),
              _PdfTab(vm: widget.vm),
            ],
          ),
        ),
        Divider(height: 1, color: tokens.border),
        _stickyTotals(context),
      ],
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return BillingDocEditDesktopShell(
      topRow: (ctx, slot) => switch (slot) {
        0 => _ClientCardDesktop(vm: widget.vm),
        1 => _ScheduleCardDesktop(vm: widget.vm),
        2 => _NumberCardDesktop(vm: widget.vm),
        _ => const SizedBox.shrink(),
      },
      itemsSection: _ItemsSectionDesktop(vm: widget.vm),
      notesTabsCard: _NotesTabsCardDesktop(vm: widget.vm),
      pdfPane: _PdfPaneDesktop(vm: widget.vm),
      stickyTotals: _stickyTotals(context),
      isDirty: !widget.vm.isCreate && widget.vm.isDirty && !widget.vm.isSaving,
    );
  }
}

// ── Desktop multi-column cards ───────────────────────────────────────

class _ClientCardDesktop extends StatelessWidget {
  const _ClientCardDesktop({required this.vm});
  final RecurringInvoiceEditViewModel vm;

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
  final RecurringInvoiceEditViewModel vm;

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

class _ScheduleCardDesktop extends StatefulWidget {
  const _ScheduleCardDesktop({required this.vm});
  final RecurringInvoiceEditViewModel vm;

  @override
  State<_ScheduleCardDesktop> createState() => _ScheduleCardDesktopState();
}

class _ScheduleCardDesktopState extends State<_ScheduleCardDesktop> {
  late final TextEditingController _remainingCycles;
  late final TextEditingController _dueDateDays;

  @override
  void initState() {
    super.initState();
    _remainingCycles = TextEditingController(
      text: widget.vm.draft.remainingCycles < 0
          ? ''
          : '${widget.vm.draft.remainingCycles}',
    );
    _dueDateDays = TextEditingController(text: widget.vm.draft.dueDateDays);
  }

  @override
  void dispose() {
    _remainingCycles.dispose();
    _dueDateDays.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    return FormSection(
      title: context.tr('schedule'),
      children: [
        DropdownButtonFormField<String>(
          initialValue:
              vm.draft.frequencyId.isEmpty ? null : vm.draft.frequencyId,
          decoration: InputDecoration(labelText: context.tr('frequency')),
          items: _frequencyItemsStatic(context),
          onChanged: (v) => vm.setFrequencyId(v ?? ''),
        ),
        SizedBox(height: InSpacing.md(context)),
        InDateField(
          value: vm.draft.nextSendDate?.toDateTime(),
          onChanged: (d) {
            if (d == null) {
              vm.setNextSendDate(null);
            } else {
              vm.setNextSendDate(Date(d.year, d.month, d.day));
            }
          },
          labelText: context.tr('next_send_date'),
          clearable: true,
        ),
        SizedBox(height: InSpacing.md(context)),
        TextField(
          controller: _remainingCycles,
          decoration: InputDecoration(
            labelText: context.tr('remaining_cycles'),
            hintText: '-1 = ${context.tr('endless')}',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'-?\d*')),
          ],
          onChanged: (v) {
            final parsed = int.tryParse(v.trim());
            if (parsed != null) vm.setRemainingCycles(parsed);
          },
        ),
        SizedBox(height: InSpacing.md(context)),
        TextField(
          controller: _dueDateDays,
          decoration: InputDecoration(labelText: context.tr('due_date_days')),
          onChanged: vm.setDueDateDays,
        ),
        SizedBox(height: InSpacing.md(context)),
        DropdownButtonFormField<String>(
          initialValue: vm.draft.autoBill.isEmpty ? 'off' : vm.draft.autoBill,
          decoration: InputDecoration(labelText: context.tr('auto_bill')),
          items: [
            DropdownMenuItem(value: 'off', child: Text(context.tr('off'))),
            DropdownMenuItem(value: 'always', child: Text(context.tr('enabled'))),
            DropdownMenuItem(value: 'optout', child: Text(context.tr('opt_out'))),
            DropdownMenuItem(value: 'optin', child: Text(context.tr('opt_in'))),
          ],
          onChanged: (v) => vm.setAutoBill(v ?? 'off'),
        ),
      ],
    );
  }
}

class _NumberCardDesktop extends StatefulWidget {
  const _NumberCardDesktop({required this.vm});
  final RecurringInvoiceEditViewModel vm;

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
          decoration: InputDecoration(labelText: context.tr('po_number')),
          onChanged: vm.setPoNumber,
        ),
        SizedBox(height: InSpacing.md(context)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: _discount,
                decoration: InputDecoration(labelText: context.tr('discount')),
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
  final RecurringInvoiceEditViewModel vm;

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
  final RecurringInvoiceEditViewModel vm;

  @override
  State<_NotesTabsCardDesktop> createState() => _NotesTabsCardDesktopState();
}

class _NotesTabsCardDesktopState extends State<_NotesTabsCardDesktop>
    with SingleTickerProviderStateMixin {
  late final TabController _ctl = TabController(length: 4, vsync: this);

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
          ],
        ),
        SizedBox(
          height: (MediaQuery.sizeOf(context).height * 0.4).clamp(280.0, 520.0),
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
            ],
          ),
        ),
      ],
    );
  }
}

class _PdfPaneDesktop extends StatelessWidget {
  const _PdfPaneDesktop({required this.vm});
  final RecurringInvoiceEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: context.tr('pdf'),
      children: [
        SizedBox(
          height: (MediaQuery.sizeOf(context).height * 0.55).clamp(380.0, 720.0),
          child: _PdfTab(vm: vm),
        ),
      ],
    );
  }
}

List<DropdownMenuItem<String>> _frequencyItemsStatic(BuildContext context) {
  // Mirrors the existing `_ScheduleTabState._frequencyItems` — duplicated
  // here so the desktop card can stay independent of the mobile state.
  const ids = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
  ];
  const labels = [
    'frequency_daily',
    'frequency_weekly',
    'frequency_two_weeks',
    'frequency_four_weeks',
    'frequency_monthly',
    'frequency_two_months',
    'frequency_three_months',
    'frequency_four_months',
    'frequency_six_months',
    'frequency_annually',
    'frequency_two_years',
    'frequency_three_years',
    'frequency_custom',
  ];
  return [
    for (var i = 0; i < ids.length; i++)
      DropdownMenuItem(value: ids[i], child: Text(context.tr(labels[i]))),
  ];
}

class _DetailsTab extends StatefulWidget {
  const _DetailsTab({required this.vm});
  final RecurringInvoiceEditViewModel vm;
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
          _ClientPicker(vm: vm),
          SizedBox(height: InSpacing.lg(context)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _number,
                  decoration: InputDecoration(
                    labelText: context.tr('recurring_invoice_number'),
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
  final RecurringInvoiceEditViewModel vm;

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

class _ScheduleTab extends StatefulWidget {
  const _ScheduleTab({required this.vm});
  final RecurringInvoiceEditViewModel vm;
  @override
  State<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<_ScheduleTab> {
  late final TextEditingController _remainingCycles;
  late final TextEditingController _dueDateDays;

  @override
  void initState() {
    super.initState();
    _remainingCycles = TextEditingController(
      text: widget.vm.draft.remainingCycles < 0
          ? ''
          : '${widget.vm.draft.remainingCycles}',
    );
    _dueDateDays = TextEditingController(text: widget.vm.draft.dueDateDays);
  }

  @override
  void dispose() {
    _remainingCycles.dispose();
    _dueDateDays.dispose();
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
          DropdownButtonFormField<String>(
            initialValue: vm.draft.frequencyId.isEmpty
                ? null
                : vm.draft.frequencyId,
            decoration: InputDecoration(labelText: context.tr('frequency')),
            items: _frequencyItems(context),
            onChanged: (v) => vm.setFrequencyId(v ?? ''),
          ),
          SizedBox(height: InSpacing.md(context)),
          InDateField(
            value: vm.draft.nextSendDate?.toDateTime(),
            onChanged: (d) {
              if (d == null) {
                vm.setNextSendDate(null);
              } else {
                vm.setNextSendDate(Date(d.year, d.month, d.day));
              }
            },
            labelText: context.tr('next_send_date'),
            clearable: true,
          ),
          SizedBox(height: InSpacing.md(context)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _remainingCycles,
                  decoration: InputDecoration(
                    labelText: context.tr('remaining_cycles'),
                    hintText: '-1 = ${context.tr('endless')}',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'-?\d*')),
                  ],
                  onChanged: (v) {
                    final parsed = int.tryParse(v.trim());
                    if (parsed != null) vm.setRemainingCycles(parsed);
                  },
                ),
              ),
              SizedBox(width: InSpacing.md(context)),
              Expanded(
                child: TextField(
                  controller: _dueDateDays,
                  decoration: InputDecoration(
                    labelText: context.tr('due_date_days'),
                  ),
                  onChanged: vm.setDueDateDays,
                ),
              ),
            ],
          ),
          SizedBox(height: InSpacing.lg(context)),
          DropdownButtonFormField<String>(
            initialValue: vm.draft.autoBill.isEmpty ? 'off' : vm.draft.autoBill,
            decoration: InputDecoration(labelText: context.tr('auto_bill')),
            items: [
              DropdownMenuItem(value: 'off', child: Text(context.tr('off'))),
              DropdownMenuItem(
                value: 'always',
                child: Text(context.tr('enabled')),
              ),
              DropdownMenuItem(
                value: 'optout',
                child: Text(context.tr('opt_out')),
              ),
              DropdownMenuItem(
                value: 'optin',
                child: Text(context.tr('opt_in')),
              ),
            ],
            onChanged: (v) => vm.setAutoBill(v ?? 'off'),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _frequencyItems(BuildContext context) =>
      const [
        DropdownMenuItem(value: '1', child: Text('Daily')),
        DropdownMenuItem(value: '2', child: Text('Weekly')),
        DropdownMenuItem(value: '3', child: Text('Every 2 weeks')),
        DropdownMenuItem(value: '4', child: Text('Every 4 weeks')),
        DropdownMenuItem(value: '5', child: Text('Monthly')),
        DropdownMenuItem(value: '6', child: Text('Every 2 months')),
        DropdownMenuItem(value: '7', child: Text('Every 3 months')),
        DropdownMenuItem(value: '8', child: Text('Every 4 months')),
        DropdownMenuItem(value: '9', child: Text('Every 6 months')),
        DropdownMenuItem(value: '10', child: Text('Annually')),
        DropdownMenuItem(value: '11', child: Text('Every 2 years')),
        DropdownMenuItem(value: '12', child: Text('Every 3 years')),
      ];
}

class _ClientPicker extends StatelessWidget {
  const _ClientPicker({required this.vm});
  final RecurringInvoiceEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return StreamBuilder<List<Client>>(
      stream: services.clients.watchPage(
        companyId: vm.companyId,
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

class _ContactsTab extends StatelessWidget {
  const _ContactsTab({required this.vm});
  final RecurringInvoiceEditViewModel vm;

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

class _ItemsTab extends StatelessWidget {
  const _ItemsTab({required this.vm});
  final RecurringInvoiceEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(InSpacing.lg(context)),
      child: LineItemEditor(
        companyId: vm.companyId,
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
  final RecurringInvoiceEditViewModel vm;

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
  final RecurringInvoiceEditViewModel vm;

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
      entity: BillingDocType.recurringInvoice,
      entityNumber: vm.draft.number,
      fetcher: ({String? designId, required bool deliveryNote}) =>
          services.recurringInvoices.api.downloadPdf(
        id: vm.draft.id,
        designId: designId ??
            (vm.draft.designId.isEmpty ? null : vm.draft.designId),
      ),
    );
  }
}
