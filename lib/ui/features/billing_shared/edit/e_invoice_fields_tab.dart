import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/core/widgets/in_date_field.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/billing_shared/view_models/billing_doc_edit_view_model.dart';

/// Reusable e-invoice (PEPPOL/UBL) edit tab, shared by invoice / credit /
/// recurring-invoice edit layouts.
///
/// `eInvoice` is an open-ended `Map<String, dynamic>` on the wire rather
/// than a typed model. This surfaces the two fields most commonly edited
/// (invoice period start + end) and, when the caller passes one, the
/// document-type read-out (F1 / R1 / R2 for Verifactu — only invoices
/// carry that today via their `backup` map). The generic
/// [GenericBillingDocEditViewModel] already owns `eInvoiceOf` + `setEInvoiceField`,
/// so every billing-doc type works through the same path with no
/// per-entity code.
class EInvoiceFieldsTab<T> extends StatelessWidget {
  const EInvoiceFieldsTab({
    required this.vm,
    this.documentType,
    this.formatter,
    super.key,
  });

  final GenericBillingDocEditViewModel<T> vm;

  /// Optional Verifactu document-type chip (invoice-only today). Null hides
  /// the chip — credit / recurring don't carry a `backup` map.
  final String? documentType;

  /// Active company `Formatter`. Passed in from the caller (the generic VM
  /// doesn't expose `companyId`) so the period dates render/parse with the
  /// company date format instead of raw ISO. Null falls back to ISO.
  final Formatter? formatter;

  Date? _readDate(String key) {
    final raw = vm.eInvoiceOf(vm.draft)?[key];
    if (raw is String) return Date.tryParse(raw);
    return null;
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
        LayoutBuilder(
          builder: (context, constraints) {
            final start = InDateField(
              value: _readDate('invoice_period_start')?.toDateTime(),
              formatter: formatter,
              onChanged: (d) => vm.setEInvoiceField(
                'invoice_period_start',
                d == null ? null : Date(d.year, d.month, d.day).toIso(),
              ),
              labelText: context.tr('invoice_period_start'),
              clearable: true,
            );
            final end = InDateField(
              value: _readDate('invoice_period_end')?.toDateTime(),
              formatter: formatter,
              onChanged: (d) => vm.setEInvoiceField(
                'invoice_period_end',
                d == null ? null : Date(d.year, d.month, d.day).toIso(),
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
        SizedBox(height: InSpacing.lg(context)),
        Text(
          context.tr('einvoice_help'),
          style: TextStyle(color: tokens.ink3, fontSize: 12),
        ),
      ],
    );
  }
}
