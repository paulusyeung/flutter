import 'package:flutter/material.dart';

import 'package:admin/data/models/domain/transaction_rule.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';

/// Modal sheet for editing one [RuleCriterion]. Returns the modified
/// criterion on save, or null on cancel.
Future<RuleCriterion?> showRuleCriterionSheet({
  required BuildContext context,
  required RuleCriterion initial,
  required bool isCredit,
}) {
  return showModalBottomSheet<RuleCriterion>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetCtx) =>
        _RuleCriterionSheet(initial: initial, isCredit: isCredit),
  );
}

class _RuleCriterionSheet extends StatefulWidget {
  const _RuleCriterionSheet({required this.initial, required this.isCredit});

  final RuleCriterion initial;
  final bool isCredit;

  @override
  State<_RuleCriterionSheet> createState() => _RuleCriterionSheetState();
}

class _RuleCriterionSheetState extends State<_RuleCriterionSheet> {
  late String _searchKey;
  late String _operator;
  late TextEditingController _value;

  static const _debitKeys = <String>[
    kRuleSearchKeyDescription,
    kRuleSearchKeyAmount,
    kRuleSearchKeyParticipant,
    kRuleSearchKeyParticipantName,
  ];

  static const _stringOperators = <String>[
    kRuleOperatorIs,
    kRuleOperatorContains,
    kRuleOperatorStartsWith,
    kRuleOperatorIsEmpty,
  ];

  static const _numberOperators = <String>[
    kRuleOperatorEquals,
    kRuleOperatorLessThan,
    kRuleOperatorLessThanOrEqual,
    kRuleOperatorGreaterThan,
    kRuleOperatorGreaterThanOrEqual,
    kRuleOperatorIsEmpty,
  ];

  @override
  void initState() {
    super.initState();
    final keys = widget.isCredit ? kRuleCreditSearchKeys : _debitKeys;
    _searchKey =
        widget.initial.searchKey.isNotEmpty &&
            keys.contains(widget.initial.searchKey)
        ? widget.initial.searchKey
        : keys.first;
    final operators = _operatorsFor(_searchKey);
    _operator =
        widget.initial.operator.isNotEmpty &&
            operators.contains(widget.initial.operator)
        ? widget.initial.operator
        : operators.first;
    _value = TextEditingController(text: widget.initial.value);
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  List<String> _operatorsFor(String key) =>
      isNumericSearchKey(key) ? _numberOperators : _stringOperators;

  @override
  Widget build(BuildContext context) {
    final keys = widget.isCredit ? kRuleCreditSearchKeys : _debitKeys;
    final operators = _operatorsFor(_searchKey);
    final hideValue = _operator == kRuleOperatorIsEmpty;
    // Save is only meaningful when a value is present (or `is_empty` is
    // selected, which deliberately omits the value field). Without this
    // gate users can land a `description contains <empty>` criterion
    // that always matches every row.
    final canSave =
        _searchKey.isNotEmpty &&
        _operator.isNotEmpty &&
        (hideValue || _value.text.trim().isNotEmpty);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('add_rule'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _buildSearchKeyField(context, keys),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _operator,
            decoration: InputDecoration(labelText: context.tr('operator')),
            items: [
              for (final op in operators)
                DropdownMenuItem(value: op, child: Text(labelForOperator(op))),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _operator = v);
            },
          ),
          const SizedBox(height: 12),
          if (!hideValue)
            TextField(
              controller: _value,
              decoration: InputDecoration(labelText: context.tr('value')),
              keyboardType: isNumericSearchKey(_searchKey)
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              autofocus: true,
              // Re-render so canSave flips as the user types.
              onChanged: (_) => setState(() {}),
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(minimumSize: const Size(64, 40)),
                child: Text(context.tr('cancel')),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: canSave
                    ? () => Navigator.of(context).pop(
                        RuleCriterion(
                          searchKey: _searchKey,
                          operator: _operator,
                          value: hideValue ? '' : _value.text.trim(),
                        ),
                      )
                    : null,
                style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
                child: Text(context.tr('save')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// CREDIT-side search keys hit 19 entries — long enough that scrolling
  /// a vanilla dropdown is cumbersome. Use [SearchableDropdownField] to
  /// honor the CLAUDE.md "type-to-search past ~20 options" rule.
  Widget _buildSearchKeyField(BuildContext context, List<String> keys) {
    if (widget.isCredit) {
      return SearchableDropdownField<String>(
        label: context.tr('field'),
        items: keys,
        initialValue: _searchKey.isEmpty ? null : _searchKey,
        idOf: (k) => k,
        displayString: labelForSearchKey,
        onChanged: (v) {
          if (v == null) return;
          setState(() {
            _searchKey = v;
            final next = _operatorsFor(v);
            if (!next.contains(_operator)) _operator = next.first;
          });
        },
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: _searchKey,
      decoration: InputDecoration(labelText: context.tr('field')),
      items: [
        for (final k in keys)
          DropdownMenuItem(value: k, child: Text(labelForSearchKey(k))),
      ],
      onChanged: (v) {
        if (v == null) return;
        setState(() {
          _searchKey = v;
          final next = _operatorsFor(v);
          if (!next.contains(_operator)) _operator = next.first;
        });
      },
    );
  }
}
