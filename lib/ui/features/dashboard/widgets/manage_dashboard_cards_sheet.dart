import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/dashboard/dashboard_card_config.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
import 'package:admin/ui/features/dashboard/view_models/dashboard_view_model.dart';

/// Top-bar / app-bar entry point that opens the manage-cards surface. Styled
/// identically to `DashboardSettingsButton` so the dashboard chrome reads as
/// one family.
class DashboardCardsButton extends StatelessWidget {
  const DashboardCardsButton({super.key, required this.vm});

  final DashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: tokens.ink2,
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(InRadii.r2),
          side: BorderSide(color: tokens.border),
        ),
      ),
      icon: const Icon(Icons.dashboard_customize_outlined, size: 14),
      label: Text(context.tr('cards'), style: const TextStyle(fontSize: 13)),
      onPressed: () => openManageDashboardCards(context, vm: vm),
    );
  }
}

/// Wide (≥600) → centered dialog (~720, the settings max-width convention).
/// Narrow → full-height scroll-controlled bottom sheet. Both host the same
/// live editor; mutations apply instantly (no Save gate).
Future<void> openManageDashboardCards(
  BuildContext context, {
  required DashboardViewModel vm,
}) {
  final wide = MediaQuery.sizeOf(context).width >= 600;
  if (wide) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
          child: _ManageBody(vm: vm),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.92,
      child: _ManageBody(vm: vm),
    ),
  );
}

class _ManageBody extends StatefulWidget {
  const _ManageBody({required this.vm});
  final DashboardViewModel vm;

  @override
  State<_ManageBody> createState() => _ManageBodyState();
}

class _FieldOpt {
  const _FieldOpt(this.id, this.label);
  final String id;
  final String label;
}

class _ManageBodyState extends State<_ManageBody> {
  String? _field;
  CardPeriod _period = CardPeriod.current;
  CardCalc _calc = CardCalc.sum;
  CardFormat _format = CardFormat.money;

  DashboardViewModel get vm => widget.vm;

  DashboardCardConfig? get _prospective {
    final f = _field;
    if (f == null) return null;
    final fmt = isTaskField(f) ? _format : CardFormat.money;
    return DashboardCardConfig(
      field: f,
      period: _period,
      calculate: _calc,
      format: fmt,
    );
  }

  bool get _isDuplicate {
    final p = _prospective;
    return p != null && vm.dashboardCards.any((c) => c.key == p.key);
  }

  ButtonStyle get _segStyle => SegmentedButton.styleFrom(
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 10),
  );

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final fieldOpts = [
      for (final f in kDashboardCardFields)
        _FieldOpt(f, context.tr(fieldLabelKey(f))),
    ]..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    final isTask = _field != null && isTaskField(_field!);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.all(InSpacing.lg(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('cards'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: tokens.ink,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                  tooltip: context.tr('close'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ── Add section (fixed) ──────────────────────────────────────
            SearchableDropdownField<_FieldOpt>(
              label: context.tr('field'),
              items: fieldOpts,
              initialValue: _field == null
                  ? null
                  : fieldOpts.firstWhere((o) => o.id == _field),
              displayString: (o) => o.label,
              idOf: (o) => o.id,
              emptyHintKey: 'no_records_found',
              onChanged: (o) => setState(() {
                _field = o?.id;
                if (_field == null || !isTaskField(_field!)) {
                  _format = CardFormat.money;
                }
              }),
            ),
            SizedBox(height: InSpacing.md(context)),
            _segRow<CardPeriod>(
              context.tr('period'),
              CardPeriod.values,
              _period,
              (v) => setState(() => _period = v),
              (v) => context.tr(switch (v) {
                CardPeriod.current => 'current_period',
                CardPeriod.previous => 'previous_period',
                CardPeriod.total => 'total',
              }),
            ),
            SizedBox(height: InSpacing.md(context)),
            _segRow<CardCalc>(
              context.tr('calculate'),
              CardCalc.values,
              _calc,
              (v) => setState(() => _calc = v),
              (v) => context.tr(switch (v) {
                CardCalc.sum => 'sum',
                CardCalc.avg => 'average',
                CardCalc.count => 'count',
              }),
            ),
            if (isTask) ...[
              SizedBox(height: InSpacing.md(context)),
              _segRow<CardFormat>(
                context.tr('format'),
                CardFormat.values,
                _format,
                (v) => setState(() => _format = v),
                (v) => context.tr(v.name),
              ),
            ],
            if (_isDuplicate) ...[
              SizedBox(height: InSpacing.md(context)),
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: tokens.overdue,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      context.tr('card_already_exists'),
                      style: TextStyle(fontSize: 12, color: tokens.ink3),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: InSpacing.md(context)),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, 40),
                ),
                onPressed: (_field == null || _isDuplicate)
                    ? null
                    : () {
                        vm.addCard(_prospective!);
                        setState(() {});
                      },
                child: Text(context.tr('add')),
              ),
            ),
            const Divider(height: 24),
            // ── Current cards (scrollable) ───────────────────────────────
            Flexible(
              child: ListenableBuilder(
                listenable: vm,
                builder: (context, _) {
                  if (vm.dashboardCards.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: InSpacing.lg(context),
                      ),
                      child: Text(
                        context.tr('no_records_found'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: tokens.ink3, fontSize: 12),
                      ),
                    );
                  }
                  return ReorderableListView.builder(
                    shrinkWrap: true,
                    buildDefaultDragHandles: false,
                    itemCount: vm.dashboardCards.length,
                    onReorder: vm.reorderCards,
                    itemBuilder: (context, i) {
                      final c = vm.dashboardCards[i];
                      return _CardRow(
                        key: ValueKey(c.key),
                        index: i,
                        title: context.tr(fieldLabelKey(c.field)),
                        subtitle:
                            '${context.tr(switch (c.period) {
                              CardPeriod.current => 'current_period',
                              CardPeriod.previous => 'previous_period',
                              CardPeriod.total => 'total',
                            })} · ${context.tr(switch (c.calculate) {
                              CardCalc.sum => 'sum',
                              CardCalc.avg => 'average',
                              CardCalc.count => 'count',
                            })}',
                        onRemove: () => vm.removeCard(c.key),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segRow<T>(
    String label,
    List<T> values,
    T selected,
    ValueChanged<T> onChange,
    String Function(T) labelOf,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: context.inTheme.ink3),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<T>(
              showSelectedIcon: false,
              style: _segStyle,
              segments: [
                for (final v in values)
                  ButtonSegment<T>(
                    value: v,
                    label: Text(
                      labelOf(v),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
              selected: {selected},
              onSelectionChanged: (s) => onChange(s.first),
            ),
          ),
        ),
      ],
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({
    super.key,
    required this.index,
    required this.title,
    required this.subtitle,
    required this.onRemove,
  });

  final int index;
  final String title;
  final String subtitle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: InSpacing.xs),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Icon(Icons.drag_indicator, color: tokens.ink3, size: 20),
          ),
          SizedBox(width: InSpacing.md(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: tokens.ink3),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            iconSize: 18,
            tooltip: context.tr('remove'),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
