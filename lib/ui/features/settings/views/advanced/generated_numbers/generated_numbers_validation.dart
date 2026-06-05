/// Shared client-side validation for the Generated Numbers settings page.
///
/// Ports the guard the legacy admin-portal applied in
/// `lib/ui/settings/generated_numbers.dart` (`_onSavePressed`): a pattern that
/// uses the **per-client** `{$client_counter}` token without also including a
/// client-distinguishing token (`{$client_number}` / `{$client_id_number}`) or
/// the global `{$counter}` would mint the SAME number for every client's first
/// document (e.g. client A and client B both get invoice `0001`). The server
/// (`GeneratesCounter::applyNumberPattern`) does NOT enforce this — it happily
/// substitutes the per-client counter and creates the collision — so the check
/// has to live on the client.
///
/// Used in two places (so it lives here, not inline):
///   * `_PatternField` renders it as an inline field error (immediate, every
///     cascade scope).
///   * `GeneratedNumbersViewModel.preSaveError` hard-blocks the save at company
///     scope (matching the legacy app's coverage — it had no per-client
///     number settings).
library;

/// Every `<entity>_number_pattern` apiKey rendered by the Generated Numbers
/// tabs. Mirrors the per-entity tabs in `generated_numbers_shell.dart` and the
/// 12 patterns the legacy app validated.
const kNumberPatternKeys = <String>[
  'client_number_pattern',
  'invoice_number_pattern',
  'recurring_invoice_number_pattern',
  'payment_number_pattern',
  'quote_number_pattern',
  'credit_number_pattern',
  'project_number_pattern',
  'task_number_pattern',
  'vendor_number_pattern',
  'purchase_order_number_pattern',
  'expense_number_pattern',
  'recurring_expense_number_pattern',
];

/// True when [pattern] uses `{$client_counter}` but lacks any token that makes
/// the result unique per client. Null / empty / patterns without
/// `{$client_counter}` are valid.
///
/// Note `'{\$client_counter}'` does not *contain* the substring
/// `'{\$counter}'` (the chars after `{$` are `client_…`, not `counter}`), so the
/// distinguisher check below is not accidentally satisfied by the token itself.
bool violatesClientCounterRule(String? pattern) {
  final value = pattern ?? '';
  if (!value.contains(r'{$client_counter}')) return false;
  final hasDistinguisher =
      value.contains(r'{$counter}') ||
      value.contains(r'{$client_number}') ||
      value.contains(r'{$client_id_number}');
  return !hasDistinguisher;
}
