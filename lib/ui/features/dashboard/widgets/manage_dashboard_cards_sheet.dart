import 'dart:async';

import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/dashboard/dashboard_card_config.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
import 'package:admin/ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:admin/ui/features/dashboard/widgets/delta_chip.dart';
import 'package:admin/ui/features/dashboard/widgets/kpi_card.dart';

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

/// Wide (≥600) → centered dialog (~720, the settings max-width convention),
/// two columns (compose | current). Narrow → full-height scroll-controlled
/// bottom sheet, single column. Both host the same live editor; mutations
/// apply instantly (no Save gate).
Future<void> openManageDashboardCards(
  BuildContext context, {
  required DashboardViewModel vm,
}) {
  final wide = MediaQuery.sizeOf(context).width >= 600;
  if (wide) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
          child: _ManageBody(vm: vm, twoColumn: true),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.92,
      child: _ManageBody(vm: vm, twoColumn: false),
    ),
  );
}

class _ManageBody extends StatefulWidget {
  const _ManageBody({required this.vm, required this.twoColumn});
  final DashboardViewModel vm;
  final bool twoColumn;

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

  /// Key of the just-added card — drives the scroll-to + brief highlight.
  String? _recentlyAddedKey;
  Timer? _flashTimer;
  final GlobalKey _newRowKey = GlobalKey();
  final ScrollController _listScroll = ScrollController();

  DashboardViewModel get vm => widget.vm;

  @override
  void dispose() {
    _flashTimer?.cancel();
    _listScroll.dispose();
    super.dispose();
  }

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

  String _periodLabel(CardPeriod p) => switch (p) {
    CardPeriod.current => 'current',
    CardPeriod.previous => 'previous',
    CardPeriod.total => 'total',
  };

  String _calcLabel(CardCalc c) => switch (c) {
    CardCalc.sum => 'sum',
    CardCalc.avg => 'average',
    CardCalc.count => 'count',
  };

  void _onAdd() {
    final p = _prospective;
    if (p == null) return;
    vm.addCard(p);
    _recentlyAddedKey = p.key;
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _recentlyAddedKey = null);
    });
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _newRowKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 250),
          alignment: 0.5,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fieldOpts = [
      for (final f in kDashboardCardFields)
        _FieldOpt(f, context.tr(fieldLabelKey(f))),
    ]..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.all(InSpacing.lg(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context),
            SizedBox(height: InSpacing.md(context)),
            if (widget.twoColumn)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: _composePane(context, fieldOpts),
                      ),
                    ),
                    SizedBox(width: InSpacing.lg(context)),
                    Expanded(child: _currentPane(context)),
                  ],
                ),
              )
            else ...[
              Flexible(
                child: SingleChildScrollView(
                  child: _composePane(context, fieldOpts),
                ),
              ),
              SizedBox(height: InSpacing.lg(context)),
              Flexible(child: _currentPane(context)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final tokens = context.inTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            context.tr('cards'),
            style: TextStyle(
              fontSize: 16,
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
    );
  }

  // ── Compose pane ──────────────────────────────────────────────────────

  Widget _composePane(BuildContext context, List<_FieldOpt> fieldOpts) {
    final isTask = _field != null && isTaskField(_field!);
    _FieldOpt? selected;
    for (final o in fieldOpts) {
      if (o.id == _field) {
        selected = o;
        break;
      }
    }
    return _PaneCard(
      title: context.tr('add'),
      child: Padding(
        padding: EdgeInsets.all(InSpacing.lg(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SearchableDropdownField<_FieldOpt>(
              label: context.tr('field'),
              items: fieldOpts,
              initialValue: selected,
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
            _LabeledControl(
              label: context.tr('period'),
              child: _seg<CardPeriod>(
                CardPeriod.values,
                _period,
                (v) => setState(() => _period = v),
                (v) => context.tr(_periodLabel(v)),
              ),
            ),
            SizedBox(height: InSpacing.md(context)),
            _LabeledControl(
              label: context.tr('calculate'),
              child: _seg<CardCalc>(
                CardCalc.values,
                _calc,
                (v) => setState(() => _calc = v),
                (v) => context.tr(_calcLabel(v)),
              ),
            ),
            if (isTask) ...[
              SizedBox(height: InSpacing.md(context)),
              _LabeledControl(
                label: context.tr('format'),
                child: _seg<CardFormat>(
                  CardFormat.values,
                  _format,
                  (v) => setState(() => _format = v),
                  (v) => context.tr(v.name),
                ),
              ),
            ],
            SizedBox(height: InSpacing.lg(context)),
            _LabeledControl(
              label: context.tr('preview'),
              child: SizedBox(height: 140, child: _preview(context)),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 150),
              alignment: Alignment.topCenter,
              child: _isDuplicate
                  ? Padding(
                      padding: EdgeInsets.only(top: InSpacing.md(context)),
                      child: _duplicateWarning(context),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            SizedBox(height: InSpacing.lg(context)),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
              onPressed: (_field == null || _isDuplicate) ? null : _onAdd,
              child: Text(context.tr('add')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview(BuildContext context) {
    if (_field == null) {
      final tokens = context.inTheme;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surfaceAlt,
          borderRadius: BorderRadius.circular(InRadii.r3),
          border: Border.all(color: tokens.border),
        ),
        child: Center(
          child: Text(
            context.tr('field'),
            style: TextStyle(color: tokens.ink3, fontSize: 12),
          ),
        ),
      );
    }
    return KpiCard(
      label: context.tr(fieldLabelKey(_field!)),
      value: '—',
      deltaPercent: null,
      goodDirection: GoodDirection.up,
      showDelta: false,
      subcaption:
          '${context.tr(_periodLabel(_period))} · '
          '${context.tr(_calcLabel(_calc))}',
    );
  }

  Widget _duplicateWarning(BuildContext context) {
    final tokens = context.inTheme;
    return Row(
      children: [
        Icon(Icons.warning_amber_rounded, size: 16, color: tokens.overdue),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            context.tr('card_already_exists'),
            style: TextStyle(fontSize: 12, color: tokens.ink3),
          ),
        ),
      ],
    );
  }

  // ── Current pane ──────────────────────────────────────────────────────

  Widget _currentPane(BuildContext context) {
    final tokens = context.inTheme;
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final cards = vm.dashboardCards;
        return _PaneCard(
          title: context.tr('cards'),
          fill: true,
          trailing: cards.isEmpty
              ? null
              : Text(
                  '${cards.length}',
                  style: TextStyle(fontSize: 12, color: tokens.ink3),
                ),
          child: cards.isEmpty
              ? EmptyState(
                  icon: Icons.dashboard_customize_outlined,
                  title: context.tr('no_records_found'),
                  subtitle: context.tr('add_dashboard_cards'),
                )
              : ReorderableListView.builder(
                  scrollController: _listScroll,
                  padding: EdgeInsets.symmetric(
                    horizontal: InSpacing.lg(context),
                    vertical: InSpacing.md(context),
                  ),
                  buildDefaultDragHandles: false,
                  itemCount: cards.length,
                  onReorderItem: vm.reorderCards,
                  itemBuilder: (context, i) {
                    final c = cards[i];
                    final highlighted = c.key == _recentlyAddedKey;
                    return _CardRow(
                      key: ValueKey(c.key),
                      rowKey: highlighted ? _newRowKey : null,
                      highlighted: highlighted,
                      index: i,
                      title: context.tr(fieldLabelKey(c.field)),
                      subtitle:
                          '${context.tr(_periodLabel(c.period))} · '
                          '${context.tr(_calcLabel(c.calculate))}',
                      onRemove: () => vm.removeCard(c.key),
                    );
                  },
                ),
        );
      },
    );
  }

  // ── Shared bits ───────────────────────────────────────────────────────

  Widget _seg<T>(
    List<T> values,
    T selected,
    ValueChanged<T> onChange,
    String Function(T) labelOf,
  ) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<T>(
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        segments: [
          for (final v in values)
            ButtonSegment<T>(
              value: v,
              label: Text(labelOf(v), style: const TextStyle(fontSize: 12)),
            ),
        ],
        selected: {selected},
        onSelectionChanged: (s) => onChange(s.first),
      ),
    );
  }
}

/// FormSection-style chrome (surface + 1px border + r3, header + divider)
/// whose body fills the remaining height — lets the current-cards list get
/// a bounded height for its own scroll/reorder.
class _PaneCard extends StatelessWidget {
  const _PaneCard({
    required this.title,
    required this.child,
    this.trailing,
    this.fill = false,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  /// When true the body fills remaining height (`Flexible`) so an inner
  /// scrollable/list gets bounded constraints — used by the current-cards
  /// pane. The compose pane sizes to content and is scrolled by an outer
  /// `SingleChildScrollView`, so it must stay `fill: false`.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.inTheme;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(InRadii.r3),
        border: Border.all(color: tokens.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: InSpacing.lg(context),
              vertical: InSpacing.md(context),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: tokens.ink,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Divider(height: 1, color: tokens.border),
          if (fill) Flexible(child: child) else child,
        ],
      ),
    );
  }
}

class _LabeledControl extends StatelessWidget {
  const _LabeledControl({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: tokens.ink3)),
        const SizedBox(height: 6),
        child,
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
    this.rowKey,
    this.highlighted = false,
  });

  final int index;
  final String title;
  final String subtitle;
  final VoidCallback onRemove;
  final Key? rowKey;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return AnimatedContainer(
      key: rowKey,
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: highlighted ? tokens.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(InRadii.r1),
      ),
      padding: EdgeInsets.symmetric(
        vertical: InSpacing.xs,
        horizontal: InSpacing.xs,
      ),
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
                Text(title, style: Theme.of(context).textTheme.bodyMedium),
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
