import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/data/models/domain/recurring_invoice.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/features/recurring_invoices/view_models/recurring_invoice_edit_view_model.dart';
import 'package:admin/ui/features/recurring_invoices/widgets/edit/recurring_invoice_edit_layout.dart';

class RecurringInvoiceEditScreen extends StatelessWidget {
  const RecurringInvoiceEditScreen({
    this.existingId,
    this.cloneFrom,
    super.key,
  });

  final String? existingId;
  final RecurringInvoice? cloneFrom;

  @override
  Widget build(BuildContext context) {
    return EntityEditScreenScaffold<RecurringInvoice,
        RecurringInvoiceEditViewModel>(
      existingId: existingId,
      entityTypeName: 'recurring_invoice',
      fetchExisting: (ctx, services, companyId, id) =>
          services.recurringInvoices.watch(companyId: companyId, id: id).first,
      buildVm: (ctx, services, companyId, existing) {
        return RecurringInvoiceEditViewModel(
          repo: services.recurringInvoices,
          companyId: companyId,
          existing: existing,
          cloneFrom: cloneFrom,
        );
      },
      titleWhileLoading: (ctx) => existingId == null
          ? ctx.tr('new_recurring_invoice')
          : ctx.tr('edit'),
      titleBuilder: (ctx, vm) => vm.isCreate
          ? ctx.tr('new_recurring_invoice')
          : (vm.draft.number.isNotEmpty
              ? '${ctx.tr('edit')} · #${vm.draft.number}'
              : ctx.tr('edit')),
      bodyBuilder: (ctx, vm) => RecurringInvoiceEditLayout(vm: vm),
      resetToEmpty: (vm) => vm.resetToEmpty(),
      entityIdOf: (r) => r.id,
      onSaved: (ctx, vm, saved) {
        if (vm.isCreate) {
          ctx.go('/recurring_invoices/${saved.id}');
        } else {
          ctx.pop();
        }
      },
    );
  }
}
