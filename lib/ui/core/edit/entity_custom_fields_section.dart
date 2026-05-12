import 'package:flutter/material.dart';

import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/company_custom_fields.dart';
import 'package:admin/ui/core/edit/entity_edit_field.dart';

/// Renders the per-entity custom-value form fields, gated by the company's
/// configured labels.
///
/// The four customValue slots (`customValue1..4` on Client / Product /
/// Invoice / …) all exist on the data layer, but the user only sees a
/// field when the company has configured a label for that slot — e.g.
/// `company.customFields['client1'] = "Region|North,South"` surfaces field
/// 1 as a plain `EntityEditField` labelled "Region". Unconfigured slots
/// don't render. When **all** slots are empty, the entire section
/// collapses to `SizedBox.shrink()` — no header, no toggle, no gap.
///
/// Reusable: pass [keyPrefix] = `'client'` / `'product'` / `'invoice'` to
/// switch which entity's custom-field labels are consulted. The host
/// supplies the [companyStream] (typically
/// `context.read<Services>().company.watch(companyId)`) so this widget
/// stays dependency-free — easy to unit-test and free of any Provider
/// scaffolding.
class EntityCustomFieldsSection extends StatelessWidget {
  const EntityCustomFieldsSection({
    super.key,
    required this.keyPrefix,
    required this.companyStream,
    required this.values,
    required this.onChanged,
  }) : assert(values.length == 4, 'values must have exactly 4 entries'),
       assert(onChanged.length == 4, 'onChanged must have exactly 4 entries');

  /// Lookup prefix for the company's customFields map (e.g. `'client'`,
  /// `'product'`). Combined with `1..4` to form keys like `'client1'`,
  /// `'product3'`.
  final String keyPrefix;

  /// Live stream of the company whose configuration drives this section.
  /// A label change in Settings flows through and reflows the form
  /// automatically — no manual refresh needed.
  final Stream<Company?> companyStream;

  /// Current draft values for slots 1..4. Length is enforced by an assert.
  final List<String> values;

  /// VM setters for slots 1..4 (e.g. `vm.setCustomValue1..4`). Length is
  /// enforced by an assert.
  final List<ValueChanged<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Company?>(
      stream: companyStream,
      builder: (context, snapshot) {
        final company = snapshot.data;
        final fields = <Widget>[];
        for (var i = 1; i <= 4; i++) {
          final label = company?.customFieldLabel('$keyPrefix$i') ?? '';
          if (label.isEmpty) continue;
          // EntityEditField already adds `vertical: InSpacing.xs` padding
          // around itself (see entity_edit_field.dart), matching the gap
          // between the rest of the form's fields — no extra SizedBox
          // separator needed here.
          fields.add(
            EntityEditField(
              label: label,
              initial: values[i - 1],
              onChanged: onChanged[i - 1],
            ),
          );
        }
        if (fields.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: fields,
        );
      },
    );
  }
}
