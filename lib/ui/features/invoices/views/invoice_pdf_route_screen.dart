import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/ui/features/billing_shared/billing_doc_type.dart';
import 'package:admin/ui/features/billing_shared/pdf/billing_doc_pdf_screen.dart';

/// Route wrapper for `/invoices/:id/pdf`. Watches the invoice (to pick up
/// the latest number / design after a save round-trips) and renders the
/// shared [BillingDocPdfScreen] with a fetcher closure that hits the
/// `/api/v1/preview` endpoint via [InvoicesApi.downloadPdf].
class InvoicePdfRouteScreen extends StatefulWidget {
  const InvoicePdfRouteScreen({super.key, required this.id});
  final String id;

  @override
  State<InvoicePdfRouteScreen> createState() => _InvoicePdfRouteScreenState();
}

class _InvoicePdfRouteScreenState extends State<InvoicePdfRouteScreen> {
  late final Services _services;
  late final Stream<Invoice?> _stream;
  late final String _companyId;

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    _companyId = _services.auth.session.value!.currentCompanyId;
    _stream = _services.invoices.watch(companyId: _companyId, id: widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Invoice?>(
      stream: _stream,
      builder: (context, snapshot) {
        final invoice = snapshot.data;
        if (invoice == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return BillingDocPdfScreen(
          entity: BillingDocType.invoice,
          entityNumber: invoice.number,
          fetcher: ({String? designId, required bool deliveryNote}) =>
              _services.invoices.api.downloadPdf(
                id: invoice.id,
                designId: designId ??
                    (invoice.designId.isEmpty ? null : invoice.designId),
                deliveryNote: deliveryNote,
              ),
        );
      },
    );
  }
}
