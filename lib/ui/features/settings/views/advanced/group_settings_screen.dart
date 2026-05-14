import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/group_setting.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';

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
/// affordance. Tapping a row opens the edit screen. Empty list flips to a
/// centered EmptyState that surfaces the primary CTA directly.
class GroupSettingsScreen extends StatefulWidget {
  const GroupSettingsScreen({super.key});

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  late final Services _services = context.read<Services>();
  late final String _companyId =
      _services.auth.session.value?.currentCompanyId ?? '';

  @override
  void initState() {
    super.initState();
    // Fire-and-forget — refresh from the server in the background while the
    // local stream renders whatever Drift already has.
    if (_companyId.isNotEmpty) {
      _services.groupSettings.refreshAll(companyId: _companyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenScaffold(
      titleKey: 'group_settings',
      body: StreamBuilder<List<GroupSetting>>(
        stream: _services.groupSettings.watchAll(companyId: _companyId),
        builder: (context, snapshot) {
          // Show a loader while we wait on the first emission — without
          // this, the empty-state CTA flashes for a moment on a brand-new
          // device before Drift hands us actual data.
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final groups = snapshot.data ?? const <GroupSetting>[];
          if (groups.isEmpty) {
            return EmptyState(
              icon: Icons.group_work_outlined,
              title: context.tr('no_groups_yet'),
              subtitle: context.tr('no_groups_yet_subtitle'),
              action: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
                icon: const Icon(Icons.add),
                label: Text(context.tr('new_group')),
                onPressed: () => context.go('/settings/group_settings/new'),
              ),
            );
          }
          return SettingsFormShell(
            sections: [
              FormSection(
                title: context.tr('groups'),
                spacing: 0,
                children: [
                  for (final g in groups) ...[
                    _GroupRow(group: g),
                    const Divider(height: 1),
                  ],
                  _NewGroupTile(),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.group});

  final GroupSetting group;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(group.name.isEmpty ? context.tr('untitled') : group.name),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go('/settings/group_settings/${group.id}'),
    );
  }
}

class _NewGroupTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.add),
      title: Text(context.tr('new_group')),
      onTap: () => context.go('/settings/group_settings/new'),
    );
  }
}
