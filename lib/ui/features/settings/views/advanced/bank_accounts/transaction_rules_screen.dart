import 'package:flutter/material.dart';

import 'package:admin/ui/features/transaction_rules/views/transaction_rule_list_screen.dart';

/// Settings → Bank Accounts → Rules entry point.
class BankAccountsTransactionRulesScreen extends StatelessWidget {
  const BankAccountsTransactionRulesScreen({super.key});

  @override
  Widget build(BuildContext context) => const TransactionRuleListScreen();
}
