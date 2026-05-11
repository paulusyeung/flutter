import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/models/domain/contact.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/features/clients/view_models/client_detail_view_model.dart';

class ClientDetailScreen extends StatefulWidget {
  const ClientDetailScreen({required this.id, super.key});
  final String id;

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  late final ClientDetailViewModel _vm;

  @override
  void initState() {
    super.initState();
    final services = context.read<Services>();
    _vm = ClientDetailViewModel(
      repo: services.clients,
      companyId: services.auth.session.value!.currentCompanyId,
      id: widget.id,
    );
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('client')),
        actions: [
          IconButton(
            tooltip: context.tr('edit'),
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.go('/clients/${widget.id}/edit'),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final c = _vm.client;
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
          return _ClientBody(client: c);
        },
      ),
    );
  }
}

class _ClientBody extends StatelessWidget {
  const _ClientBody({required this.client});
  final Client client;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final noName = context.tr('no_name_fallback');
    final displayName = client.displayName.isNotEmpty
        ? client.displayName
        : (client.name.isNotEmpty ? client.name : noName);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(radius: 28, child: Text(_initials(displayName))),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: theme.textTheme.headlineSmall),
                  if (client.number.isNotEmpty)
                    Text(
                      client.number,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                ],
              ),
            ),
            if (client.isDirty)
              Chip(
                label: Text(context.tr('unsynced')),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
          ],
        ),
        const SizedBox(height: 24),
        _Section(
          title: context.tr('financial'),
          rows: [
            (context.tr('balance'), client.balance.toString()),
            (context.tr('paid_to_date'), client.paidToDate.toString()),
            (context.tr('credit_balance'), client.creditBalance.toString()),
          ],
        ),
        _Section(
          title: context.tr('contact'),
          rows: [
            if (client.website.isNotEmpty)
              (context.tr('website'), client.website),
            if (client.phone.isNotEmpty) (context.tr('phone'), client.phone),
            if (client.vatNumber.isNotEmpty)
              (context.tr('vat_number'), client.vatNumber),
            if (client.idNumber.isNotEmpty)
              (context.tr('id_number'), client.idNumber),
          ],
        ),
        _Section(
          title: context.tr('address'),
          rows: [
            if (client.address1.isNotEmpty)
              (context.tr('address1'), client.address1),
            if (client.address2.isNotEmpty)
              (context.tr('address2'), client.address2),
            if (client.city.isNotEmpty) (context.tr('city'), client.city),
            if (client.state.isNotEmpty) (context.tr('state'), client.state),
            if (client.postalCode.isNotEmpty)
              (context.tr('postal_code'), client.postalCode),
            if (client.countryId.isNotEmpty)
              (context.tr('country'), client.countryId),
          ],
        ),
        if (client.contacts.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            context.tr('contacts_with_count', {
              'count': client.contacts.length.toString(),
            }),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final contact in client.contacts) _ContactTile(contact: contact),
        ],
        if (client.privateNotes.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            context.tr('private_notes'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(client.privateNotes),
        ],
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});
  final String title;
  final List<(String label, String value)> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      row.$1,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                  Expanded(child: Text(row.$2)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.contact});
  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final fullName = '${contact.firstName} ${contact.lastName}'.trim();
    final title = fullName.isEmpty ? context.tr('no_name_fallback') : fullName;
    final subtitle = [
      if (contact.email.isNotEmpty) contact.email,
      if (contact.phone.isNotEmpty) contact.phone,
    ].join(' · ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Expanded(child: Text(title)),
          if (contact.isPrimary)
            Chip(
              label: Text(context.tr('primary')),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
        ],
      ),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
    );
  }
}
