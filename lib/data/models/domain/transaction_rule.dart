import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/transaction_rule_api_model.dart';
import 'package:admin/data/models/value/parsing.dart';

part 'transaction_rule.freezed.dart';

/// `applies_to` constants.
const String kTransactionRuleAppliesDebit = 'DEBIT';
const String kTransactionRuleAppliesCredit = 'CREDIT';

/// `search_key` constants — DEBIT-side fields.
const String kRuleSearchKeyDescription = 'description';
const String kRuleSearchKeyAmount = 'amount';
const String kRuleSearchKeyParticipant = 'participant';
const String kRuleSearchKeyParticipantName = 'participant_name';

/// `search_key` constants — CREDIT-side placeholders. Match the React
/// shape: `$invoice.number`, `$invoice.po_number`, `$invoice.amount`,
/// `$invoice.custom1..4`, `$payment.amount`,
/// `$payment.transaction_reference`, `$payment.custom1..4`,
/// `$client.id_number`, `$client.email`, `$client.custom1..4`.
const List<String> kRuleCreditSearchKeys = <String>[
  r'$invoice.number',
  r'$invoice.po_number',
  r'$invoice.amount',
  r'$invoice.custom1',
  r'$invoice.custom2',
  r'$invoice.custom3',
  r'$invoice.custom4',
  r'$payment.amount',
  r'$payment.transaction_reference',
  r'$payment.custom1',
  r'$payment.custom2',
  r'$payment.custom3',
  r'$payment.custom4',
  r'$client.id_number',
  r'$client.email',
  r'$client.custom1',
  r'$client.custom2',
  r'$client.custom3',
  r'$client.custom4',
];

/// String operators (description / participant fields).
const String kRuleOperatorIs = 'is';
const String kRuleOperatorContains = 'contains';
const String kRuleOperatorStartsWith = 'starts_with';
const String kRuleOperatorIsEmpty = 'is_empty';

/// Numeric operators (amount field).
const String kRuleOperatorEquals = '=';
const String kRuleOperatorLessThan = '<';
const String kRuleOperatorLessThanOrEqual = '<=';
const String kRuleOperatorGreaterThan = '>';
const String kRuleOperatorGreaterThanOrEqual = '>=';

/// Whether [searchKey] takes a numeric value (drives the operator + input
/// type in the rule criterion editor).
bool isNumericSearchKey(String searchKey) =>
    searchKey == kRuleSearchKeyAmount ||
    searchKey == r'$invoice.amount' ||
    searchKey == r'$payment.amount';

/// User-facing label for a rule [searchKey]. Strips the `$invoice.` /
/// `$payment.` / `$client.` placeholder prefixes used by CREDIT-side
/// rules and humanizes the bare key (`po_number` → `PO Number`,
/// `participant_name` → `Participant Name`).
///
/// CREDIT placeholders are rendered as `<scope> <field>` (e.g.
/// `Invoice Number`, `Payment Amount`, `Client Email`) so the user reads
/// them as English instead of `$invoice.po_number` wire syntax.
String labelForSearchKey(String searchKey) {
  if (searchKey.isEmpty) return '';
  if (searchKey.startsWith(r'$')) {
    final parts = searchKey.substring(1).split('.');
    if (parts.length == 2) {
      return '${_humanize(parts[0])} ${_humanize(parts[1])}';
    }
  }
  return _humanize(searchKey);
}

/// User-facing label for a rule [operator]. The string operators
/// (`is`, `contains`, `starts_with`, `is_empty`) translate via the
/// localization keys of the same name; numeric operators (`=`, `<`, etc.)
/// pass through.
String labelForOperator(String operator) {
  switch (operator) {
    case kRuleOperatorIs:
      return 'is';
    case kRuleOperatorContains:
      return 'contains';
    case kRuleOperatorStartsWith:
      return 'starts with';
    case kRuleOperatorIsEmpty:
      return 'is empty';
    case kRuleOperatorEquals:
      return '=';
    case kRuleOperatorLessThan:
      return '<';
    case kRuleOperatorLessThanOrEqual:
      return '≤';
    case kRuleOperatorGreaterThan:
      return '>';
    case kRuleOperatorGreaterThanOrEqual:
      return '≥';
    default:
      return operator;
  }
}

/// `po_number` → `PO Number`, `participant_name` → `Participant Name`.
/// Special-cases the all-caps token `po` so the rendering reads as
/// "PO Number" rather than "Po Number".
String _humanize(String raw) {
  if (raw.isEmpty) return raw;
  return raw
      .split('_')
      .map((part) {
        if (part.isEmpty) return part;
        if (part.toLowerCase() == 'po') return 'PO';
        if (part.toLowerCase() == 'id') return 'ID';
        return '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
      })
      .join(' ');
}

/// One rule-criterion row. Equality intentional so a freezed `==` on the
/// containing list works cleanly.
@freezed
abstract class RuleCriterion with _$RuleCriterion {
  const factory RuleCriterion({
    @Default('') String searchKey,
    @Default('') String operator,
    @Default('') String value,
  }) = _RuleCriterion;

  factory RuleCriterion.fromApi(RuleCriterionApi a) => RuleCriterion(
    searchKey: a.searchKey,
    operator: a.operator,
    value: a.value,
  );

  const RuleCriterion._();

  RuleCriterionApi toApi() => RuleCriterionApi(
    searchKey: searchKey,
    operator: operator,
    value: value,
  );
}

/// Domain `TransactionRule` (wire entity: `bank_transaction_rule`).
/// Settings-area entity reached via Settings → Bank Accounts → Rules.
@freezed
abstract class TransactionRule with _$TransactionRule {
  const TransactionRule._();

  const factory TransactionRule({
    required String id,
    required String name,
    required String appliesTo,
    required bool matchesOnAll,
    required bool autoConvert,
    required String vendorId,
    required String categoryId,
    @Default(<RuleCriterion>[]) List<RuleCriterion> rules,
    @Default('') String vendorName,
    @Default('') String categoryName,
    required bool isDeleted,
    required DateTime updatedAt,
    required DateTime createdAt,
    required DateTime? archivedAt,
    @Default(false) bool isDirty,
  }) = _TransactionRule;

  factory TransactionRule.fromApi(TransactionRuleApi a) => TransactionRule(
    id: a.id,
    name: a.name,
    appliesTo:
        a.appliesTo.isEmpty ? kTransactionRuleAppliesDebit : a.appliesTo,
    matchesOnAll: a.matchesOnAll,
    autoConvert: a.autoConvert,
    vendorId: a.vendorId,
    categoryId: a.categoryId,
    rules: a.rules.map(RuleCriterion.fromApi).toList(growable: false),
    vendorName: (a.vendor?['name'] as String?) ?? '',
    categoryName: (a.expenseCategory?['name'] as String?) ?? '',
    isDeleted: a.isDeleted,
    updatedAt: epochSecondsToUtc(a.updatedAt),
    createdAt: epochSecondsToUtc(a.createdAt),
    archivedAt: epochSecondsToUtcOrNull(a.archivedAt),
  );

  Map<String, dynamic> toApiJson({bool preserveTempId = false}) {
    final json = TransactionRuleApi(
      id: id,
      name: name,
      appliesTo: appliesTo,
      matchesOnAll: matchesOnAll,
      autoConvert: autoConvert,
      vendorId: vendorId,
      categoryId: categoryId,
      rules: rules.map((r) => r.toApi()).toList(growable: false),
      isDeleted: isDeleted,
      updatedAt: updatedAt.millisecondsSinceEpoch ~/ 1000,
      createdAt: createdAt.millisecondsSinceEpoch ~/ 1000,
      archivedAt: archivedAt == null
          ? 0
          : archivedAt!.millisecondsSinceEpoch ~/ 1000,
    ).toJson();
    if (!preserveTempId && id.startsWith('tmp_')) {
      json.remove('id');
    }
    // Joined sub-objects are read-only; never round-trip them on save.
    json.remove('vendor');
    json.remove('expense_category');
    return json;
  }

  bool get isDebit => appliesTo == kTransactionRuleAppliesDebit;
  bool get isCredit => appliesTo == kTransactionRuleAppliesCredit;
}
