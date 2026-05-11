import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/services.dart';
import '../../../../data/models/domain/client.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../view_models/client_list_view_model.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  late final ClientListViewModel _vm;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    final services = context.read<Services>();
    final session = services.auth.session.value;
    _vm = ClientListViewModel(
      repo: services.clients,
      // A null session here means the router failed its redirect — but the
      // screen is built lazily, so by the time we reach here the session
      // value is always set. Bang-asserting matches that invariant.
      companyId: session!.currentCompanyId,
    );
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 600) {
      _vm.loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: 'New client',
        onPressed: () => context.go('/clients/new'),
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: const Text('Clients'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search clients',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 12,
                ),
              ),
              onChanged: _vm.setSearch,
            ),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) => _body(),
      ),
    );
  }

  Widget _body() {
    if (_vm.initialError != null && _vm.clients.isEmpty) {
      return ErrorView(message: _vm.initialError!, onRetry: _vm.retryInitial);
    }
    if (_vm.clients.isEmpty && !_vm.isLoadingPage) {
      return RefreshIndicator(
        onRefresh: _vm.refresh,
        child: ListView(
          // RefreshIndicator needs a scrollable child; a single sliver-free
          // ListView with one centered tile gives the empty state without
          // breaking pull-to-refresh.
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: const EmptyState(
                icon: Icons.people_outline,
                title: 'No clients yet',
                subtitle: 'Create your first client in M1.10b — coming soon.',
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _vm.refresh,
      child: ListView.builder(
        controller: _scroll,
        itemCount: _vm.clients.length + 1, // + 1 for the footer
        itemBuilder: (context, index) {
          if (index >= _vm.clients.length) return _footer();
          final c = _vm.clients[index];
          return _ClientRow(
            client: c,
            onTap: () => context.go('/clients/${c.id}'),
          );
        },
      ),
    );
  }

  Widget _footer() {
    if (_vm.isLoadingPage) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (!_vm.hasMore && _vm.clients.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'End of list',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _ClientRow extends StatelessWidget {
  const _ClientRow({required this.client, required this.onTap});
  final Client client;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = client.displayName.isNotEmpty
        ? client.displayName
        : (client.name.isNotEmpty ? client.name : '(no name)');
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(child: Text(_initials(displayName))),
      title: Row(
        children: [
          Expanded(child: Text(displayName, overflow: TextOverflow.ellipsis)),
          if (client.isDirty)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Chip(
                label: Text('Unsynced', style: theme.textTheme.labelSmall),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
      subtitle: client.number.isNotEmpty ? Text(client.number) : null,
      trailing: Text(client.balance.toString()),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
