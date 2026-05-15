import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/ui/core/list/search/token_search_field.dart';
import 'package:admin/ui/features/recurring_invoices/view_models/recurring_invoice_list_view_model.dart';
import 'package:admin/ui/features/recurring_invoices/widgets/recurring_invoice_filter_keys.dart';

class RecurringInvoiceTokenSearchField extends StatelessWidget {
  const RecurringInvoiceTokenSearchField({
    required this.vm,
    required this.wide,
    super.key,
  });

  final RecurringInvoiceListViewModel vm;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return TokenSearchField(
      vm: vm,
      filterKeys: buildRecurringInvoiceFilterKeys(
        clients: services.clients,
        companyId: vm.companyId,
      ),
      wide: wide,
      hintKey: 'search_recurring_invoices_or_filter_hint',
    );
  }
}
