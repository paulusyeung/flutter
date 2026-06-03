import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/recurring_invoice.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/edit/after_save_create_action.dart';
import 'package:admin/ui/core/edit/edit_action_filter.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/core/list/master_detail_layout.dart';
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
          sync: services.sync,
          connectivity: services.connectivity,
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
      // Create-mode: resolve the tmp id to the real one so navigating actions
      // (Send Email, View PDF) keep their navigation instead of the redirect.
      onAfterSaveActionOnCreate: (ctx, saved, a) {
        final services = ctx.read<Services>();
        final companyId = services.auth.session.value!.currentCompanyId;
        return dispatchAfterSaveOnCreate<
          RecurringInvoice,
          RecurringInvoiceAction
        >(
          ctx,
          saved: saved,
          idOf: (r) => r.id,
          withId: (r, id) => r.copyWith(id: id),
          resolveId: services.recurringInvoices.resolveId,
          action: a as RecurringInvoiceAction,
          navigatesOnCreate: RecurringInvoiceActions.navigatesOnCreate,
          dispatch: (c, resolved, act) => RecurringInvoiceActions.dispatch(
            c,
            services,
            companyId,
            resolved,
            act,
          ),
        );
      },
      onSaved: (ctx, vm, saved) => goAfterEntitySave(
        ctx,
        isCreate: vm.isCreate,
        basePath: '/recurring_invoices',
        savedId: saved.id,
      ),
    );
  }
}
