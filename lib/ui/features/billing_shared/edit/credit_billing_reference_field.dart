import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/credit.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/in_date_field.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
import 'package:admin/ui/features/billing_shared/view_models/billing_doc_edit_view_model.dart';
import 'package:admin/utils/formatting.dart';

/// PEPPOL billing reference for a credit note: the originating invoice +
/// its issue date, stored under
/// `e_invoice.CreditNote.BillingReference.0.InvoiceDocumentReference.{ID,IssueDate}`
/// (a UBL array — note the list index, not a `"0"` map key).
///
/// Picking an invoice auto-fills both fields (ID = the human document
/// number per PEPPOL, IssueDate = the invoice date) so the common path is
/// zero typing. The issue-date field only appears once an invoice is
/// chosen and stays editable for the rare manual override. Candidate
/// invoices are scoped to the credit's client.
class CreditBillingReferenceField extends StatefulWidget {
  const CreditBillingReferenceField({
    required this.vm,
    required this.companyId,
    this.formatter,
    super.key,
  });

  final GenericBillingDocEditViewModel<Credit> vm;
  final String companyId;
  final Formatter? formatter;

  static const idPath = <Object>[
    'CreditNote',
    'BillingReference',
    0,
    'InvoiceDocumentReference',
    'ID',
  ];
  static const issueDatePath = <Object>[
    'CreditNote',
    'BillingReference',
    0,
    'InvoiceDocumentReference',
    'IssueDate',
  ];

  @override
  State<CreditBillingReferenceField> createState() =>
      _CreditBillingReferenceFieldState();
}

class _CreditBillingReferenceFieldState
    extends State<CreditBillingReferenceField> {
  List<Invoice> _invoices = const [];
  bool _loading = true;
  late String _clientId;

  @override
  void initState() {
    super.initState();
    _clientId = widget.vm.draft.clientId;
    if (_clientId.isEmpty) {
      _loading = false;
    } else {
      _load();
    }
    // The credit's client can be chosen later (new credit) or changed on
    // another tab — the VM is a ChangeNotifier, so react to that and
    // reload the candidate invoices when the client actually changes.
    widget.vm.addListener(_onVmChanged);
  }

  @override
  void dispose() {
    widget.vm.removeListener(_onVmChanged);
    super.dispose();
  }

  void _onVmChanged() {
    final next = widget.vm.draft.clientId;
    if (next == _clientId) return;
    setState(() {
      _clientId = next;
      _invoices = const [];
      _loading = next.isNotEmpty;
    });
    if (next.isNotEmpty) _load();
  }

  Future<void> _load() async {
    final services = context.read<Services>();
    final filters = <String, Set<String>>{
      'client_id': {_clientId},
    };
    try {
      const maxPages = 5;
      for (var page = 1; page <= maxPages; page++) {
        final more = await services.invoices.ensurePageLoaded(
          companyId: widget.companyId,
          page: page,
          states: const {EntityState.active},
          extraFilters: filters,
          ignoreCursor: true,
        );
        if (!more) break;
      }
      final invoices = await services.invoices
          .watchForClient(companyId: widget.companyId, clientId: _clientId)
          .first;
      if (!mounted) return;
      setState(() {
        _invoices = invoices;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _displayInvoice(Invoice i) {
    final num = i.number.isNotEmpty ? i.number : i.id;
    final f = widget.formatter;
    final amount = f == null ? '' : ' · ${f.money(i.amount)}';
    final date = i.date == null
        ? ''
        : ' · ${f == null ? i.date!.toIso() : f.date(i.date!.toIso())}';
    return '$num$amount$date';
  }

  void _onPick(Invoice? inv) {
    if (inv == null) {
      widget.vm.setEInvoicePath(CreditBillingReferenceField.idPath, null);
      widget.vm.setEInvoicePath(
        CreditBillingReferenceField.issueDatePath,
        null,
      );
      setState(() {});
      return;
    }
    widget.vm.setEInvoicePath(
      CreditBillingReferenceField.idPath,
      inv.number.isNotEmpty ? inv.number : inv.id,
    );
    widget.vm.setEInvoicePath(
      CreditBillingReferenceField.issueDatePath,
      inv.date?.toIso(),
    );
    setState(() {});
  }

  Date? _readIssueDate() {
    final raw = widget.vm.readEInvoicePath(
      widget.vm.draft,
      CreditBillingReferenceField.issueDatePath,
    );
    return raw is String ? Date.tryParse(raw) : null;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final storedId = widget.vm.readEInvoicePath(
      widget.vm.draft,
      CreditBillingReferenceField.idPath,
    );

    Widget header = Text(
      context.tr('billing_reference'),
      style: TextStyle(
        color: tokens.ink3,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );

    if (_clientId.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          SizedBox(height: InSpacing.md(context)),
          Text(
            context.tr('billing_reference_requires_client'),
            style: TextStyle(color: tokens.ink3, fontSize: 12),
          ),
        ],
      );
    }

    Invoice? selected;
    if (storedId is String && storedId.isNotEmpty) {
      for (final i in _invoices) {
        if (i.number == storedId || i.id == storedId) {
          selected = i;
          break;
        }
      }
    }
    final hasSelection = storedId is String && storedId.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        SizedBox(height: InSpacing.md(context)),
        SearchableDropdownField<Invoice>(
          label: context.tr('invoice'),
          items: _invoices,
          initialValue: selected,
          displayString: _displayInvoice,
          idOf: (i) => i.id,
          onChanged: _onPick,
          emptyHintKey: _loading ? 'loading' : 'no_records_found',
        ),
        if (hasSelection && selected == null && !_loading)
          // Stored reference isn't in the loaded list (archived, beyond the
          // page cap, or a different client) — surface it as text so it's
          // not invisibly empty and one stray tap can't silently drop it.
          Padding(
            padding: EdgeInsets.only(top: InSpacing.sm),
            child: Text(
              '${context.tr('invoice')}: $storedId',
              style: TextStyle(color: tokens.ink3, fontSize: 12),
            ),
          ),
        if (hasSelection) ...[
          SizedBox(height: InSpacing.md(context)),
          InDateField(
            value: _readIssueDate()?.toDateTime(),
            formatter: widget.formatter,
            onChanged: (d) => widget.vm.setEInvoicePath(
              CreditBillingReferenceField.issueDatePath,
              d == null ? null : Date(d.year, d.month, d.day).toIso(),
            ),
            labelText: context.tr('invoice_date'),
            clearable: true,
          ),
        ],
      ],
    );
  }
}
