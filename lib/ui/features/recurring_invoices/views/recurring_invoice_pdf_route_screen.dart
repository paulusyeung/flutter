import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/recurring_invoice.dart';
import 'package:admin/ui/features/billing_shared/billing_doc_type.dart';
import 'package:admin/ui/features/billing_shared/pdf/billing_doc_pdf_screen.dart';

/// Route wrapper for `/recurring_invoices/:id/pdf`. Mirrors
/// `PurchaseOrderPdfRouteScreen`.
class RecurringInvoicePdfRouteScreen extends StatefulWidget {
  const RecurringInvoicePdfRouteScreen({super.key, required this.id});
  final String id;

  @override
  State<RecurringInvoicePdfRouteScreen> createState() =>
      _RecurringInvoicePdfRouteScreenState();
}

class _RecurringInvoicePdfRouteScreenState
    extends State<RecurringInvoicePdfRouteScreen> {
  late final Services _services;
  late final Stream<RecurringInvoice?> _stream;
  late final String _companyId;

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    _companyId = _services.auth.session.value!.currentCompanyId;
    _stream = _services.recurringInvoices.watch(
      companyId: _companyId,
      id: widget.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RecurringInvoice?>(
      stream: _stream,
      builder: (context, snapshot) {
        final ri = snapshot.data;
        if (ri == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return BillingDocPdfScreen(
          entity: BillingDocType.recurringInvoice,
          entityNumber: ri.number,
          fetcher: ({String? designId, required bool deliveryNote}) =>
              _services.recurringInvoices.api.downloadPdf(
                entityJson: ri.toApiJson(),
                designId:
                    designId ?? (ri.designId.isEmpty ? null : ri.designId),
              ),
        );
      },
    );
  }
}
