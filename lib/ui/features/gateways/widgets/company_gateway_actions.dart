import 'package:flutter/material.dart';

import 'package:admin/app/router.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company_gateway.dart';
import 'package:admin/domain/gateway_constants.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/detail/standard_entity_action_items.dart';
import 'package:admin/ui/core/detail/standard_entity_actions.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/core/widgets/notify_async.dart';

/// Action set surfaced for a company gateway. Mirrors `ProjectAction` —
/// edit / archive / restore / delete are wired today; `disconnect`
/// (Stripe Connect) lands in Phase 2.
enum CompanyGatewayAction {
  edit,
  disconnect,
  importCustomers,
  verifyCustomers,
  archive,
  restore,
  delete,
}

class CompanyGatewayActions {
  CompanyGatewayActions._();

  /// Actions the old admin-portal hid on a brand-new (unsaved) record.
  /// Fed to `filterForEditScreen` so the create screen drops archive /
  /// restore / delete.
  static bool isLifecycle(CompanyGatewayAction action) {
    switch (action) {
      case CompanyGatewayAction.archive:
      case CompanyGatewayAction.restore:
      case CompanyGatewayAction.delete:
        return true;
      default:
        return false;
    }
  }

  static List<EntityActionItem<CompanyGatewayAction>> itemsFor(
    BuildContext context,
    CompanyGateway gateway,
    void Function(CompanyGatewayAction) onTap,
  ) {
    final canArchive = gateway.archivedAt == 0 && !gateway.isDeleted;
    final canRestore = gateway.archivedAt != 0 || gateway.isDeleted;

    final isStripeConnect = gateway.gatewayKey == kGatewayStripeConnect;
    final isAnyStripe =
        gateway.gatewayKey == kGatewayStripe ||
        gateway.gatewayKey == kGatewayStripeConnect;
    return [
      editActionItem(
        context: context,
        kind: CompanyGatewayAction.edit,
        onTap: () => onTap(CompanyGatewayAction.edit),
      ),
      if (isStripeConnect)
        EntityActionItem(
          kind: CompanyGatewayAction.disconnect,
          icon: Icons.link_off_outlined,
          label: context.tr('disconnect'),
          enabled: true,
          onTap: () => onTap(CompanyGatewayAction.disconnect),
        ),
      if (isAnyStripe) ...[
        EntityActionItem(
          kind: CompanyGatewayAction.importCustomers,
          icon: Icons.cloud_download_outlined,
          label: context.tr('import_customers'),
          enabled: true,
          onTap: () => onTap(CompanyGatewayAction.importCustomers),
        ),
        EntityActionItem(
          kind: CompanyGatewayAction.verifyCustomers,
          icon: Icons.fact_check_outlined,
          label: context.tr('verify_customers'),
          enabled: true,
          onTap: () => onTap(CompanyGatewayAction.verifyCustomers),
        ),
      ],
      ?archiveActionItem(
        context: context,
        kind: CompanyGatewayAction.archive,
        canArchive: canArchive,
        onTap: () => onTap(CompanyGatewayAction.archive),
      ),
      ?restoreActionItem(
        context: context,
        kind: CompanyGatewayAction.restore,
        canRestore: canRestore,
        onTap: () => onTap(CompanyGatewayAction.restore),
      ),
      ?deleteActionItem(
        context: context,
        kind: CompanyGatewayAction.delete,
        canDelete: !gateway.isDeleted,
        onTap: () => onTap(CompanyGatewayAction.delete),
      ),
    ];
  }

  static Future<void> dispatch(
    BuildContext context,
    Services services,
    String companyId,
    CompanyGateway gateway,
    CompanyGatewayAction action,
  ) async {
    switch (action) {
      case CompanyGatewayAction.edit:
        goEntityEdit(context, '/settings/company_gateways', gateway.id);
      case CompanyGatewayAction.disconnect:
        await runMutationWithNotify(
          context,
          () => services.companyGateways.disconnectStripe(id: gateway.id),
          successMsg: context.tr('disconnected_gateway'),
        );
      case CompanyGatewayAction.importCustomers:
        await runMutationWithNotify(
          context,
          () => services.companyGateways.importStripeCustomers(id: gateway.id),
          successMsg: context.tr('imported_customers'),
        );
      case CompanyGatewayAction.verifyCustomers:
        try {
          final counts = await services.companyGateways.verifyStripeCustomers();
          if (!context.mounted) return;
          await _showVerifyCustomersDialog(context, counts);
        } catch (e) {
          if (context.mounted) Notify.error(context, e.toString());
        }
      case CompanyGatewayAction.archive:
        await StandardEntityActions.archive(
          context: context,
          wireName: 'company_gateway',
          op: () => services.companyGateways.archive(
            companyId: companyId,
            id: gateway.id,
          ),
        );
      case CompanyGatewayAction.restore:
        await StandardEntityActions.restore(
          context: context,
          wireName: 'company_gateway',
          op: () => services.companyGateways.restore(
            companyId: companyId,
            id: gateway.id,
          ),
        );
      case CompanyGatewayAction.delete:
        if (gateway.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        await StandardEntityActions.delete(
          context: context,
          wireName: 'company_gateway',
          op: () => services.companyGateways.delete(
            companyId: companyId,
            id: gateway.id,
          ),
        );
    }
  }

  static Future<void> _showVerifyCustomersDialog(
    BuildContext context,
    ({int stripeCount, int localCount}) counts,
  ) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('customer_count')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CountRow(label: 'Stripe', value: counts.stripeCount),
            const SizedBox(height: 8),
            _CountRow(label: 'Invoice Ninja', value: counts.localCount),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.tr('close')),
          ),
        ],
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(label)),
        SizedBox(width: 100, child: Text('$value', textAlign: TextAlign.end)),
      ],
    );
  }
}
