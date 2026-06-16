import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/tag.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/tag_picker_field.dart';

/// Drop-in tag picker for an entity edit form. Streams the active tag cache
/// for [entityType] (`task` / `project`), gates inline-create to
/// admins/owners, and emits the selected id set via [onChanged]. The edit
/// VM only needs a `setTagIds(List<String>)` setter and `draft.tagIds`.
class EntityTagsField extends StatelessWidget {
  const EntityTagsField({
    super.key,
    required this.entityType,
    required this.selectedIds,
    required this.onChanged,
    this.enabled = true,
  });

  final String entityType;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    final me = services.auth.session.value?.currentCompany;
    final isAdminOrOwner = (me?.isAdmin ?? false) || (me?.isOwner ?? false);
    return StreamBuilder<List<Tag>>(
      // All lifecycle states in one stream: the active pool is derived for
      // selection, and every name (incl. archived/deleted) feeds the picker's
      // inline-create collision check — the server's UNIQUE rule reserves
      // soft-deleted names too, so creating one 422s and kills the save (M1).
      stream: services.tags.watchAllAnyState(
        companyId: companyId,
        entityType: entityType,
      ),
      builder: (context, snap) {
        final all = snap.data ?? const <Tag>[];
        final available = [
          for (final t in all)
            if (t.archivedAt == null && !t.isDeleted) t,
        ];
        final reservedNames = {for (final t in all) t.name.toLowerCase()};
        return TagPickerField(
          label: context.tr('tags'),
          available: available,
          reservedNames: reservedNames,
          selectedIds: selectedIds,
          enabled: enabled,
          onChanged: onChanged,
          onCreate: isAdminOrOwner
              ? (name) async {
                  final result = await services.tags.create(
                    companyId: companyId,
                    draft: newTagDraft(name: name, entityType: entityType),
                  );
                  return result.entity;
                }
              : null,
        );
      },
    );
  }
}
