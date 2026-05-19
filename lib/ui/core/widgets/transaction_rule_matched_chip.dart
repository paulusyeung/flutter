import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/transaction_rule.dart';
import 'package:admin/l10n/localization.dart';

/// Provenance chip for a bank transaction that was auto-categorized by a
/// transaction rule. Resolves the rule name from the local Drift cache
/// (rules are bundled via `applyBundle` on login/refresh, so this is an
/// instant cache hit — no lazy hydrate scaffold like `BankAccountNameLabel`,
/// the rule repo has no `ensureLoaded`) and renders it as a tappable,
/// rounded chip that deep-links to the rule editor.
///
/// Surfaced near the top of the transaction detail header rather than as a
/// gray meta-row: "why was this categorized?" is a salience-sensitive
/// provenance fact, not an identity field.
class TransactionRuleMatchedChip extends StatelessWidget {
  const TransactionRuleMatchedChip({required this.transactionRuleId, super.key});

  final String transactionRuleId;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId;
    if (companyId == null || companyId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<TransactionRule?>(
      stream: services.transactionRules.watchByRealId(
        companyId: companyId,
        id: transactionRuleId,
      ),
      builder: (context, snapshot) {
        final rule = snapshot.data;
        final name = rule == null || rule.name.isEmpty
            ? transactionRuleId
            : rule.name;
        return ActionChip(
          backgroundColor: tokens.surface,
          side: BorderSide(color: tokens.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(InRadii.r1),
          ),
          tooltip: context.tr('transaction_rule'),
          onPressed: () => context.go(
            '/settings/bank_accounts/transaction_rules/$transactionRuleId',
          ),
          // No Flexible/Expanded here: RawChip measures its label under
          // unbounded width (intrinsic sizing), so a flex child throws a
          // RenderFlex error. The chip sizes to content; the caller's
          // Align(centerLeft) keeps it from going edge-to-edge, and a
          // ConstrainedBox caps a pathologically long rule name.
          label: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, size: 16, color: tokens.ink3),
                const SizedBox(width: 6),
                Text(
                  '${context.tr('transaction_rule')}: ',
                  style: TextStyle(color: tokens.ink3, fontSize: 12),
                ),
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
