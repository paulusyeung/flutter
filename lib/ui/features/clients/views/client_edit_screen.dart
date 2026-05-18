import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/edit/edit_action_filter.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/features/clients/view_models/client_edit_view_model.dart';
import 'package:admin/ui/features/clients/widgets/client_actions.dart';
import 'package:admin/ui/features/clients/widgets/edit/client_edit_layout.dart';

/// Edit + Create form for a Client. The outer scaffold owns VM lifecycle,
/// the loading-state Scaffold, dead-outbox-row 422 recovery, and post-save
/// cleanup. This widget only contributes the per-entity wiring: how to
/// fetch the existing row, how to build the VM, the title, and the form
/// body.
class ClientEditScreen extends StatelessWidget {
  const ClientEditScreen({this.existingId, this.cloneFrom, super.key});

  final String? existingId;

  /// When non-null and [existingId] is null, the create form opens
  /// pre-filled with this client's fields. Identity-bearing fields (id,
  /// number, balances, timestamps, contact ids) are stripped by the
  /// caller before navigating.
  final Client? cloneFrom;

  @override
  Widget build(BuildContext context) {
    return EntityEditScreenScaffold<Client, ClientEditViewModel>(
      existingId: existingId,
      entityTypeName: 'client',
      fetchExisting: (ctx, services, companyId, id) =>
          services.clients.watch(companyId: companyId, id: id).first,
      buildVm: (ctx, services, companyId, existing) => ClientEditViewModel(
        repo: services.clients,
        companyId: companyId,
        existing: existing,
        cloneFrom: cloneFrom,
      ),
      titleWhileLoading: (ctx) =>
          existingId == null ? ctx.tr('new_client') : ctx.tr('edit'),
      titleBuilder: (ctx, vm) {
        if (vm.isCreate) return ctx.tr('new_client');
        final displayName = vm.draft.displayName.isNotEmpty
            ? vm.draft.displayName
            : vm.draft.name;
        return displayName.isNotEmpty
            ? '${ctx.tr('edit')} · $displayName'
            : ctx.tr('edit');
      },
      bodyBuilder: (ctx, vm) => ClientEditLayout(vm: vm),
      resetToEmpty: (vm) => vm.resetToEmpty(),
      entityIdOf: (c) => c.id,
      actionsBuilder: (ctx, vm, onTap, saveButton) =>
          EntityOverflowActionBar<ClientAction>(
            leading: saveButton,
            items: filterForEditScreen(
              ClientActions.itemsFor(ctx, vm.draft, (a) => onTap(a)),
              isCreate: vm.isCreate,
              isLifecycle: ClientActions.isLifecycle,
            ),
          ),
      onAfterSaveAction: (ctx, saved, a) {
        final services = ctx.read<Services>();
        return ClientActions.dispatch(
          ctx,
          services,
          services.auth.session.value!.currentCompanyId,
          saved,
          a as ClientAction,
        );
      },
      onSaved: (ctx, vm, saved) {
        if (vm.isCreate) {
          ctx.go('/clients/${saved.id}');
        } else {
          ctx.pop();
        }
      },
    );
  }
}
