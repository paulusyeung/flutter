import 'package:flutter/material.dart';

import 'package:admin/ui/features/settings/views/advanced/e_invoice/e_invoice_body.dart';
import 'package:admin/ui/features/settings/views/advanced/e_invoice/e_invoice_view_model.dart';
import 'package:admin/ui/features/settings/widgets/cascade_settings_scaffold.dart';

/// Settings → E-Invoice. Cascade-aware (company / group / client) — the
/// scaffold swaps to the shared `ClientSettingsDraftViewModel` at non-company
/// scope; per-page customization lives in [EInvoiceViewModel] (a one-line
/// subclass of `SettingsDraftViewModel`).
///
/// The page hosts the cascade-friendly fields (type, enable, merge-to-PDF,
/// quote type, forward emails, skip-automatic-email) plus company-only
/// blocks (certificate, PEPPOL, payment means, tax identifiers) that gate
/// themselves with `scope.isCompany` inside the body.
class EInvoiceScreen extends StatelessWidget {
  const EInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CascadeSettingsScaffold(
      titleKey: 'e_invoice',
      companyVmFactory: ({required repo, required companyId}) =>
          EInvoiceViewModel(repo: repo, companyId: companyId),
      body: const EInvoiceBody(),
    );
  }
}
