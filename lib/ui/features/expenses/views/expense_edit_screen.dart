import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/expense.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/edit/edit_action_filter.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/core/list/master_detail_layout.dart';
import 'package:admin/ui/features/expenses/view_models/expense_edit_view_model.dart';
import 'package:admin/ui/features/expenses/widgets/edit/expense_edit_layout.dart';
import 'package:admin/ui/features/expenses/widgets/expense_actions.dart';

/// Edit + Create form for an Expense.
///
/// Layout is delegated to [ExpenseEditLayout], which mirrors the v2 two-column
/// pattern: main column (Identity / Amount / Payment) + 360 px sidebar
/// (Notes / Invoicing / collapsibles) on widths ≥1100 px, single column
/// otherwise. The three densest sections (Currency conversion, Banking,
/// Custom fields) start collapsed per the UX spec § Progressive disclosure.
class ExpenseEditScreen extends StatelessWidget {
  const ExpenseEditScreen({
    this.existingId,
    this.cloneFrom,
    this.prefillProjectId,
    super.key,
  });

  final String? existingId;

  /// When non-null and [existingId] is null, the create form opens
  /// pre-filled with this expense's fields. Identity-bearing fields (id,
  /// number, timestamps, invoice link, payment metadata) should already
  /// be stripped by the caller.
  final Expense? cloneFrom;

  /// Optional project id seed (`?project=<id>`). In create mode the VM
  /// resolves the project and seeds the expense's projectId + clientId so
  /// "New Expense" from a Project's Expenses tab opens pre-scoped.
  final String? prefillProjectId;

  @override
  Widget build(BuildContext context) {
    return EntityEditScreenScaffold<Expense, ExpenseEditViewModel>(
      existingId: existingId,
      entityTypeName: 'expense',
      fetchExisting: (ctx, services, companyId, id) =>
          services.expenses.watch(companyId: companyId, id: id).first,
      buildVm: (ctx, services, companyId, existing) {
        final vm = ExpenseEditViewModel(
          repo: services.expenses,
          companyId: companyId,
          existing: existing,
          cloneFrom: cloneFrom,
          useCommaAsDecimalPlace:
              services
                  .formatterIfReady(companyId)
                  ?.settings
                  .useCommaAsDecimalPlace ??
              false,
          sync: services.sync,
          connectivity: services.connectivity,
        );
        // Seed project + client from `?project=<id>` on first build (create
        // mode only). Wrapped in postFrame so listeners are attached before
        // notifyListeners fires — see InvoiceEditScreen for the trace.
        final seedId = prefillProjectId;
        if (seedId != null && seedId.isNotEmpty && existing == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(
              services.projects
                  .watch(companyId: companyId, id: seedId)
                  .first
                  .then((project) {
                    if (project != null) {
                      vm.setProjectId(project.id);
                      vm.setClientId(project.clientId);
                    }
                  })
                  .catchError((Object _) {}),
            );
          });
        }
        return vm;
      },
      titleWhileLoading: (ctx) =>
          existingId == null ? ctx.tr('new_expense') : ctx.tr('edit'),
      titleBuilder: (ctx, vm) => vm.isCreate
          ? ctx.tr('new_expense')
          : (vm.draft.number.isNotEmpty
                ? '${ctx.tr('edit')} · #${vm.draft.number}'
                : ctx.tr('edit')),
      bodyBuilder: (ctx, vm) => ExpenseEditLayout(vm: vm),
      resetToEmpty: (vm) => vm.resetToEmpty(),
      entityIdOf: (e) => e.id,
      actionsBuilder: (ctx, vm, onTap, saveButton) =>
          EntityOverflowActionBar<ExpenseAction>(
            leading: saveButton,
            items: filterForEditScreen(
              ExpenseActions.itemsFor(ctx, vm.draft, (a) => onTap(a)),
              isCreate: vm.isCreate,
              isLifecycle: ExpenseActions.isLifecycle,
            ),
          ),
      onAfterSaveAction: (ctx, saved, a) {
        final services = ctx.read<Services>();
        return ExpenseActions.dispatch(
          ctx,
          services,
          services.auth.session.value!.currentCompanyId,
          saved,
          a as ExpenseAction,
        );
      },
      onSaved: (ctx, vm, saved) => goAfterEntitySave(
        ctx,
        isCreate: vm.isCreate,
        basePath: '/expenses',
        savedId: saved.id,
      ),
    );
  }
}
