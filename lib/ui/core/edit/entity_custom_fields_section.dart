import 'package:flutter/material.dart';

import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/company_custom_fields.dart';
import 'package:admin/ui/core/edit/entity_edit_field.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';

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
/// `context.read<Services>().company.watchCompany(companyId)`) so this widget
/// stays dependency-free — easy to unit-test and free of any Provider
/// scaffolding.
///
/// Pass [wrapInCard] (default `true`) to wrap the section in a
/// [DashboardCardShell] with [cardTitle] — sits alongside the other cards in
/// the right column of a two-column edit layout. The card disappears
/// entirely when all slots are unconfigured (mirroring the inner widget's
/// `SizedBox.shrink()` collapse). The card is also skipped — fields render
/// inline — when [cardTitle] is null or empty, even with `wrapInCard: true`:
/// a titleless `DashboardCardShell` would otherwise draw an empty header box.
/// Hosts that nest this section inside their own card (client/vendor details,
/// billing-doc edit tabs) simply pass no [cardTitle]; `wrapInCard: false` is
/// equivalent and reads more explicitly.
class EntityCustomFieldsSection extends StatelessWidget {
  const EntityCustomFieldsSection({
    super.key,
    required this.keyPrefix,
    required this.companyStream,
    required this.values,
    required this.onChanged,
    this.wrapInCard = true,
    this.cardTitle,
    this.slots = const [1, 2, 3, 4],
  }) : assert(values.length == 4, 'values must have exactly 4 entries'),
       assert(onChanged.length == 4, 'onChanged must have exactly 4 entries');

  /// Which of the four custom-field slots to render (1-based). Defaults
  /// to all four. The billing-doc edit screen splits these across two
  /// columns by passing `[1, 3]` and `[2, 4]`.
  final List<int> slots;

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

  /// Wrap the field column in a [DashboardCardShell] (titled by [cardTitle]).
  /// Defaults to true — the common pattern. Set false for layouts that own
  /// their own card chrome.
  final bool wrapInCard;

  /// Card title when [wrapInCard] is true. Typically
  /// `context.tr('custom_fields')`. Ignored when `wrapInCard: false`.
  final String? cardTitle;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Company?>(
      stream: companyStream,
      builder: (context, snapshot) {
        final company = snapshot.data;
        final fields = <Widget>[];
        for (var i = 1; i <= 4; i++) {
          if (!slots.contains(i)) continue;
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
        final column = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: fields,
        );
        // Wrap in a card only when there's an actual title to show. A
        // null/empty title would otherwise render `DashboardCardShell` with an
        // empty header row (it treats `title: ''` as "has header"), drawing a
        // stray empty box — the case for every host that nests this section
        // inside its own card (client/vendor details, billing-doc edit tabs).
        final title = cardTitle;
        if (!wrapInCard || title == null || title.isEmpty) return column;
        return DashboardCardShell(title: title, child: column);
      },
    );
  }
}
