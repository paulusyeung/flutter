import 'package:flutter/material.dart';

import 'package:admin/ui/features/bank_accounts/views/bank_account_list_screen.dart';

/// Settings → Bank Accounts entry point. Re-exports the real list screen
/// so the existing `/settings/bank_accounts` route lands on it.
class BankAccountsScreen extends StatelessWidget {
  const BankAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) => const BankAccountListScreen();
}
