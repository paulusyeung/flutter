import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/purchase_order.dart';
import 'package:admin/ui/features/billing_shared/billing_doc_type.dart';
import 'package:admin/ui/features/billing_shared/pdf/billing_doc_pdf_screen.dart';

/// Route wrapper for `/purchase_orders/:id/pdf`. Mirrors
/// `CreditPdfRouteScreen`.
class PurchaseOrderPdfRouteScreen extends StatefulWidget {
  const PurchaseOrderPdfRouteScreen({super.key, required this.id});
  final String id;

  @override
  State<PurchaseOrderPdfRouteScreen> createState() =>
      _PurchaseOrderPdfRouteScreenState();
}

class _PurchaseOrderPdfRouteScreenState
    extends State<PurchaseOrderPdfRouteScreen> {
  late final Services _services;
  late final Stream<PurchaseOrder?> _stream;
  late final String _companyId;

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    _companyId = _services.auth.session.value!.currentCompanyId;
    _stream = _services.purchaseOrders.watch(
      companyId: _companyId,
      id: widget.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PurchaseOrder?>(
      stream: _stream,
      builder: (context, snapshot) {
        final po = snapshot.data;
        if (po == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return BillingDocPdfScreen(
          entity: BillingDocType.purchaseOrder,
          entityNumber: po.number,
          fetcher: ({String? designId, required bool deliveryNote}) =>
              _services.purchaseOrders.api.downloadPdf(
                entityJson: po.toApiJson(),
                designId:
                    designId ?? (po.designId.isEmpty ? null : po.designId),
              ),
        );
      },
    );
  }
}
