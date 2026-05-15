import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company_gateway.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/entity_actions_popup_button.dart';
import 'package:admin/ui/core/list/entity_list_constants.dart';
import 'package:admin/ui/core/widgets/cell_copy_hover.dart';
import 'package:admin/ui/features/gateways/widgets/gateway_logo.dart';
import 'package:admin/ui/core/widgets/leading_select_slot.dart';
import 'package:admin/ui/core/widgets/status_pill.dart';
import 'package:admin/ui/features/gateways/widgets/company_gateway_actions.dart';

/// One row in the company-gateways list.
///
/// Wide-mode mirrors `ProjectListTile`'s anatomy — leading actions slot,
/// avatar/checkbox slot, column cells, status-pill slot. Narrow-mode stacks
/// label + provider type. Gateway uses a "Test" pill when `testMode` is on;
/// the standard archived/deleted state is rendered by the column cells
/// elsewhere.
class CompanyGatewayListTile extends StatelessWidget {
  const CompanyGatewayListTile({
    super.key,
    required this.gateway,
    required this.columns,
    required this.onTap,
    this.wide = true,
    this.onAction,
    this.onSelectTap,
    this.onLongPress,
    this.selected = false,
    this.urlSelected = false,
    this.selecting = false,
    this.isLast = false,
  });

  final CompanyGateway gateway;
  final List<ColumnDefinition<CompanyGateway>> columns;
  final VoidCallback onTap;
  final bool wide;
  final ValueChanged<CompanyGatewayAction>? onAction;
  final VoidCallback? onSelectTap;
  final VoidCallback? onLongPress;
  final bool selected;

  /// True when this row matches the URL's `:id` (active in master-detail
  /// split view). Distinct from [selected] (multi-select) so the tile
  /// can render an unmistakable accent stripe on the left edge for
  /// URL-active rows without conflating with the bulk-select chip.
  final bool urlSelected;
  final bool selecting;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return InkWell(
      onTap: selecting ? onSelectTap : onTap,
      onLongPress: onLongPress,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? tokens.accentSoft : null,
          border: BorderDirectional(
            start: urlSelected
                ? BorderSide(color: tokens.accent, width: 3)
                : BorderSide.none,
            bottom: isLast ? BorderSide.none : BorderSide(color: tokens.border),
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 10),
          child: wide ? _wide(context, tokens) : _narrow(context, tokens),
        ),
      ),
    );
  }

  Widget _wide(BuildContext context, InTheme tokens) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: kColWMoreMenu,
          child: (onAction == null || selecting)
              ? const SizedBox.shrink()
              : EntityActionsPopupButton<CompanyGatewayAction>(
                  icon: Icons.more_horiz,
                  items: CompanyGatewayActions.itemsFor(
                    context,
                    gateway,
                    onAction!,
                  ),
                ),
        ),
        const SizedBox(width: kColCellGap),
        _leading(),
        const SizedBox(width: kColCellGap),
        for (final col in columns) ...[
          _CellSlot(
            column: col,
            gateway: gateway,
            child: col.cellBuilder(gateway, context),
          ),
          const SizedBox(width: kColCellGap),
        ],
        SizedBox(width: kColWPillSlot, child: _statusPill(context)),
      ],
    );
  }

  Widget _narrow(BuildContext context, InTheme tokens) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _leading(),
        const SizedBox(width: 12),
        Expanded(child: _identity(context, tokens)),
        const SizedBox(width: 8),
        _statusPill(context),
        if (onAction != null && !selecting) ...[
          const SizedBox(width: 4),
          EntityActionsPopupButton<CompanyGatewayAction>(
            icon: Icons.more_horiz,
            items: CompanyGatewayActions.itemsFor(context, gateway, onAction!),
          ),
        ],
      ],
    );
  }

  Widget _identity(BuildContext context, InTheme tokens) {
    final providerName = _providerName(context);
    final display = gateway.resolveDisplayName(gatewayName: providerName);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          display,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (providerName != null && display != providerName) ...[
          const SizedBox(height: 2),
          Text(
            providerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: tokens.ink3, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _leading() {
    return LeadingSelectSlot(
      selecting: selecting,
      selected: selected,
      onSelectTap: onSelectTap,
      defaultChild: GatewayLogo(gatewayKey: gateway.gatewayKey, size: 24),
    );
  }

  /// Test-mode pill takes priority. Otherwise no pill — archived/deleted
  /// state is conveyed by the column cells and the row treatment.
  Widget _statusPill(BuildContext context) {
    if (!gateway.testMode) return const SizedBox.shrink();
    final tokens = context.inTheme;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: StatusPill(
        label: context.tr('test'),
        fgColor: tokens.sent,
        bgColor: tokens.sentSoft,
      ),
    );
  }

  String? _providerName(BuildContext context) {
    if (gateway.gatewayKey.isEmpty) return null;
    final statics = context.read<Services>().statics;
    return statics.gateway(gateway.gatewayKey)?.name;
  }
}

class _CellSlot extends StatelessWidget {
  const _CellSlot({
    required this.column,
    required this.gateway,
    required this.child,
  });
  final ColumnDefinition<CompanyGateway> column;
  final CompanyGateway gateway;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final aligned = Align(
      alignment: column.align == ColumnAlign.end
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: child,
    );
    final cell = CellCopyHover(
      value: column.valueBuilder?.call(gateway),
      align: column.align,
      child: aligned,
    );
    if (column.isFlex) return Expanded(child: cell);
    return SizedBox(width: column.width, child: cell);
  }
}
