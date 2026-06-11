import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/tag.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/tag_pill.dart';
import 'package:admin/ui/features/settings/widgets/settings_entity_list_scaffold.dart';

/// Search keys for the settings sidebar search. Colocated with the screen so
/// adding / renaming a field updates both ends in one place.
const kTagsSearchKeys = <String>['tags', 'name', 'color'];

/// `/settings/tags` — manage tags, scoped to task or project via the
/// Task/Project toggle in the banner. Tap a row to edit; "+ New" creates a
/// tag of the currently-selected entity type. Admin/owner-gated for create.
class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  String _entityType = 'task';

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    final me = services.auth.session.value?.currentCompany;
    final isAdminOrOwner = (me?.isAdmin ?? false) || (me?.isOwner ?? false);
    final repo = services.tags;

    return SettingsEntityListScaffold<Tag>(
      titleKey: 'tags',
      sectionTitleKey: 'tags',
      newRoute: '/settings/tags/new?entityType=$_entityType',
      newLabelKey: 'new_tag',
      emptyIcon: Icons.local_offer_outlined,
      emptyTitleKey: 'no_tags',
      emptyHintKey: 'no_tags_hint',
      supportsArchive: true,
      canCreate: isAdminOrOwner,
      banner: _EntityTypeToggle(
        value: _entityType,
        onChanged: (v) => setState(() => _entityType = v),
      ),
      refreshAll: () async {
        if (companyId.isEmpty) return;
        await repo.refreshAll(companyId: companyId);
      },
      stream: ({required includeArchived}) => repo.watchAll(
        companyId: companyId,
        entityType: _entityType,
        includeArchived: includeArchived,
      ),
      isArchivedOf: (t) => t.archivedAt != null,
      isDeletedOf: (t) => t.isDeleted,
      rowBuilder: (t) => _TagRow(key: ValueKey(t.id), tag: t),
      archivedRowBuilder: (t) => _TagRow.archived(key: ValueKey(t.id), tag: t),
    );
  }
}

/// Task / Project segmented toggle rendered above the list (see React's two
/// `/settings/tags` routes — we consolidate into one screen + a toggle).
class _EntityTypeToggle extends StatelessWidget {
  const _EntityTypeToggle({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        InSpacing.lg(context),
        InSpacing.md(context),
        InSpacing.lg(context),
        0,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'task', label: Text(context.tr('tasks'))),
            ButtonSegment(
              value: 'project',
              label: Text(context.tr('projects')),
            ),
          ],
          selected: {value},
          showSelectedIcon: false,
          onSelectionChanged: (s) => onChanged(s.first),
        ),
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.tag, super.key}) : _isArchived = false;

  const _TagRow.archived({required this.tag, super.key}) : _isArchived = true;

  final Tag tag;
  final bool _isArchived;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: parseTagColor(tag.color, fallback: tokens.ink3),
              shape: BoxShape.circle,
            ),
          ),
          title: Text(tag.name.isEmpty ? context.tr('untitled') : tag.name),
          trailing: _isArchived
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.draftSoft,
                    borderRadius: BorderRadius.circular(InRadii.r1),
                  ),
                  child: Text(
                    context.tr('archived'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: tokens.draft,
                    ),
                  ),
                )
              : const Icon(Icons.chevron_right),
          onTap: () => context.go('/settings/tags/${tag.id}'),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
