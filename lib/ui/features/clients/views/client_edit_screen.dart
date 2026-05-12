import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_edit_scaffold.dart';
import 'package:admin/ui/core/widgets/save_failed_banner.dart';
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
    await _loadFailedSyncErrors(services, companyId, widget.existingId!);
  }

  /// Hydrate the VM with field errors from a prior 422 so the form opens
  /// pre-flagged. Reads the dead outbox row for this entity (if any) and
  /// pushes its `field_errors_json` onto the VM. No-op when no dead row.
  Future<void> _loadFailedSyncErrors(
    Services services,
    String companyId,
    String entityId,
  ) async {
    final row = await services.db.outboxDao.findDeadForEntity(
      companyId: companyId,
      entityType: 'client',
      entityId: entityId,
    );
    if (row == null || _vm == null || !mounted) return;
    final raw = row.fieldErrorsJson;
    if (raw == null || raw.isEmpty) return;
    Map<String, List<String>> errors;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      errors = decoded.map(
        (k, v) => MapEntry(
          k,
          (v as List).map((e) => e.toString()).toList(growable: false),
        ),
      );
    } catch (_) {
      return;
    }
    if (errors.isEmpty) return;
    _vm!.applyFailedSync(rowId: row.id, errors: errors);
  }

  /// Resolve the dead outbox row id for the current entity. Reuses the VM's
  /// cached id when present; falls back to a dao lookup otherwise. Used by
  /// the form-level Discard action and the onSaved cleanup — both need to
  /// delete the right row even when the VM never had a chance to load its
  /// id (e.g. a 422 that landed after the form opened).
  Future<int?> _resolveDeadRowId(
    Services services,
    ClientEditViewModel vm,
  ) async {
    final cached = vm.deadOutboxRowId;
    if (cached != null) return cached;
    final entityId = widget.existingId;
    if (entityId == null) return null;
    final row = await services.db.outboxDao.findDeadForEntity(
      companyId: vm.companyId,
      entityType: 'client',
      entityId: entityId,
    );
    return row?.id;
  }

  @override
  void dispose() {
    _vm?.dispose();
    super.dispose();
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
    // Create mode requires a name before saving — Save mints a tmp_ id
    // and queues an outbox row, and an unnamed client is rarely intended.
    // Edit mode just requires `isDirty` so we don't round-trip a clean
    // form through the outbox.
    final canSave =
        !vm.isSaving &&
        (vm.isCreate ? vm.draft.name.trim().isNotEmpty : vm.isDirty);
    return EntityEditScaffold<Client>(
      vm: vm,
      canSave: canSave,
      titleBuilder: (context) {
        final displayName = vm.draft.displayName.isNotEmpty
            ? vm.draft.displayName
            : vm.draft.name;
        return vm.isCreate
            ? context.tr('new_client')
            : (displayName.isNotEmpty
                  ? '${context.tr('edit')} · $displayName'
                  : context.tr('edit'));
      },
      bodyBuilder: (context) => ClientEditLayout(vm: vm),
      topBanner: SaveFailedBanner(
        vm: vm,
        onDiscard: () => _discardFailedSync(context, vm),
      ),
      resetToEmpty: vm.resetToEmpty,
      onSaveRejected: () async {
        // Save() returned null with fieldErrors — refresh the dead-row link
        // so the SaveFailedBanner's Discard button targets the *fresh*
        // failure (not whatever stale id was cached). Today no save path
        // throws ValidationException synchronously, so this is defensive
        // for future plumbing (e.g. routing sync.events into the form).
        final services = context.read<Services>();
        await _loadFailedSyncErrors(services, vm.companyId, vm.draft.id);
      },
      onSaved: (context, saved) async {
        // The fresh save queued a new outbox row; the prior dead row's
        // payload is now stale. Delete it so the Outbox screen doesn't
        // keep showing the failure indefinitely. The VM keeps its dead-
        // row link across save() entry, so the lookup here usually hits
        // the cache. The fallback dao query covers the rare path where
        // a 422 landed after the form opened but before the VM got the id.
        final services = context.read<Services>();
        final priorDeadId = await _resolveDeadRowId(services, vm);
        if (priorDeadId != null) {
          await services.db.outboxDao.deleteRow(priorDeadId);
          vm.clearFailedSync();
        }
        if (!context.mounted) return;
        if (vm.isCreate) {
          context.go('/clients/${saved.id}');
        } else {
          context.pop();
        }
      },
    );
  }

  Future<void> _discardFailedSync(
    BuildContext context,
    ClientEditViewModel vm,
  ) async {
    final services = context.read<Services>();
    final rowId = await _resolveDeadRowId(services, vm);
    if (rowId == null) {
      // Nothing on disk to discard — just drop the in-memory error state
      // so the banner clears.
      vm.clearFailedSync();
      return;
    }
    await services.db.outboxDao.deleteRow(rowId);
    vm.clearFailedSync();
  }
}
