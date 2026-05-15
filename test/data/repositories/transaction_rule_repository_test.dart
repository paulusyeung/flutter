import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/transaction_rule_api_model.dart';
import 'package:admin/data/models/domain/transaction_rule.dart';
import 'package:admin/data/repositories/transaction_rule_repository.dart';
import 'package:admin/data/services/transaction_rules_api.dart';

import '_base_entity_repository_contract.dart';

void main() {
  runEntityRepositoryContract(
    EntityRepositoryContractFixture<TransactionRule, TransactionRuleApi>.build(
      entityType: 'transaction_rule',
      buildRepo: (db) =>
          TransactionRuleRepository(db: db, api: _FakeTransactionRulesApi()),
      buildApiModel: ({
        required String id,
        String? displayValue,
        int updatedAt = 1700000000,
      }) => TransactionRuleApi(
        id: id,
        name: displayValue ?? id,
        appliesTo: kTransactionRuleAppliesDebit,
        updatedAt: updatedAt,
      ),
      fromApi: TransactionRule.fromApi,
      editCopy: (item, {required String displayValue}) =>
          item.copyWith(name: displayValue),
      idOf: (item) => item.id,
      isDirtyOf: (item) => item.isDirty,
      create: (repo, {required companyId, required draft}) =>
          (repo as TransactionRuleRepository)
              .create(companyId: companyId, draft: draft),
      save: (repo, {required companyId, required entity}) =>
          (repo as TransactionRuleRepository)
              .save(companyId: companyId, rule: entity),
      delete: (repo, {required companyId, required id}) =>
          (repo as TransactionRuleRepository)
              .delete(companyId: companyId, id: id),
    ),
  );

  group('TransactionRuleRepository — RuleCriterion round-trip', () {
    test('criteria survive JSON encode → decode unchanged', () {
      final criteria = const [
        RuleCriterion(
          searchKey: kRuleSearchKeyDescription,
          operator: kRuleOperatorContains,
          value: 'Amazon',
        ),
        RuleCriterion(
          searchKey: kRuleSearchKeyAmount,
          operator: kRuleOperatorGreaterThan,
          value: '100',
        ),
        RuleCriterion(
          searchKey: kRuleSearchKeyParticipant,
          operator: kRuleOperatorIsEmpty,
          value: '',
        ),
      ];
      final rule = TransactionRule.fromApi(
        TransactionRuleApi(
          id: 'r1',
          name: 'High-value Amazon expenses',
          rules: criteria.map((c) => c.toApi()).toList(growable: false),
        ),
      );
      // Encode through the toApiJson path used to persist the payload.
      final json = jsonEncode(rule.toApiJson(preserveTempId: true));
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final api = TransactionRuleApi.fromJson(decoded);
      final back = TransactionRule.fromApi(api);
      expect(back.rules, hasLength(3));
      expect(back.rules[0].searchKey, kRuleSearchKeyDescription);
      expect(back.rules[0].operator, kRuleOperatorContains);
      expect(back.rules[0].value, 'Amazon');
      expect(back.rules[1].searchKey, kRuleSearchKeyAmount);
      expect(back.rules[1].operator, kRuleOperatorGreaterThan);
      expect(back.rules[1].value, '100');
      expect(back.rules[2].operator, kRuleOperatorIsEmpty);
      expect(back.rules[2].value, '');
    });

    test('vendor + expense_category joins land on the domain row', () {
      const api = TransactionRuleApi(
        id: 'r1',
        name: 'Rule',
        vendor: <String, dynamic>{'id': 'v1', 'name': 'Acme'},
        expenseCategory: <String, dynamic>{'id': 'c1', 'name': 'Office'},
      );
      final rule = TransactionRule.fromApi(api);
      expect(rule.vendorName, 'Acme');
      expect(rule.categoryName, 'Office');
    });

    test('toApiJson strips the read-only vendor + expense_category joins', () {
      final rule = TransactionRule.fromApi(
        const TransactionRuleApi(
          id: 'r1',
          name: 'Rule',
          vendor: <String, dynamic>{'id': 'v1', 'name': 'Acme'},
          expenseCategory: <String, dynamic>{'id': 'c1', 'name': 'Office'},
        ),
      );
      final payload = rule.toApiJson();
      expect(payload.containsKey('vendor'), isFalse);
      expect(payload.containsKey('expense_category'), isFalse);
    });

    test('isNumericSearchKey identifies amount fields', () {
      expect(isNumericSearchKey(kRuleSearchKeyAmount), isTrue);
      expect(isNumericSearchKey(r'$invoice.amount'), isTrue);
      expect(isNumericSearchKey(r'$payment.amount'), isTrue);
      expect(isNumericSearchKey(kRuleSearchKeyDescription), isFalse);
      expect(isNumericSearchKey(r'$invoice.number'), isFalse);
    });
  });
}

class _FakeTransactionRulesApi implements TransactionRulesApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
