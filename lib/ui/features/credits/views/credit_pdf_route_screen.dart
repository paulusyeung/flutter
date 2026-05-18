import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/credit.dart';
import 'package:admin/ui/features/billing_shared/billing_doc_type.dart';
import 'package:admin/ui/features/billing_shared/pdf/billing_doc_pdf_screen.dart';

/// Route wrapper for `/credits/:id/pdf`. Mirrors `QuotePdfRouteScreen`.
class CreditPdfRouteScreen extends StatefulWidget {
  const CreditPdfRouteScreen({super.key, required this.id});
  final String id;

  @override
  State<CreditPdfRouteScreen> createState() => _CreditPdfRouteScreenState();
}

class _CreditPdfRouteScreenState extends State<CreditPdfRouteScreen> {
  late final Services _services;
  late final Stream<Credit?> _stream;
  late final String _companyId;

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    _companyId = _services.auth.session.value!.currentCompanyId;
    _stream = _services.credits.watch(companyId: _companyId, id: widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Credit?>(
      stream: _stream,
      builder: (context, snapshot) {
        final credit = snapshot.data;
        if (credit == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return BillingDocPdfScreen(
          entity: BillingDocType.credit,
          entityNumber: credit.number,
          fetcher: ({String? designId, required bool deliveryNote}) =>
              _services.credits.api.downloadPdf(
            entityJson: credit.toApiJson(),
            designId: designId ??
                (credit.designId.isEmpty ? null : credit.designId),
          ),
        );
      },
    );
  }
}
