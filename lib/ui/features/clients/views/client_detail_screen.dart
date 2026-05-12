import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/core/widgets/formatter_host_mixin.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/clients/view_models/client_detail_view_model.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_actions_row.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_cards_grid.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_header.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_kpi_strip.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_tabs.dart';

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
      case ClientAction.archive:
        await _services.clients.archive(companyId: _companyId, id: c.id);
        if (!mounted) return;
        Notify.success(context, context.tr('archived'));
      case ClientAction.restore:
        await _services.clients.restore(companyId: _companyId, id: c.id);
        if (!mounted) return;
        Notify.success(context, context.tr('restored'));
      case ClientAction.viewStatement:
      case ClientAction.clientPortal:
      case ClientAction.settings:
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
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final c = _vm.client;
        return Scaffold(
          appBar: AppBar(
            titleSpacing: InSpacing.md,
            title: c == null
                ? null
                : ClientDetailActionsRow(
                    client: c,
                    onAction: (a) => _onAction(c, a),
                  ),
          ),
          body: Builder(
            builder: (context) {
              if (c == null && _vm.isResolving) {
                return const Center(child: CircularProgressIndicator());
              }
              if (c == null) {
                return EmptyState(
                  icon: Icons.person_off_outlined,
                  title: context.tr('client_not_found'),
                  subtitle: context.tr('client_not_found_subtitle'),
                );
              }
              return SingleChildScrollView(
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
              );
            },
          ),
        );
      },
    );
  }
}
