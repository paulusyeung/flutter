import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';

/// Which segment of a chip the [SegmentMenu] is editing.
enum SegmentKind { comparator, value }

/// Self-contained dropdown for one segment of a comparable filter chip.
///
/// Deliberately does NOT touch the search text controller or the
/// `FilterSuggestionController` — every choice commits straight through
/// the key (`changeOp` / `addValue`), so picking a comparator or value
/// never dumps `<key>:<value>` text into the search field (the bug the
/// shared value-mode overlay had).
///
///  * [SegmentKind.comparator] — one row per `key.supportedOps`
///    (localized phrase / symbol), the current op check-marked. Tap →
///    `key.changeOp` (one VM write, value preserved).
///  * [SegmentKind.value], date key — relative presets + "Absolute
///    date →" (Material date picker). Commits the chosen value, keeping
///    the current operator.
///  * [SegmentKind.value], numeric/string key — a small autofocused
///    field prefilled with the current value; Enter commits. Edits the
///    value only — the comparator is changed via the comparator segment.
class SegmentMenu extends StatelessWidget {
  const SegmentMenu({
    required this.vm,
    required this.filterKey,
    required this.kind,
    required this.currentWire,
    required this.onClose,
    super.key,
  });

  final GenericListViewModel<dynamic> vm;
  final ComparableFilterKey filterKey;
  final SegmentKind kind;
  final String currentWire;
  final VoidCallback onClose;

  static const double _maxWidth = 280;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final (value, op) = filterKey.parseWire(currentWire);

    final Widget body;
    if (kind == SegmentKind.comparator) {
      body = _comparatorList(context, op);
    } else if (filterKey.valueType == FilterValueType.date) {
      body = _dateValueList(context, op);
    } else {
      body = _ValueField(
        initial: value,
        onSubmit: (text) {
          final t = text.trim();
          if (t.isEmpty) {
            onClose();
            return;
          }
          filterKey.addValue(vm, filterKey.buildWire(t, op));
          onClose();
        },
      );
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): onClose,
      },
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(InRadii.r2),
        color: tokens.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth, maxHeight: 360),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(InRadii.r2),
              border: Border.all(color: tokens.border),
            ),
            child: body,
          ),
        ),
      ),
    );
  }

  Widget _comparatorList(BuildContext context, FilterOp current) {
    final ops = filterKey.supportedOps;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        for (var i = 0; i < ops.length; i++)
          _MenuRow(
            autofocus: ops[i] == current,
            selected: ops[i] == current,
            label: filterOpPhrase(context, ops[i], filterKey.valueType),
            onTap: () {
              filterKey.changeOp(vm, currentWire, ops[i]);
              onClose();
            },
          ),
      ],
    );
  }

  Widget _dateValueList(BuildContext context, FilterOp op) {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        for (final (token, labelKey) in kRelativeDatePresets)
          _MenuRow(
            label: context.tr(labelKey),
            onTap: () {
              filterKey.addValue(vm, filterKey.buildWire(token, op));
              onClose();
            },
          ),
        Divider(height: 9, color: context.inTheme.border),
        _MenuRow(
          label: '${context.tr('absolute_date')}  →',
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: now,
              firstDate: DateTime(2000),
              lastDate: DateTime(now.year + 5),
            );
            if (picked != null) {
              final iso =
                  '${picked.year}-${picked.month.toString().padLeft(2, '0')}-'
                  '${picked.day.toString().padLeft(2, '0')}';
              await filterKey.addValue(vm, filterKey.buildWire(iso, op));
            }
            onClose();
          },
        ),
      ],
    );
  }
}

/// One tappable menu row — keyboard-activatable (Enter/Space when
/// focused), hover tint, optional leading ✓ for the current selection.
class _MenuRow extends StatefulWidget {
  const _MenuRow({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool autofocus;

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        autofocus: widget.autofocus,
        onTap: widget.onTap,
        child: Container(
          color: _hovered ? tokens.surfaceAlt : Colors.transparent,
          // ≥44 px row so the picker stays thumb-friendly on touch.
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: widget.selected
                    ? Icon(Icons.check, size: 16, color: tokens.ink)
                    : null,
              ),
              Expanded(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.ink,
                    fontWeight: widget.selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Numeric/string value editor — a single autofocused line, Enter
/// commits. Stays inside the popup; never writes to the search field.
class _ValueField extends StatefulWidget {
  const _ValueField({required this.initial, required this.onSubmit});

  final String initial;
  final ValueChanged<String> onSubmit;

  @override
  State<_ValueField> createState() => _ValueFieldState();
}

class _ValueFieldState extends State<_ValueField> {
  late final TextEditingController _c = TextEditingController(
    text: widget.initial,
  )..selection = TextSelection(
    baseOffset: 0,
    extentOffset: widget.initial.length,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _c,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: widget.onSubmit,
        decoration: InputDecoration(
          isDense: true,
          border: const OutlineInputBorder(),
          hintText: context.tr('change_value'),
        ),
      ),
    );
  }
}
