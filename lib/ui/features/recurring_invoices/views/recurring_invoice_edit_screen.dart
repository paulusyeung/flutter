import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/recurring_invoice.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/edit/edit_action_filter.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/features/recurring_invoices/view_models/recurring_invoice_edit_view_model.dart';
import 'package:admin/ui/features/recurring_invoices/widgets/edit/recurring_invoice_edit_layout.dart';
import 'package:admin/ui/features/recurring_invoices/widgets/recurring_invoice_actions.dart';

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
    return EntityEditScreenScaffold<
      RecurringInvoice,
      RecurringInvoiceEditViewModel
    >(
      existingId: existingId,
      entityTypeName: 'recurring_invoice',
      fetchExisting: (ctx, services, companyId, id) =>
          services.recurringInvoices.watch(companyId: companyId, id: id).first,
      buildVm: (ctx, services, companyId, existing) {
        return RecurringInvoiceEditViewModel(
          repo: services.recurringInvoices,
          companyId: companyId,
          clientRequiredMessage: ctx.tr('please_select_a_client'),
          crossClientLineItemsMessage: ctx.tr('cross_client_line_items'),
          existing: existing,
          cloneFrom: cloneFrom,
        );
      },
      titleWhileLoading: (ctx) =>
          existingId == null ? ctx.tr('new_recurring_invoice') : ctx.tr('edit'),
      titleBuilder: (ctx, vm) => vm.isCreate
          ? ctx.tr('new_recurring_invoice')
          : (vm.draft.number.isNotEmpty
                ? '${ctx.tr('edit')} · #${vm.draft.number}'
                : ctx.tr('edit')),
      bodyBuilder: (ctx, vm) => RecurringInvoiceEditLayout(vm: vm),
      resetToEmpty: (vm) => vm.resetToEmpty(),
      entityIdOf: (r) => r.id,
      actionsBuilder: (ctx, vm, onTap, saveButton) =>
          EntityOverflowActionBar<RecurringInvoiceAction>(
            leading: saveButton,
            items: filterForEditScreen(
              RecurringInvoiceActions.itemsFor(ctx, vm.draft, (a) => onTap(a)),
              isCreate: vm.isCreate,
              isLifecycle: RecurringInvoiceActions.isLifecycle,
            ),
          ),
      saveParamFor: (a) =>
          RecurringInvoiceActions.saveParamFor(a as RecurringInvoiceAction),
      onAfterSaveAction: (ctx, saved, a) {
        final services = ctx.read<Services>();
        return RecurringInvoiceActions.dispatch(
          ctx,
          services,
          services.auth.session.value!.currentCompanyId,
          saved,
          a as RecurringInvoiceAction,
        );
      },
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
