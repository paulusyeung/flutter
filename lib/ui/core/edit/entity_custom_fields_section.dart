import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/custom_field_types.dart';
import 'package:admin/ui/core/edit/entity_edit_field.dart';
import 'package:admin/ui/core/widgets/in_date_field.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/utils/formatting.dart';

/// Renders the per-entity custom-value form fields, gated by the company's
/// configured labels — and by the configured **type**: single-line text,
/// multi-line text, switch (`'yes'`/`'no'`), date (ISO `yyyy-MM-dd`), or a
/// dropdown over comma-separated options.
///
/// The four customValue slots (`customValue1..4` on Client / Product /
/// Invoice / …) all exist on the data layer, but the user only sees a
/// field when the company has configured a label for that slot — e.g.
/// `company.customFields['client1'] = "Region|North,South"` surfaces field
/// 1 as a "Region" dropdown. Unconfigured slots don't render. When **all**
/// slots are empty, the entire section collapses to `SizedBox.shrink()`.
///
/// Reusable: pass [keyPrefix] = `'client'` / `'product'` / `'invoice'` to
/// switch which entity's custom-field labels are consulted. The host supplies
/// the [companyStream] (typically
/// `context.read<Services>().company.watchCompany(companyId)`) so this widget
/// stays dependency-free. Pass [formatter] when date-typed slots should display
/// in the company's date format (falls back to ISO when null).
///
/// Pass [wrapInCard] (default `true`) to wrap the section in a
/// [DashboardCardShell] with [cardTitle]. The card disappears entirely when all
/// slots are unconfigured. The card is skipped — fields render inline — when
/// [cardTitle] is null or empty, even with `wrapInCard: true`. Hosts that nest
/// this section inside their own card pass no [cardTitle].
class EntityCustomFieldsSection extends StatelessWidget {
  const EntityCustomFieldsSection({
    super.key,
    required this.keyPrefix,
    required this.companyStream,
    required this.values,
    required this.onChanged,
    this.formatter,
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
  /// `'product'`). Combined with `1..4` to form keys like `'client1'`.
  final String keyPrefix;

  /// Live stream of the company whose configuration drives this section.
  /// A label/type change in Settings flows through and reflows the form
  /// automatically — no manual refresh needed.
  final Stream<Company?> companyStream;

  /// Current draft values for slots 1..4. Length is enforced by an assert.
  final List<String> values;

  /// VM setters for slots 1..4 (e.g. `vm.setCustomValue1..4`). Length is
  /// enforced by an assert.
  final List<ValueChanged<String>> onChanged;

  /// Active company `Formatter`, used to render/parse date-typed custom
  /// fields. When null, date fields fall back to ISO display + parsing.
  final Formatter? formatter;

  /// Wrap the field column in a [DashboardCardShell] (titled by [cardTitle]).
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
          final parsed = company == null
              ? const ParsedCustomField(
                  label: '',
                  type: kFieldTypeSingleLineText,
                  options: [],
                )
              : parseCustomField(company.customFields['$keyPrefix$i']);
          if (parsed.label.isEmpty) continue;
          fields.add(_buildField(parsed, i));
        }
        if (fields.isEmpty) return const SizedBox.shrink();
        final column = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: fields,
        );
        // Wrap in a card only when there's an actual title to show — a
        // null/empty title would render `DashboardCardShell` with an empty
        // header box.
        final title = cardTitle;
        if (!wrapInCard || title == null || title.isEmpty) return column;
        return DashboardCardShell(title: title, child: column);
      },
    );
  }

  Widget _buildField(ParsedCustomField parsed, int slot) {
    final value = values[slot - 1];
    final onChange = onChanged[slot - 1];
    switch (parsed.type) {
      case kFieldTypeMultiLineText:
        return EntityEditField(
          label: parsed.label,
          initial: value,
          onChanged: onChange,
          minLines: 3,
          maxLines: 3,
        );
      case kFieldTypeSwitch:
        return _CustomSwitchRow(
          label: parsed.label,
          value: value,
          onChanged: onChange,
        );
      case kFieldTypeDate:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: InSpacing.xs),
          child: InDateField(
            labelText: parsed.label,
            formatter: formatter,
            clearable: true,
            value: value.isEmpty ? null : DateTime.tryParse(value),
            onChanged: (d) => onChange(d == null ? '' : _isoDate(d)),
          ),
        );
      case kFieldTypeDropdown:
        // Prepend a blank so the user can clear, and so `items` is never empty
        // (an empty list renders SearchableDropdownField's "loading"
        // placeholder). Selecting the blank writes '' (unselected).
        final items = <String>['', ...parsed.options];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: InSpacing.xs),
          child: SearchableDropdownField<String>(
            label: parsed.label,
            items: items,
            initialValue: items.contains(value) ? value : '',
            displayString: (o) => o,
            idOf: (o) => o,
            onChanged: (o) => onChange(o ?? ''),
          ),
        );
      case kFieldTypeSingleLineText:
      default:
        return EntityEditField(
          label: parsed.label,
          initial: value,
          onChanged: onChange,
        );
    }
  }
}

/// ISO `yyyy-MM-dd` for a calendar date — the wire format for date-typed
/// custom values (matches React's `<input type="date">` + admin-portal).
String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Switch-typed custom field: a [Switch] + label row. Stored value is the
/// canonical `'yes'` / `'no'` string.
class _CustomSwitchRow extends StatelessWidget {
  const _CustomSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: InSpacing.xs),
      child: Row(
        children: [
          Switch(
            value: value == kSwitchValueYes,
            onChanged: (v) => onChanged(v ? kSwitchValueYes : kSwitchValueNo),
          ),
          SizedBox(width: InSpacing.sm),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
