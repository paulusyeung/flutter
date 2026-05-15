import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/bank_account.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/widgets/settings_entity_list_scaffold.dart';
import 'package:admin/utils/formatting.dart';

/// Search keys for the in-app settings sidebar search.
const kBankAccountsListSearchKeys = <String>[
  'bank_accounts',
  'bank_account',
  'new_bank_account',
  'auto_sync',
  'sync_from',
  'transaction_rules',
  'connect_accounts',
  'reconnect',
];

/// `/settings/bank_accounts` — list every bank integration. Tap a row to
/// edit; tap "+ New bank account" to create a manual account. Connect
/// Accounts (Yodlee/Nordigen OAuth) is deferred — surfaces as a disabled
/// button with a "Coming soon" tooltip.
class BankAccountListScreen extends StatelessWidget {
  const BankAccountListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    final repo = services.bankAccounts;

    // The Formatter is built async (statics + company settings). Resolve
    // once at the screen level and pass down — rows render unformatted
    // balances while the future is pending, then re-render with the
    // proper currency/locale once it resolves.
    return FutureBuilder<Formatter>(
      future: services.formatterFor(companyId),
      builder: (context, snapshot) {
        final formatter = snapshot.data;
        return SettingsEntityListScaffold<BankAccount>(
          titleKey: 'bank_accounts',
          sectionTitleKey: 'bank_accounts',
          newRoute: '/settings/bank_accounts/new',
          newLabelKey: 'new_bank_account',
          emptyIcon: Icons.account_balance_outlined,
          emptyTitleKey: 'no_bank_accounts',
          emptyHintKey: 'no_bank_accounts_hint',
          supportsArchive: true,
          extraAppBarActions: const [_ConnectAccountsButton()],
          refreshAll: () async {
            if (companyId.isEmpty) return;
            await repo.refreshAll(companyId: companyId);
          },
          stream: ({required includeArchived}) => includeArchived
              ? repo.watchAllIncludingArchived(companyId: companyId)
              : repo.watchAll(companyId: companyId),
          isArchivedOf: (a) => a.archivedAt != null,
          isDeletedOf: (a) => a.isDeleted,
          rowBuilder: (a) => _BankAccountRow(
            key: ValueKey(a.id),
            account: a,
            formatter: formatter,
          ),
          archivedRowBuilder: (a) => _BankAccountRow.archived(
            key: ValueKey(a.id),
            account: a,
            formatter: formatter,
          ),
        );
      },
    );
  }
}

class _BankAccountRow extends StatelessWidget {
  const _BankAccountRow({
    required this.account,
    required this.formatter,
    super.key,
  }) : _isArchived = false;

  const _BankAccountRow.archived({
    required this.account,
    required this.formatter,
    super.key,
  }) : _isArchived = true;

  final BankAccount account;
  final Formatter? formatter;
  final bool _isArchived;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final displayName =
        account.name.trim().isEmpty ? context.tr('untitled') : account.name;
    final balanceLabel = _formatBalance(formatter, account);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(
            account.needsReconnect
                ? Icons.link_off
                : Icons.account_balance_outlined,
            color: account.needsReconnect ? tokens.overdue : tokens.ink2,
          ),
          title: Text(displayName),
          subtitle: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (account.type.isNotEmpty)
                Text(
                  account.type,
                  style: TextStyle(color: tokens.ink2, fontSize: 12),
                ),
              if (account.provider.isNotEmpty ||
                  account.integrationType.isNotEmpty)
                Text(
                  '· ${_providerLabel(context, account)}',
                  style: TextStyle(color: tokens.ink2, fontSize: 12),
                ),
              if (account.needsReconnect)
                _ChipPill(
                  text: context.tr('reconnect'),
                  background: tokens.overdueSoft,
                  foreground: tokens.overdue,
                ),
            ],
          ),
          trailing: _isArchived
              ? _ChipPill(
                  text: context.tr('archived'),
                  background: tokens.draftSoft,
                  foreground: tokens.draft,
                )
              : Text(
                  balanceLabel,
                  style: TextStyle(
                    color: tokens.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          onTap: () => context.go('/settings/bank_accounts/${account.id}'),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

/// Format the balance through the company's Formatter when one is
/// available. Bank accounts store currency as an ISO code (`USD`) but
/// `Formatter.money` keys on the numeric currency id — resolve via
/// `formatter.currencies` (small map, cheap scan). When the formatter
/// isn't ready yet, fall back to a plain `<CODE> <amount>` rendering so
/// the row still displays sensibly during the brief load.
String _formatBalance(Formatter? formatter, BankAccount account) {
  if (formatter != null) {
    String? resolvedId;
    if (account.currency.isNotEmpty) {
      final upper = account.currency.toUpperCase();
      for (final entry in formatter.currencies.entries) {
        if (entry.value.code.toUpperCase() == upper) {
          resolvedId = entry.key;
          break;
        }
      }
    }
    final formatted = formatter.money(
      account.balance,
      currencyId: resolvedId,
    );
    if (formatted.isNotEmpty) return formatted;
  }
  final prefix = account.currency.isEmpty ? '' : '${account.currency} ';
  return '$prefix${account.balance}';
}

/// Disabled "Connect Accounts" affordance surfaced in the AppBar. The
/// Yodlee/Nordigen OAuth flow is deferred; we render the button so the
/// path is discoverable but tooltip-disable it to set honest expectations.
class _ConnectAccountsButton extends StatelessWidget {
  const _ConnectAccountsButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Tooltip(
        message: context.tr('coming_soon'),
        child: TextButton.icon(
          icon: const Icon(Icons.add_link, size: 18),
          label: Text(context.tr('connect_accounts')),
          onPressed: null,
        ),
      ),
    );
  }
}

/// Prefer the server-provided friendly provider name when present;
/// otherwise translate the wire `integration_type` (YODLEE / NORDIGEN /
/// manual) so the row never displays the raw uppercase enum.
String _providerLabel(BuildContext context, BankAccount account) {
  if (account.provider.isNotEmpty) {
    // Server sometimes returns the wire enum (`YODLEE`) and sometimes a
    // friendlier label — translate when it matches a known wire value,
    // otherwise pass through.
    final key = labelKeyForProvider(account.provider);
    if (key.startsWith('provider_name_') || key == 'manual') {
      return context.tr(key);
    }
    return account.provider;
  }
  return context.tr(labelKeyForProvider(account.integrationType));
}

class _ChipPill extends StatelessWidget {
  const _ChipPill({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(InRadii.r1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
