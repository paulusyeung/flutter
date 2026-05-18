import 'package:decimal/decimal.dart';

import 'package:admin/data/models/domain/bank_transaction.dart';
import 'package:admin/data/models/domain/transaction_rule.dart';

/// Pure, local transaction-rule evaluator backing the rule-edit screen's
/// live "matches N transactions" preview. No server preview endpoint exists
/// (the backend matches server-side; the legacy clients have no evaluator),
/// so this mirrors the backend operator semantics closely enough for an
/// at-a-glance estimate.
///
/// **Scope:** only DEBIT-side `search_key`s (`description`, `amount`,
/// `participant`, `participant_name`) match a bank transaction's own
/// fields and are evaluable here. CREDIT-side placeholder keys
/// (`$invoice.*` / `$payment.*` / `$client.*`) match a transaction against
/// a *related* invoice/payment/client and cannot be evaluated against a
/// transaction alone — [transactionRuleMatches] returns `false` for those,
/// and the preview UI is hidden for credit rules.
bool ruleCriterionMatches(BankTransaction tx, RuleCriterion c) {
  if (c.searchKey.isEmpty || c.operator.isEmpty) return false;
  switch (c.searchKey) {
    case kRuleSearchKeyDescription:
      return _stringMatch(tx.description, c.operator, c.value);
    case kRuleSearchKeyParticipant:
      return _stringMatch(tx.participant, c.operator, c.value);
    case kRuleSearchKeyParticipantName:
      return _stringMatch(tx.participantName, c.operator, c.value);
    case kRuleSearchKeyAmount:
      return _numberMatch(tx.amount, c.operator, c.value);
    default:
      // CREDIT-side `$...` keys are not locally evaluable.
      return false;
  }
}

/// `true` iff [tx] satisfies [rule]. Empty / search-key-less criteria are
/// ignored; a rule with no usable criteria matches nothing (the preview is
/// only meaningful once at least one real criterion exists). `matchesOnAll`
/// → every criterion must match (AND); otherwise any (OR).
bool transactionRuleMatches(BankTransaction tx, TransactionRule rule) {
  final criteria =
      rule.rules.where((c) => c.searchKey.isNotEmpty).toList(growable: false);
  if (criteria.isEmpty) return false;
  if (rule.matchesOnAll) {
    return criteria.every((c) => ruleCriterionMatches(tx, c));
  }
  return criteria.any((c) => ruleCriterionMatches(tx, c));
}

/// How many of [transactions] the [rule] matches.
int transactionRuleMatchCount(
  Iterable<BankTransaction> transactions,
  TransactionRule rule,
) =>
    transactions.where((t) => transactionRuleMatches(t, rule)).length;

bool _stringMatch(String field, String op, String value) {
  final f = field.toLowerCase().trim();
  final v = value.toLowerCase().trim();
  switch (op) {
    case kRuleOperatorIs:
      return f == v;
    case kRuleOperatorContains:
      return v.isNotEmpty && f.contains(v);
    case kRuleOperatorStartsWith:
      return v.isNotEmpty && f.startsWith(v);
    case kRuleOperatorIsEmpty:
      return f.isEmpty;
    default:
      return false;
  }
}

bool _numberMatch(Decimal amount, String op, String value) {
  if (op == kRuleOperatorIsEmpty) return false; // amount is never "empty"
  final v = Decimal.tryParse(value.trim());
  if (v == null) return false;
  final cmp = amount.compareTo(v);
  switch (op) {
    case kRuleOperatorEquals:
      return cmp == 0;
    case kRuleOperatorLessThan:
      return cmp < 0;
    case kRuleOperatorLessThanOrEqual:
      return cmp <= 0;
    case kRuleOperatorGreaterThan:
      return cmp > 0;
    case kRuleOperatorGreaterThanOrEqual:
      return cmp >= 0;
    default:
      return false;
  }
}
