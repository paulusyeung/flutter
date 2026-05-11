import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/features/clients/view_models/client_detail_view_model.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_cards_grid.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_header.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_notes_card.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_tabs.dart';
import 'package:admin/utils/formatting.dart';

class ClientDetailScreen extends StatefulWidget {
  const ClientDetailScreen({required this.id, super.key});
  final String id;

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  late final ClientDetailViewModel _vm;
  late final Services _services;
  late final String _companyId;

  /// Built once in `initState`. Money fields render as `—` while the future
  /// is in flight (same pattern as `client_list_screen.dart`).
  Formatter? _formatter;

  /// Above this width the detail layout shows the tabs section taller and
  /// the cards in a single row. Mirrors the breakpoint logic in
  /// `client_detail_cards_grid.dart` (which has its own LayoutBuilder).
  static const double _wideBreakpoint = 900;

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
    _loadFormatter();
  }

  void _loadFormatter() {
    final loadingFor = _companyId;
    _services.formatterFor(loadingFor).then((f) {
      if (!mounted || loadingFor != _companyId) return;
      setState(() => _formatter = f);
    });
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
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
              IconButton(
                tooltip: context.tr('edit'),
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.go('/clients/${widget.id}/edit'),
              ),
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
              return LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= _wideBreakpoint;
                  final hasNotes = c.privateNotes.isNotEmpty ||
                      c.publicNotes.isNotEmpty;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(InSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClientDetailHeader(client: c),
                        const SizedBox(height: InSpacing.xl),
                        ClientDetailCardsGrid(
                          client: c,
                          formatter: _formatter,
                        ),
                        if (hasNotes) ...[
                          const SizedBox(height: InSpacing.md),
                          ClientDetailNotesCard(client: c),
                        ],
                        const SizedBox(height: InSpacing.xl),
                        SizedBox(
                          height: wide ? 480 : 360,
                          child: const ClientDetailTabs(),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
