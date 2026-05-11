import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/clients/view_models/client_edit_view_model.dart';
import 'package:admin/ui/features/clients/widgets/edit/client_edit_layout.dart';

/// Edit + Create form for a Client.
///
/// When [existingId] is null the screen is in "create" mode and navigates to
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
        builder: (context, _) {
          // Create mode requires a name before saving — Save mints a tmp_ id
          // and queues an outbox row, and an unnamed client is rarely intended.
          // Edit mode just requires `isDirty` so we don't round-trip a clean
          // form through the outbox.
          final canSave = !vm.isSaving &&
              (vm.isCreate
                  ? vm.draft.name.trim().isNotEmpty
                  : vm.isDirty);
          final displayName = vm.draft.displayName.isNotEmpty
              ? vm.draft.displayName
              : vm.draft.name;
          final title = vm.isCreate
              ? context.tr('new_client')
              : (displayName.isNotEmpty
                  ? '${context.tr('edit')} · $displayName'
                  : context.tr('edit'));
          return Scaffold(
            appBar: AppBar(
              title: Text(title),
              actions: [
                TextButton(
                  onPressed: canSave ? _onSave : null,
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
            body: ClientEditLayout(vm: vm),
          );
        },
      ),
    );
  }
}
