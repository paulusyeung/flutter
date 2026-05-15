import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/group_setting.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/widgets/plan_gate_banner.dart';
import 'package:admin/ui/features/settings/widgets/settings_entity_list_scaffold.dart';

/// Search keys exported for the settings sidebar search. Colocated with the
/// screen so adding / renaming a field updates both ends in one place.
const kGroupSettingsSearchKeys = <String>[
  'groups',
  'name',
  'currency',
  'language',
  'country',
];

/// `/settings/group_settings` — list every group with a leading "New group"
/// affordance. Tapping a row opens the edit screen. No archive support
/// today (group lifecycle is create + edit + delete only).
class GroupSettingsScreen extends StatelessWidget {
  const GroupSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final session = services.auth.session.value;
    final companyId = session?.currentCompanyId ?? '';
    final hasAccess = session?.isProPlan ?? false;
    final repo = services.groupSettings;

    return SettingsEntityListScaffold<GroupSetting>(
      titleKey: 'group_settings',
      sectionTitleKey: 'groups',
      newRoute: '/settings/group_settings/new',
      newLabelKey: 'new_group',
      emptyIcon: Icons.group_work_outlined,
      emptyTitleKey: 'no_groups_yet',
      emptyHintKey: 'no_groups_yet_subtitle',
      refreshAll: () async {
        if (companyId.isEmpty) return;
        await repo.refreshAll(companyId: companyId);
      },
      stream: ({required includeArchived}) =>
          repo.watchAll(companyId: companyId),
      isArchivedOf: (g) => g.archivedAt != null,
      isDeletedOf: (g) => g.isDeleted,
      rowBuilder: (g) => _GroupRow(key: ValueKey(g.id), group: g),
      banner: const PlanGateBanner(style: PlanGateStyle.stripe),
      canCreate: hasAccess,
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.group, super.key});

  final GroupSetting group;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text(group.name.isEmpty ? context.tr('untitled') : group.name),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/settings/group_settings/${group.id}'),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
