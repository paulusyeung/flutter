import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/models/domain/user.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
import 'package:admin/ui/features/tasks/view_models/kanban_view_model.dart';

typedef _Named = ({String id, String name});

/// Client-side kanban filter bar: Project / Client / Assignee pickers +
/// Clear. Each clears to "no filter" (null → ''). While any filter is set
/// the board is read-only for reordering (see [KanbanViewModel.filtersActive]).
class KanbanFilterBar extends StatelessWidget {
  const KanbanFilterBar({required this.companyId, super.key});

  final String companyId;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<KanbanViewModel>();
    final services = context.read<Services>();
    final tokens = context.inTheme;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: InSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: StreamBuilder<List<_Named>>(
              stream: services.projects.watchActiveNames(companyId: companyId),
              builder: (context, snap) {
                final items = snap.data ?? const <_Named>[];
                return SearchableDropdownField<_Named>(
                  label: context.tr('project'),
                  items: items,
                  initialValue: items
                      .where((p) => p.id == vm.projectId)
                      .firstOrNull,
                  displayString: (p) => p.name,
                  idOf: (p) => p.id,
                  onChanged: (p) => vm.setProjectFilter(p?.id ?? ''),
                );
              },
            ),
          ),
          SizedBox(width: InSpacing.md(context)),
          Expanded(
            child: StreamBuilder<List<Client>>(
              stream: services.clients.watchPage(
                companyId: companyId,
                loadedPages: 100,
              ),
              builder: (context, snap) {
                final items = snap.data ?? const <Client>[];
                return SearchableDropdownField<Client>(
                  label: context.tr('client'),
                  items: items,
                  initialValue: items
                      .where((c) => c.id == vm.clientId)
                      .firstOrNull,
                  displayString: (c) =>
                      c.displayName.isEmpty ? c.name : c.displayName,
                  idOf: (c) => c.id,
                  onChanged: (c) => vm.setClientFilter(c?.id ?? ''),
                );
              },
            ),
          ),
          SizedBox(width: InSpacing.md(context)),
          Expanded(
            child: StreamBuilder<List<User>>(
              stream: services.user.watchPage(
                companyId: companyId,
                loadedPages: 100,
              ),
              builder: (context, snap) {
                final items = snap.data ?? const <User>[];
                return SearchableDropdownField<User>(
                  label: context.tr('assigned_user'),
                  items: items,
                  initialValue: items
                      .where((u) => u.id == vm.assignedUserId)
                      .firstOrNull,
                  displayString: (u) => u.displayName,
                  idOf: (u) => u.id,
                  onChanged: (u) => vm.setAssigneeFilter(u?.id ?? ''),
                );
              },
            ),
          ),
          if (vm.filtersActive) ...[
            SizedBox(width: InSpacing.md(context)),
            TextButton.icon(
              onPressed: vm.clearFilters,
              icon: const Icon(Icons.clear, size: 16),
              label: Text(context.tr('clear')),
            ),
          ],
        ],
      ),
    );
  }
}
