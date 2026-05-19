import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/core/widgets/in_date_field.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/billing_shared/view_models/billing_doc_edit_view_model.dart';

/// Which billing-doc type owns this tab. Drives the small per-entity
/// branches: only credits show the billing-reference [leading] card, and
/// only recurring invoices serialize the period as the React-style
/// pipe-delimited `Invoice.InvoicePeriod.0.Description` string.
enum EInvoiceEntityKind { invoice, credit, recurringInvoice }

/// Reusable e-invoice (PEPPOL/UBL) edit tab, shared by invoice / credit /
/// recurring-invoice edit layouts.
///
/// `eInvoice` is an open-ended `Map<String, dynamic>` on the wire rather
/// than a typed model. This surfaces the period (start + end) + actual
/// delivery date, an optional [leading] card (credit billing reference),
/// and the document-type read-out (F1 / R1 / R2 for Verifactu — only
/// invoices carry that today via their `backup` map). The generic
/// [GenericBillingDocEditViewModel] owns `eInvoiceOf` / `setEInvoiceField`
/// / `setEInvoicePath`, so every billing-doc type works through the same
/// path with only the [entityKind] branch.
class EInvoiceFieldsTab<T> extends StatelessWidget {
  const EInvoiceFieldsTab({
    required this.vm,
    required this.entityKind,
    this.documentType,
    this.formatter,
    this.leading,
    super.key,
  });

  final GenericBillingDocEditViewModel<T> vm;

  final EInvoiceEntityKind entityKind;

  /// Optional Verifactu document-type chip (invoice-only today). Null hides
  /// the chip — credit / recurring don't carry a `backup` map.
  final String? documentType;

  /// Active company `Formatter`. Passed in from the caller (the generic VM
  /// doesn't expose `companyId`) so the period dates render/parse with the
  /// company date format instead of raw ISO. Null falls back to ISO.
  final Formatter? formatter;

  /// Optional card rendered at the top of the tab (the credit
  /// billing-reference picker). Null for invoice / recurring.
  final Widget? leading;

  /// React serializes the recurring-invoice period as a single
  /// pipe-delimited string here rather than the two flat keys
  /// invoices/credits use.
  static const _recurringPeriodPath = <Object>[
    'Invoice',
    'InvoicePeriod',
    0,
    'Description',
  ];

  Date? _readFlatDate(String key) {
    final raw = vm.eInvoiceOf(vm.draft)?[key];
    if (raw is String) return Date.tryParse(raw);
    return null;
  }

  ({Date? start, Date? end}) _readPeriod() {
    if (entityKind == EInvoiceEntityKind.recurringInvoice) {
      final desc = vm.readEInvoicePath(vm.draft, _recurringPeriodPath);
      if (desc is String && desc.isNotEmpty) {
        // The complete UBL form is "start|end"; tolerate a pipeless legacy
        // value (treat it as the start) so a single-value record still reads.
        final parts = desc.split('|');
        return (
          start: Date.tryParse(parts[0]),
          end: parts.length > 1 ? Date.tryParse(parts[1]) : null,
        );
      }
      // Partial entry (only one date so far) is buffered in the flat keys —
      // and so are legacy records saved before this reconcile. Fall through.
    }
    return (
      start: _readFlatDate('invoice_period_start'),
      end: _readFlatDate('invoice_period_end'),
    );
  }

  void _commitPeriod(Date? start, Date? end) {
    if (entityKind == EInvoiceEntityKind.recurringInvoice) {
      if (start != null && end != null) {
        // Complete: emit the canonical UBL string, drop the flat buffer so
        // we never ship both encodings.
        vm.setEInvoicePath(
          _recurringPeriodPath,
          '${start.toIso()}|${end.toIso()}',
        );
        vm.setEInvoiceField('invoice_period_start', null);
        vm.setEInvoiceField('invoice_period_end', null);
      } else {
        // Partial: keep the half-entered value in the flat keys so it
        // survives the rebuild; clear any stale Description.
        vm.setEInvoicePath(_recurringPeriodPath, null);
        vm.setEInvoiceField('invoice_period_start', start?.toIso());
        vm.setEInvoiceField('invoice_period_end', end?.toIso());
      }
      return;
    }
    vm.setEInvoiceField('invoice_period_start', start?.toIso());
    vm.setEInvoiceField('invoice_period_end', end?.toIso());
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final docType = documentType;
    return ListView(
      padding: EdgeInsets.all(InSpacing.lg(context)),
      children: [
        if (docType != null && docType.isNotEmpty)
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
                Icon(Icons.qr_code_2_outlined, size: 18, color: tokens.ink3),
                const SizedBox(width: 8),
                Text(
                  context.tr('document_type'),
                  style: TextStyle(color: tokens.ink3, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  docType,
                  style: TextStyle(
                    color: tokens.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        if (leading != null) ...[
          leading!,
          SizedBox(height: InSpacing.lg(context)),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final period = _readPeriod();
            final start = InDateField(
              value: period.start?.toDateTime(),
              formatter: formatter,
              onChanged: (d) => _commitPeriod(
                d == null ? null : Date(d.year, d.month, d.day),
                _readPeriod().end,
              ),
              labelText: context.tr('invoice_period_start'),
              clearable: true,
            );
            final end = InDateField(
              value: period.end?.toDateTime(),
              formatter: formatter,
              onChanged: (d) => _commitPeriod(
                _readPeriod().start,
                d == null ? null : Date(d.year, d.month, d.day),
              ),
              labelText: context.tr('invoice_period_end'),
              clearable: true,
            );
            if (Breakpoints.isWide(constraints)) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: start),
                  SizedBox(width: InSpacing.md(context)),
                  Expanded(child: end),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                start,
                SizedBox(height: InSpacing.md(context)),
                end,
              ],
            );
          },
        ),
        SizedBox(height: InSpacing.md(context)),
        InDateField(
          value: _readFlatDate('actual_delivery_date')?.toDateTime(),
          formatter: formatter,
          onChanged: (d) => vm.setEInvoiceField(
            'actual_delivery_date',
            d == null ? null : Date(d.year, d.month, d.day).toIso(),
          ),
          labelText: context.tr('actual_delivery_date'),
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
