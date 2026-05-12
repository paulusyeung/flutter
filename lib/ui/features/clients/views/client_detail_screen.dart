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
import 'package:admin/ui/features/clients/widgets/detail/client_detail_cards_grid.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_header.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_kpi_strip.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_tabs.dart';

/// Actions surfaced in the AppBar's `…` overflow menu next to Edit.
enum ClientDetailAction { archive, restore, delete, newInvoice, merge }

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

  /// Handles `…`-menu actions in the AppBar. [c] is captured at the moment
  /// the menu opens, so a late-arriving stream update doesn't change which
  /// row gets archived/restored mid-tap.
  Future<void> _onAction(Client c, ClientDetailAction action) async {
    switch (action) {
      case ClientDetailAction.archive:
        await _services.clients.archive(companyId: _companyId, id: c.id);
        if (!mounted) return;
        Notify.success(context, context.tr('archived'));
      case ClientDetailAction.restore:
        await _services.clients.restore(companyId: _companyId, id: c.id);
        if (!mounted) return;
        Notify.success(context, context.tr('restored'));
      case ClientDetailAction.delete:
      case ClientDetailAction.newInvoice:
      case ClientDetailAction.merge:
        // Disabled in the menu UI — these branches stay for exhaustiveness
        // until the password-confirm sheet (delete) and the entities they
        // depend on (invoice / merge target picker) land.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final c = _vm.client;
        // AppBar title binds to the loaded client so the user always knows
        // which entity they're looking at. Falls back to the entity-type
        // word while the watch stream is still resolving.
        final appBarTitle = c == null
            ? context.tr('client')
            : (c.displayName.isNotEmpty
                  ? c.displayName
                  : (c.name.isNotEmpty ? c.name : context.tr('client')));
        return Scaffold(
          appBar: AppBar(
            title: Text(appBarTitle),
            actions: [
              TextButton(
                onPressed: c == null
                    ? null
                    : () => context.go('/clients/${widget.id}/edit'),
                child: Text(context.tr('edit')),
              ),
              if (c != null) _ActionMenu(client: c, onAction: _onAction),
            ],
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

class _ActionMenu extends StatelessWidget {
  const _ActionMenu({required this.client, required this.onAction});
  final Client client;
  final Future<void> Function(Client, ClientDetailAction) onAction;

  @override
  Widget build(BuildContext context) {
    final canArchive = client.archivedAt == null && !client.isDeleted;
    final canRestore = client.archivedAt != null || client.isDeleted;
    return PopupMenuButton<ClientDetailAction>(
      tooltip: context.tr('actions'),
      icon: const Icon(Icons.more_vert),
      onSelected: (action) => onAction(client, action),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: ClientDetailAction.newInvoice,
          enabled: false,
          child: _MenuItem(
            icon: Icons.receipt_long_outlined,
            label: context.tr('new_invoice'),
            subtitle: context.tr('coming_soon_subtitle'),
          ),
        ),
        const PopupMenuDivider(),
        if (canArchive)
          PopupMenuItem(
            value: ClientDetailAction.archive,
            child: _MenuItem(
              icon: Icons.archive_outlined,
              label: context.tr('archive'),
            ),
          ),
        if (canRestore)
          PopupMenuItem(
            value: ClientDetailAction.restore,
            child: _MenuItem(
              icon: Icons.unarchive_outlined,
              label: context.tr('restore'),
            ),
          ),
        PopupMenuItem(
          value: ClientDetailAction.delete,
          enabled: false,
          child: _MenuItem(
            icon: Icons.delete_outline,
            label: context.tr('delete'),
            subtitle: context.tr('coming_soon_subtitle'),
            destructive: true,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: ClientDetailAction.merge,
          enabled: false,
          child: _MenuItem(
            icon: Icons.merge_type,
            label: context.tr('merge'),
            subtitle: context.tr('coming_soon_subtitle'),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.destructive = false,
  });
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final color = destructive ? tokens.overdue : tokens.ink;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: InSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: color)),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(fontSize: 11, color: tokens.ink3),
              ),
          ],
        ),
      ],
    );
  }
}
