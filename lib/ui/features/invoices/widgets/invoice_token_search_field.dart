import 'package:flutter/material.dart';

import 'package:admin/ui/core/list/search/token_search_field.dart';
import 'package:admin/ui/features/invoices/view_models/invoice_list_view_model.dart';
import 'package:admin/ui/features/invoices/widgets/invoice_filter_keys.dart';

/// Thin wrapper that wires [TokenSearchField] for the invoices list.
class InvoiceTokenSearchField extends StatelessWidget {
  const InvoiceTokenSearchField({
    required this.vm,
    required this.wide,
    super.key,
  });

  final InvoiceListViewModel vm;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return TokenSearchField(
      vm: vm,
      filterKeys: buildInvoiceFilterKeys(),
      wide: wide,
      hintKey: 'search_invoices_or_filter_hint',
    );
  }
}
