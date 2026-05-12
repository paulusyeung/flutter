import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_scaffold.dart';
import 'package:admin/ui/core/widgets/formatter_host_mixin.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/clients/view_models/client_detail_view_model.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_actions_row.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_cards_grid.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_header.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_kpi_strip.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_tabs.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';

class ClientDetailScreen extends StatefulWidget {
  const ClientDetailScreen({required this.id, super.key});
  final String id;

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen>
    with FormatterHostMixin {
  late final ClientDetailViewModel _vm;
  late final Services _services;
  late final String _companyId;

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    _companyId = _services.auth.session.value!.currentCompanyId;
    _vm = ClientDetailViewModel(
      repo: _services.clients,
      companyId: _companyId,
      id: widget.id,
    );
    loadFormatter(_services, _companyId);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  /// Dispatches an action selected from `ClientDetailActionsRow`. [c] is
  /// captured at the moment the button is tapped, so a late-arriving stream
  /// update can't change which row gets archived/restored mid-action.
  Future<void> _onAction(Client c, ClientAction action) async {
    switch (action) {
      case ClientAction.edit:
        context.go('/clients/${c.id}/edit');
      case ClientAction.viewStatement:
        // A `tmp_` client lives only in the local outbox — the server doesn't
        // know it yet, so a statement POST would 404. Tell the user to sync.
        if (c.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        // Statement generation is server-only — no point opening the screen
        // just to render a network error. Gate at the action site.
        final online = await _services.connectivity.isOnline;
        if (!mounted) return;
        if (!online) {
          Notify.error(context, context.tr('statement_offline'));
          return;
        }
        // Push (not go) so the back arrow returns to the detail screen.
        await context.push('/clients/${c.id}/statement');
      case ClientAction.archive:
        await _services.clients.archive(companyId: _companyId, id: c.id);
        if (!mounted) return;
        Notify.success(context, context.tr('archived'));
      case ClientAction.restore:
        await _services.clients.restore(companyId: _companyId, id: c.id);
        if (!mounted) return;
        Notify.success(context, context.tr('restored'));
      case ClientAction.settings:
        if (c.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        _services.settingsLevel.setLevel(
          SettingsLevel.client,
          targetId: c.id,
          targetName: c.displayName,
        );
        // Localization mirrors admin-portal's default landing for client
        // scope and is the first non-company-only entry in the filtered
        // sidebar — picking it explicitly keeps the two heuristics in
        // agreement.
        context.go('/settings/localization');
      case ClientAction.assignGroup:
      case ClientAction.addComment:
      case ClientAction.newInvoice:
      case ClientAction.newQuote:
      case ClientAction.newPayment:
      case ClientAction.newTask:
      case ClientAction.newExpense:
      case ClientAction.merge:
      case ClientAction.delete:
      case ClientAction.purge:
        // Buttons render disabled — branches kept so the enum stays
        // exhaustive and future wiring is grep-able.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return EntityDetailScaffold<Client>(
      vm: _vm,
      emptyIcon: Icons.person_off_outlined,
      emptyTitle: context.tr('client_not_found'),
      emptySubtitle: context.tr('client_not_found_subtitle'),
      actionsForItem: (context, c) =>
          ClientDetailActionsRow(client: c, onAction: (a) => _onAction(c, a)),
      bodyBuilder: (context, c) => SingleChildScrollView(
        padding: const EdgeInsets.all(InSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClientDetailHeader(client: c, formatter: formatter),
            const SizedBox(height: InSpacing.xl),
            ClientDetailKpiStrip(client: c, formatter: formatter),
            const SizedBox(height: InSpacing.lg),
            ClientDetailCardsGrid(client: c, formatter: formatter),
            const SizedBox(height: InSpacing.xl),
            const ClientDetailTabs(),
          ],
        ),
      ),
    );
  }
}
