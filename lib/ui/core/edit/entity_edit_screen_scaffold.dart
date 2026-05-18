import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/ui/core/edit/entity_edit_scaffold.dart';
import 'package:admin/ui/core/edit/generic_edit_view_model.dart';
import 'package:admin/ui/core/widgets/save_failed_banner.dart';

/// Outer scaffold for every entity edit / create screen.
///
/// Wraps [EntityEditScaffold] with the boilerplate every concrete edit
/// screen needs:
///
///   * VM lifecycle — sync construction for `create`, async fetch + ctor
///     for `edit`. The "Loading…" placeholder Scaffold while the existing
///     row is being read.
///   * Dead-outbox-row 422 recovery — on load, look up the newest `dead`
///     row for this entity and hydrate its `fieldErrorsJson` onto the VM
///     so the form opens pre-flagged. On a successful save, delete the
///     prior dead row so the Outbox screen does not keep showing the
///     stale failure. On a fresh 422, re-link to the new dead row so the
///     SaveFailedBanner's Discard targets the *fresh* failure.
///   * The SaveFailedBanner wired into `topBanner` (renders nothing when
///     `vm.fieldErrors` is empty, so always safe to pass).
///
/// Per-entity screens become ~30 lines: a single
/// `EntityEditScreenScaffold<T, VM>(...)` invocation with builders that
/// know how to construct the VM, fetch the existing row, render the form,
/// and navigate after save.
class EntityEditScreenScaffold<T, VM extends GenericEditViewModel<T>>
    extends StatefulWidget {
  const EntityEditScreenScaffold({
    super.key,
    required this.existingId,
    required this.entityTypeName,
    required this.fetchExisting,
    required this.buildVm,
    required this.titleBuilder,
    required this.titleWhileLoading,
    required this.bodyBuilder,
    required this.resetToEmpty,
    required this.onSaved,
    required this.entityIdOf,
    this.canSave,
    this.embedded = false,
    this.actionsBuilder,
    this.saveParamFor,
    this.onAfterSaveAction,
  });

  /// Existing entity id when editing; null for create.
  final String? existingId;

  /// Outbox wire name for this entity (e.g. `'client'`, `'product'`).
  /// Used to scope the dead-row lookup.
  final String entityTypeName;

  /// Read the existing row once so the VM can be seeded. Called only when
  /// [existingId] is non-null. Reading once (not subscribing) matches the
  /// edit-screen semantics: the form snapshots the row, then owns the
  /// draft until save.
  final Future<T?> Function(
    BuildContext context,
    Services services,
    String companyId,
    String id,
  )
  fetchExisting;

  /// Construct the VM. `existing` is non-null when editing, null when
  /// creating.
  final VM Function(
    BuildContext context,
    Services services,
    String companyId,
    T? existing,
  )
  buildVm;

  /// AppBar title once the VM is ready.
  final String Function(BuildContext context, VM vm) titleBuilder;

  /// AppBar title while the existing row is being fetched.
  final String Function(BuildContext context) titleWhileLoading;

  final Widget Function(BuildContext context, VM vm) bodyBuilder;

  /// Called by the discard guard. Typically `(vm) => vm.resetToEmpty()`.
  final void Function(VM vm) resetToEmpty;

  /// Invoked after a successful save and after dead-row cleanup. Caller
  /// decides whether to pop or go to a detail route.
  final FutureOr<void> Function(BuildContext context, VM vm, T saved) onSaved;

  /// Optional Save-button gate. Defaults to `!vm.isSaving`.
  final bool Function(VM vm)? canSave;

  /// Read the entity id from a draft. Every entity has an `id` field but
  /// the generic [T] does not advertise that, so the caller supplies the
  /// accessor (typically `(c) => c.id`). Used to look up the dead outbox
  /// row that holds prior 422 errors.
  final String Function(T draft) entityIdOf;

  /// When `true`, the underlying [EntityEditScaffold] renders without
  /// its own `Scaffold` / `AppBar` — the host shell (typically
  /// `MasterDetailLayout` on wide desktop) owns the chrome.
  final bool embedded;

  /// Builds the right-aligned, overflow-aware header action cluster.
  /// Receives the live VM so the per-entity closure can read `vm.draft` /
  /// `vm.isCreate` (e.g. to apply `filterForEditScreen`). Returns an
  /// `EntityOverflowActionBar<A>` with the plain [saveButton] forwarded as
  /// its `leading:` child; wire each item's `onTap` to the type-erased
  /// sink. Null => no action bar.
  final Widget Function(
    BuildContext context,
    VM vm,
    void Function(Object action) onTap,
    Widget saveButton,
  )?
  actionsBuilder;

  /// Per-entity SAVE-PARAM classifier (typically `<E>Actions.saveParamFor`
  /// composed with the action-enum cast). Null => all actions after-save.
  final Map<String, String>? Function(Object action)? saveParamFor;

  /// Per-entity AFTER-SAVE dispatcher (typically
  /// `(ctx, saved, a) => InvoiceActions.dispatch(ctx, services,
  /// companyId, saved, a as InvoiceAction)`).
  final Future<void> Function(BuildContext context, T saved, Object action)?
  onAfterSaveAction;

  @override
  State<EntityEditScreenScaffold<T, VM>> createState() =>
      _EntityEditScreenScaffoldState<T, VM>();
}

class _EntityEditScreenScaffoldState<T, VM extends GenericEditViewModel<T>>
    extends State<EntityEditScreenScaffold<T, VM>> {
  VM? _vm;
  bool _ready = false;
  late final String _companyId;

  @override
  void initState() {
    super.initState();
    final services = context.read<Services>();
    _companyId = services.auth.session.value!.currentCompanyId;
    if (widget.existingId == null) {
      _vm = widget.buildVm(context, services, _companyId, null);
      _ready = true;
    } else {
      _load(services, _companyId, widget.existingId!);
    }
  }

  Future<void> _load(
    Services services,
    String companyId,
    String existingId,
  ) async {
    final existing = await widget.fetchExisting(
      context,
      services,
      companyId,
      existingId,
    );
    if (!mounted) return;
    final vm = widget.buildVm(context, services, companyId, existing);
    setState(() {
      _vm = vm;
      _ready = true;
    });
    await _hydrateFailedSync(services, companyId, existingId);
  }

  /// Replay a prior 422 onto the VM. Reads the newest dead outbox row for
  /// this entity (if any) and pushes its `field_errors_json` onto the VM
  /// so the form opens pre-flagged. No-op when nothing on disk or when
  /// the field-errors blob fails to decode.
  Future<void> _hydrateFailedSync(
    Services services,
    String companyId,
    String entityId,
  ) async {
    final row = await services.db.outboxDao.findDeadForEntity(
      companyId: companyId,
      entityType: widget.entityTypeName,
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

  /// Resolve the dead row id for the current entity. Prefers the VM's
  /// cached id; falls back to a dao lookup so the right row is targeted
  /// even when a 422 landed after the form opened but before the VM
  /// learned its id.
  Future<int?> _resolveDeadRowId(Services services, VM vm) async {
    final cached = vm.deadOutboxRowId;
    if (cached != null) return cached;
    final entityId = widget.existingId;
    if (entityId == null) return null;
    final row = await services.db.outboxDao.findDeadForEntity(
      companyId: _companyId,
      entityType: widget.entityTypeName,
      entityId: entityId,
    );
    return row?.id;
  }

  Future<void> _discardFailedSync(VM vm) async {
    final services = context.read<Services>();
    final rowId = await _resolveDeadRowId(services, vm);
    if (rowId == null) {
      vm.clearFailedSync();
      return;
    }
    await services.db.outboxDao.deleteRow(rowId);
    vm.clearFailedSync();
  }

  @override
  void dispose() {
    _vm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _vm == null) {
      // Embedded mode skips the Scaffold even on the loading state so
      // the parent shell's chrome doesn't briefly disappear before the
      // form renders.
      if (widget.embedded) {
        return const Center(child: CircularProgressIndicator());
      }
      return Scaffold(
        appBar: AppBar(title: Text(widget.titleWhileLoading(context))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final vm = _vm!;
    final canSave = widget.canSave?.call(vm) ?? !vm.isSaving;
    return EntityEditScaffold<T>(
      vm: vm,
      canSave: canSave,
      embedded: widget.embedded,
      actionsBuilder: widget.actionsBuilder == null
          ? null
          : (ctx, onTap, saveButton) =>
                widget.actionsBuilder!(ctx, vm, onTap, saveButton),
      saveParamFor: widget.saveParamFor,
      onAfterSaveAction: widget.onAfterSaveAction,
      titleBuilder: (ctx) => widget.titleBuilder(ctx, vm),
      bodyBuilder: (ctx) => widget.bodyBuilder(ctx, vm),
      topBanner: SaveFailedBanner(
        vm: vm,
        onDiscard: () => _discardFailedSync(vm),
      ),
      resetToEmpty: () => widget.resetToEmpty(vm),
      onSaveRejected: () async {
        // Fresh 422 landed — re-link to the new dead row so a subsequent
        // Discard tap targets *this* failure, not the prior cached id.
        final services = context.read<Services>();
        await _hydrateFailedSync(
          services,
          _companyId,
          widget.entityIdOf(vm.draft),
        );
      },
      onSaved: (ctx, saved) async {
        // A fresh save queued a new outbox row; the prior dead row's
        // payload is stale. Delete it so the Outbox screen doesn't keep
        // showing the failure indefinitely.
        final services = ctx.read<Services>();
        final priorDeadId = await _resolveDeadRowId(services, vm);
        if (priorDeadId != null) {
          await services.db.outboxDao.deleteRow(priorDeadId);
          vm.clearFailedSync();
        }
        if (!ctx.mounted) return;
        await widget.onSaved(ctx, vm, saved);
      },
    );
  }
}
