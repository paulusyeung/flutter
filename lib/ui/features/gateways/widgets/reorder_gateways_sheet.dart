import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company_gateway.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';

/// Bottom sheet that lets the user drag-to-reorder their configured
/// gateways. Persists by writing `company.settings.companyGatewayIds` —
/// a comma-separated id list — through the standard `CompanyRepository.
/// updateCompany` outbox path. Mirrors the legacy `company_gateway_list_vm.dart`
/// reorder logic at lines 96-110.
///
/// Show with `showModalBottomSheet`, e.g.:
///   `await showModalBottomSheet(context: context, isScrollControlled: true,
///       builder: (_) => ReorderGatewaysSheet(gateways: vm.items));`
class ReorderGatewaysSheet extends StatefulWidget {
  const ReorderGatewaysSheet({super.key, required this.gateways});

  /// Snapshot of the gateways to reorder. Order in the sheet seeds from
  /// the union of (a) the company's current `companyGatewayIds` and (b)
  /// any rows in [gateways] that aren't in that list (appended). New
  /// gateways the user has added since the last save thus surface at the
  /// bottom and can be slotted into place.
  final List<CompanyGateway> gateways;

  @override
  State<ReorderGatewaysSheet> createState() => _ReorderGatewaysSheetState();
}

class _ReorderGatewaysSheetState extends State<ReorderGatewaysSheet> {
  late List<CompanyGateway> _items;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _items = List<CompanyGateway>.from(widget.gateways);
    _seedOrder();
  }

  /// Re-sort `_items` so rows already in `company.settings.companyGatewayIds`
  /// take their stored positions and unknown rows append at the end. Runs
  /// once on mount — interactive reorders mutate the list directly.
  Future<void> _seedOrder() async {
    final services = context.read<Services>();
    final session = services.auth.session.value;
    if (session == null) return;
    final company = await services.company
        .watchCompany(session.currentCompanyId)
        .first;
    final csv = company?.settings.companyGatewayIds ?? '';
    if (csv.isEmpty) return;
    final ordered = csv.split(',').where((s) => s.isNotEmpty).toList();
    final byId = {for (final g in _items) g.id: g};
    final next = <CompanyGateway>[
      for (final id in ordered)
        if (byId.containsKey(id)) byId.remove(id)!,
      ...byId.values, // rows not in the stored order land at the bottom.
    ];
    if (!mounted) return;
    setState(() => _items = next);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                InSpacing.lg,
                InSpacing.lg,
                InSpacing.lg,
                InSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('reorder'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(context.tr('cancel')),
                  ),
                  const SizedBox(width: InSpacing.sm),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(64, 40),
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.tr('save')),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: tokens.border),
            Flexible(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                itemCount: _items.length,
                onReorder: _onReorder,
                itemBuilder: (context, i) {
                  final g = _items[i];
                  final providerName = context
                      .read<Services>()
                      .statics
                      .gateway(g.gatewayKey)
                      ?.name;
                  final display = g.resolveDisplayName(
                    gatewayName: providerName,
                  );
                  return ListTile(
                    key: ValueKey(g.id),
                    leading: const Icon(Icons.drag_handle),
                    title: Text(display),
                    subtitle: providerName != null && providerName != display
                        ? Text(providerName)
                        : null,
                    trailing: ReorderableDragStartListener(
                      index: i,
                      child: const Icon(Icons.reorder),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      // ReorderableListView's idiom: when dragging down past the original
      // index, newIndex is one past the destination — subtract one.
      var to = newIndex;
      if (to > oldIndex) to -= 1;
      final item = _items.removeAt(oldIndex);
      _items.insert(to, item);
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final services = context.read<Services>();
      final session = services.auth.session.value;
      if (session == null) return;
      final company = await services.company
          .watchCompany(session.currentCompanyId)
          .first;
      if (company == null) return;
      final next = company.copyWith(
        settings: company.settings.copyWith(
          companyGatewayIds: _items.map((g) => g.id).join(','),
        ),
      );
      await services.company.updateCompany(draft: next);
      if (!mounted) return;
      Notify.success(context, context.tr('saved'));
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) Notify.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

/// Helper that resolves the gateways currently displayed by the list VM
/// and opens the [ReorderGatewaysSheet]. Caller is the list screen's
/// `extraAppBarActions` IconButton.
Future<void> openReorderGatewaysSheet(
  BuildContext context, {
  required List<CompanyGateway> gateways,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => ReorderGatewaysSheet(gateways: gateways),
  );
}
