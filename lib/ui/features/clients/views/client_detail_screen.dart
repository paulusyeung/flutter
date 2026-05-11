import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/services.dart';
import '../../../../data/models/domain/client.dart';
import '../../../../data/models/domain/contact.dart';
import '../../../core/widgets/empty_state.dart';
import '../view_models/client_detail_view_model.dart';

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
      appBar: AppBar(title: const Text('Client')),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final c = _vm.client;
          if (c == null && _vm.isResolving) {
            return const Center(child: CircularProgressIndicator());
          }
          if (c == null) {
            return const EmptyState(
              icon: Icons.person_off_outlined,
              title: 'Client not found',
              subtitle: 'It may have been deleted or you may not have access.',
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
    final displayName = client.displayName.isNotEmpty
        ? client.displayName
        : (client.name.isNotEmpty ? client.name : '(no name)');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(_initials(displayName)),
            ),
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
                label: const Text('Unsynced'),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
          ],
        ),
        const SizedBox(height: 24),
        _Section(
          title: 'Financial',
          rows: [
            ('Balance', client.balance.toString()),
            ('Paid to date', client.paidToDate.toString()),
            ('Credit balance', client.creditBalance.toString()),
          ],
        ),
        _Section(
          title: 'Contact',
          rows: [
            if (client.website.isNotEmpty) ('Website', client.website),
            if (client.phone.isNotEmpty) ('Phone', client.phone),
            if (client.vatNumber.isNotEmpty) ('VAT', client.vatNumber),
            if (client.idNumber.isNotEmpty) ('ID', client.idNumber),
          ],
        ),
        _Section(
          title: 'Address',
          rows: [
            if (client.address1.isNotEmpty) ('Address 1', client.address1),
            if (client.address2.isNotEmpty) ('Address 2', client.address2),
            if (client.city.isNotEmpty) ('City', client.city),
            if (client.state.isNotEmpty) ('State', client.state),
            if (client.postalCode.isNotEmpty)
              ('Postal code', client.postalCode),
            if (client.countryId.isNotEmpty) ('Country', client.countryId),
          ],
        ),
        if (client.contacts.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Contacts (${client.contacts.length})',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final contact in client.contacts) _ContactTile(contact: contact),
        ],
        if (client.privateNotes.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Private notes', style: theme.textTheme.titleMedium),
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
    final title = fullName.isEmpty ? '(no name)' : fullName;
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
              label: const Text('Primary'),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
        ],
      ),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
    );
  }
}
