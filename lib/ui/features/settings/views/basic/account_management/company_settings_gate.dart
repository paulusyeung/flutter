import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';

/// Gate for an Account-Management settings body that PUTs the WHOLE company
/// row (Enabled Modules / Security / Overview / Analytics). The login envelope
/// omits ~29 server-only company columns (SMTP / expense / task-invoicing /
/// payment conversion), so the cached row carries table defaults for them; a
/// toggle saved before the canonical `GET /companies/{id}` lands — or while
/// offline, where it never lands — would ship those defaults and clobber the
/// server's real settings.
///
/// This rebuilds on [CompanyRepository.canonicalFetched] and hands the body a
/// `ready` flag: the screen disables its whole-company controls (and shows a
/// [CompanySettingsLockedBanner]) until the canonical row is in Drift. The
/// caller is responsible for triggering the fetch (`services.company.refresh`,
/// which the Account-Management shell already does on mount; standalone pages
/// like Analytics do it themselves).
class CompanySettingsGate extends StatelessWidget {
  const CompanySettingsGate({
    required this.companyId,
    required this.builder,
    super.key,
  });

  final String companyId;

  /// Builds the body. [ready] is true once the canonical company has been
  /// fetched this session — gate every `updateCompany`-driven control's
  /// `onChanged`/`onPressed` on it.
  final Widget Function(BuildContext context, bool ready) builder;

  @override
  Widget build(BuildContext context) {
    final company = context.read<Services>().company;
    return ValueListenableBuilder<Set<String>>(
      valueListenable: company.canonicalFetched,
      builder: (context, fetched, _) =>
          builder(context, fetched.contains(companyId)),
    );
  }
}

/// Notice shown atop a gated Account-Management body while editing is locked
/// (see [CompanySettingsGate]). Drop it in as the first `SettingsFormShell`
/// section when `!ready`.
class CompanySettingsLockedBanner extends StatelessWidget {
  const CompanySettingsLockedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      padding: EdgeInsets.all(InSpacing.lg(context)),
      decoration: BoxDecoration(
        color: tokens.sentSoft,
        borderRadius: BorderRadius.circular(InRadii.r3),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: tokens.sent,
            ),
          ),
          SizedBox(width: InSpacing.md(context)),
          Expanded(
            child: Text(
              context.tr('account_settings_syncing_notice'),
              style: TextStyle(color: tokens.ink2),
            ),
          ),
        ],
      ),
    );
  }
}
