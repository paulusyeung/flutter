import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/data/models/domain/design.dart';
import 'package:admin/data/static/built_in_designs_catalog.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/overridable_searchable_dropdown_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_field_bindings.dart';

/// Cascade-aware design picker for `company.settings.*_design_id` keys.
///
/// Merges the bundled [Design] list (passed in by the parent body, sourced
/// from `DesignRepository.watchAll`) with the [kBuiltInDesigns] static
/// catalog so the picker renders before the first /refresh delivers
/// `data[N].company.designs` and stays consistent across logged-out demo
/// installs that haven't fetched anything yet. Bundled rows win on id
/// collision (the server is authoritative).
///
/// When [allowBlank] is true (used for the optional pickers — delivery_note,
/// statement, payment_receipt, payment_refund) the user can clear the field
/// to fall back to the server default.
class OverridableDesignPicker extends StatelessWidget {
  const OverridableDesignPicker({
    super.key,
    required this.label,
    required this.apiKey,
    this.allowBlank = false,
    this.bundledDesigns = const <Design>[],
    this.forEntity,
  });

  final String label;
  final String apiKey;
  final bool allowBlank;

  /// Bundled `Design` rows from `services.designs.watchAll`. Optional — the
  /// picker falls back to the built-in catalog when empty (offline / first
  /// paint).
  final List<Design> bundledDesigns;

  /// Filter bundled designs to those whose `entities` list contains this
  /// entity type. Built-in designs aren't filtered (they work for every
  /// entity type). When null, every bundled design is included.
  final String? forEntity;

  @override
  Widget build(BuildContext context) {
    final binding = settingsBindingOf(apiKey);
    final host = context.watch<SettingsDraftHost>();
    final value = binding.read(host.settings);

    final items = _mergeItems();
    return OverridableSearchableDropdownField<_DesignOption>(
      label: label,
      apiKey: apiKey,
      value: value,
      items: items,
      displayString: (d) => d.name,
      idOf: (d) => d.id,
      onChanged: (id) => host.updateSettings(
        (s) => binding.write(s, (id == null || id.isEmpty) ? null : id),
      ),
    );
  }

  List<_DesignOption> _mergeItems() {
    final byId = <String, _DesignOption>{};
    if (allowBlank) {
      byId[''] = const _DesignOption(id: '', name: '—');
    }
    for (final d in kBuiltInDesigns) {
      byId[d.id] = _DesignOption(id: d.id, name: d.name);
    }
    for (final d in bundledDesigns) {
      if (forEntity != null &&
          d.isCustom &&
          d.entities.isNotEmpty &&
          !d.entities.contains(forEntity)) {
        continue;
      }
      byId[d.id] = _DesignOption(id: d.id, name: d.name);
    }
    final list = byId.values.toList()..sort((a, b) => a.name.compareTo(b.name));
    // Keep the blank option at the top for the optional pickers.
    if (allowBlank) {
      list.sort((a, b) {
        if (a.id == '') return -1;
        if (b.id == '') return 1;
        return a.name.compareTo(b.name);
      });
    }
    return list;
  }
}

/// Minimal `(id, name)` shape consumed by the picker. Avoids exposing the
/// full `Design` domain model to callers that only need to select an id.
class _DesignOption {
  const _DesignOption({required this.id, required this.name});
  final String id;
  final String name;
}
