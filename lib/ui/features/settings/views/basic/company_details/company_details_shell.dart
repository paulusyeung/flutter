import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/ui/features/settings/view_models/company_details_view_model.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/address_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/company_details_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/custom_fields_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/defaults_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/documents_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/logo_screen.dart';
import 'package:admin/ui/features/settings/widgets/tabbed_settings_shell.dart';

/// Company Details — 6 tabs (Details, Address, Logo, Defaults, Documents,
/// Custom Fields) hosted by the generic [TabbedSettingsShell]. The only
/// piece that's specific to this screen is the statics warm-up — Size and
/// Industry dropdowns on the Details tab depend on `Services.statics`,
/// which is normally warmed at boot but can be cold on a fresh login that
/// lands here before the first `/api/v1/statics` fetch finishes.
class CompanyDetailsShell extends StatelessWidget {
  const CompanyDetailsShell({super.key, this.initialTab});

  /// The `:tab` path parameter from the route, or null when on the parent
  /// `/settings/company_details` URL (defaults to the Details tab).
  final String? initialTab;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return _StaticsWarmer(
      child: TabbedSettingsShell<CompanyDetailsViewModel>(
        titleKey: 'company_details',
        basePath: '/settings/company_details',
        initialTab: initialTab,
        companyVmFactory: (companyId) => CompanyDetailsViewModel(
          repo: services.company,
          companyId: companyId,
        ),
        tabs: [
          TabbedSettingsTab(
            slug: '',
            labelKey: 'details',
            body: CompanyDetailsScreen(),
          ),
          TabbedSettingsTab(
            slug: 'address',
            labelKey: 'address',
            body: CompanyDetailsAddressScreen(),
          ),
          TabbedSettingsTab(
            slug: 'logo',
            labelKey: 'logo',
            body: CompanyDetailsLogoScreen(),
          ),
          TabbedSettingsTab(
            slug: 'defaults',
            labelKey: 'defaults',
            body: CompanyDetailsDefaultsScreen(),
          ),
          TabbedSettingsTab(
            slug: 'documents',
            labelKey: 'documents',
            body: CompanyDetailsDocumentsScreen(),
          ),
          TabbedSettingsTab(
            slug: 'custom_fields',
            labelKey: 'custom_fields',
            body: CompanyDetailsCustomFieldsScreen(),
          ),
        ],
      ),
    );
  }
}

/// `main.dart` warms statics at boot, but a fresh login that lands directly
/// on this screen before the first /api/v1/statics fetch finishes would see
/// empty Size + Industry maps on the Details tab. Plain `ensureLoaded()`
/// (no force) reads from the Drift cache when available and only hits the
/// network when the cache is stale or absent; the `setState(() {})` on
/// completion forces a rebuild so the dropdowns re-read `Services.statics`.
class _StaticsWarmer extends StatefulWidget {
  const _StaticsWarmer({required this.child});

  final Widget child;

  @override
  State<_StaticsWarmer> createState() => _StaticsWarmerState();
}

class _StaticsWarmerState extends State<_StaticsWarmer> {
  @override
  void initState() {
    super.initState();
    final statics = context.read<Services>().statics;
    if (statics.sizes.isEmpty || statics.industries.isEmpty) {
      statics.ensureLoaded().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
