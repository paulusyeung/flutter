import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/clients/view_models/client_edit_view_model.dart';

/// Edit + Create form for a Client.
///
/// When [existingId] is null the screen is in "create" mode and pops back to
/// the new client's detail screen on save. Otherwise it loads the existing
/// client via `repo.watch(id)` and pops back to that detail screen.
class ClientEditScreen extends StatefulWidget {
  const ClientEditScreen({this.existingId, super.key});
  final String? existingId;

  @override
  State<ClientEditScreen> createState() => _ClientEditScreenState();
}

class _ClientEditScreenState extends State<ClientEditScreen> {
  ClientEditViewModel? _vm;
  bool _loadedExisting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingId == null) {
      // Create: VM is ready immediately.
      _vm = ClientEditViewModel(
        repo: context.read<Services>().clients,
        companyId: context
            .read<Services>()
            .auth
            .session
            .value!
            .currentCompanyId,
      );
      _loadedExisting = true;
    } else {
      // Edit: pull the existing row, then construct the VM. We use `first`
      // so the form initializes with the most recent local state, then the
      // VM holds the draft independently.
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    final services = context.read<Services>();
    final companyId = services.auth.session.value!.currentCompanyId;
    final existing = await services.clients
        .watch(companyId: companyId, id: widget.existingId!)
        .first;
    if (!mounted) return;
    setState(() {
      _vm = ClientEditViewModel(
        repo: services.clients,
        companyId: companyId,
        existing: existing,
      );
      _loadedExisting = true;
    });
  }

  @override
  void dispose() {
    _vm?.dispose();
    super.dispose();
  }

  Future<bool> _confirmDiscard() async {
    final vm = _vm;
    if (vm == null || !vm.isDirty) return true;
    if (!mounted) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('discard_changes_question')),
        content: Text(ctx.tr('discard_changes_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.tr('keep_editing')),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.tr('discard')),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _onSave() async {
    final vm = _vm!;
    final result = await vm.save();
    if (!mounted) return;
    if (result == null) {
      if (vm.submitError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr('could_not_save_with_error', {
                'error': vm.submitError!,
              }),
            ),
          ),
        );
      }
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr('saved'))));
    if (vm.isCreate) {
      // Navigate to the new client's detail screen (its tmp id will be
      // remapped transparently once sync lands).
      context.go('/clients/${result.id}');
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loadedExisting || _vm == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.existingId == null
                ? context.tr('new_client')
                : context.tr('edit'),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final vm = _vm!;
    return PopScope(
      canPop: !vm.isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscard();
        if (!shouldPop) return;
        if (!context.mounted) return;
        context.pop();
      },
      child: ListenableBuilder(
        listenable: vm,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            title: Text(
              vm.isCreate ? context.tr('new_client') : context.tr('edit'),
            ),
            actions: [
              TextButton(
                onPressed: vm.isSaving ? null : _onSave,
                child: vm.isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.tr('save')),
              ),
            ],
          ),
          body: _Form(vm: vm),
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.vm});
  final ClientEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final draft = vm.draft;
    final theme = Theme.of(context);
    final primary = draft.contacts.where((c) => c.isPrimary).toList();
    final pc = primary.isNotEmpty
        ? primary.first
        : (draft.contacts.isNotEmpty ? draft.contacts.first : null);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(context.tr('identity'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _Field(
          label: context.tr('name'),
          initial: draft.name,
          onChanged: vm.setName,
          autofocus: vm.isCreate,
        ),
        _Field(
          label: context.tr('number'),
          initial: draft.number,
          onChanged: vm.setNumber,
        ),
        _Field(
          label: context.tr('id_number'),
          initial: draft.idNumber,
          onChanged: vm.setIdNumber,
        ),
        _Field(
          label: context.tr('vat_number'),
          initial: draft.vatNumber,
          onChanged: vm.setVatNumber,
        ),
        const SizedBox(height: 16),
        Text(context.tr('contact'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _Field(
          label: context.tr('website'),
          initial: draft.website,
          onChanged: vm.setWebsite,
        ),
        _Field(
          label: context.tr('phone'),
          initial: draft.phone,
          onChanged: vm.setPhone,
        ),
        const SizedBox(height: 16),
        Text(
          context.tr('primary_contact'),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _Field(
          label: context.tr('first_name'),
          initial: pc?.firstName ?? '',
          onChanged: vm.setPrimaryContactFirstName,
        ),
        _Field(
          label: context.tr('last_name'),
          initial: pc?.lastName ?? '',
          onChanged: vm.setPrimaryContactLastName,
        ),
        _Field(
          label: context.tr('email'),
          initial: pc?.email ?? '',
          onChanged: vm.setPrimaryContactEmail,
        ),
        _Field(
          label: context.tr('phone'),
          initial: pc?.phone ?? '',
          onChanged: vm.setPrimaryContactPhone,
        ),
        const SizedBox(height: 16),
        Text(context.tr('address'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _Field(
          label: context.tr('address1'),
          initial: draft.address1,
          onChanged: vm.setAddress1,
        ),
        _Field(
          label: context.tr('address2'),
          initial: draft.address2,
          onChanged: vm.setAddress2,
        ),
        _Field(
          label: context.tr('city'),
          initial: draft.city,
          onChanged: vm.setCity,
        ),
        _Field(
          label: context.tr('state'),
          initial: draft.state,
          onChanged: vm.setState,
        ),
        _Field(
          label: context.tr('postal_code'),
          initial: draft.postalCode,
          onChanged: vm.setPostalCode,
        ),
        _Field(
          label: context.tr('country'),
          initial: draft.countryId,
          onChanged: vm.setCountryId,
        ),
        const SizedBox(height: 16),
        Text(context.tr('notes'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _Field(
          label: context.tr('private_notes'),
          initial: draft.privateNotes,
          onChanged: vm.setPrivateNotes,
          maxLines: 3,
        ),
        _Field(
          label: context.tr('public_notes'),
          initial: draft.publicNotes,
          onChanged: vm.setPublicNotes,
          maxLines: 3,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _Field extends StatefulWidget {
  const _Field({
    required this.label,
    required this.initial,
    required this.onChanged,
    this.maxLines = 1,
    this.autofocus = false,
  });

  final String label;
  final String initial;
  final ValueChanged<String> onChanged;
  final int maxLines;
  final bool autofocus;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(labelText: widget.label),
        maxLines: widget.maxLines,
        autofocus: widget.autofocus,
        onChanged: widget.onChanged,
      ),
    );
  }
}
