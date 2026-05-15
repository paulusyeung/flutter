import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/quote.dart';
import 'package:admin/ui/features/billing_shared/billing_doc_type.dart';
import 'package:admin/ui/features/billing_shared/pdf/billing_doc_pdf_screen.dart';

/// Route wrapper for `/quotes/:id/pdf`. Mirrors `InvoicePdfRouteScreen`.
class QuotePdfRouteScreen extends StatefulWidget {
  const QuotePdfRouteScreen({super.key, required this.id});
  final String id;

  @override
  State<QuotePdfRouteScreen> createState() => _QuotePdfRouteScreenState();
}

class _QuotePdfRouteScreenState extends State<QuotePdfRouteScreen> {
  late final Services _services;
  late final Stream<Quote?> _stream;
  late final String _companyId;

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    _companyId = _services.auth.session.value!.currentCompanyId;
    _stream = _services.quotes.watch(companyId: _companyId, id: widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Quote?>(
      stream: _stream,
      builder: (context, snapshot) {
        final quote = snapshot.data;
        if (quote == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return BillingDocPdfScreen(
          entity: BillingDocType.quote,
          entityNumber: quote.number,
          fetcher: ({String? designId, required bool deliveryNote}) =>
              _services.quotes.api.downloadPdf(
            id: quote.id,
            designId: designId ??
                (quote.designId.isEmpty ? null : quote.designId),
          ),
        );
      },
    );
  }
}
