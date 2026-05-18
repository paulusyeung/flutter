import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/bank_transaction_api_model.dart';
import 'package:admin/data/models/api/transaction_rule_api_model.dart';
import 'package:admin/data/models/domain/bank_transaction.dart';
import 'package:admin/data/models/domain/transaction_rule.dart';
import 'package:admin/domain/transaction_rules/rule_evaluator.dart';

BankTransaction _tx({
  String description = '',
  String amount = '0',
  String participant = '',
  String participantName = '',
}) =>
    BankTransaction.fromApi(BankTransactionApi(
      id: 't',
      description: description,
      amount: amount,
      participant: participant,
      participantName: participantName,
      baseType: 'DEBIT',
    ));

TransactionRule _rule(
  List<RuleCriterion> rules, {
  bool matchesOnAll = true,
}) =>
    TransactionRule.fromApi(TransactionRuleApi(
      id: 'r',
      matchesOnAll: matchesOnAll,
      rules: rules.map((c) => c.toApi()).toList(),
    ));

RuleCriterion _c(String key, String op, String value) =>
    RuleCriterion(searchKey: key, operator: op, value: value);

void main() {
  group('ruleCriterionMatches — string ops (case-insensitive)', () {
    final tx = _tx(description: 'ACME Hosting Invoice');

    test('contains', () {
      expect(
        ruleCriterionMatches(
            tx, _c(kRuleSearchKeyDescription, kRuleOperatorContains, 'hosting')),
        isTrue,
      );
      expect(
        ruleCriterionMatches(
            tx, _c(kRuleSearchKeyDescription, kRuleOperatorContains, 'zzz')),
        isFalse,
      );
    });

    test('is / starts_with / is_empty', () {
      expect(
        ruleCriterionMatches(
            tx,
            _c(kRuleSearchKeyDescription, kRuleOperatorIs,
                'acme hosting invoice')),
        isTrue,
      );
      expect(
        ruleCriterionMatches(
            tx, _c(kRuleSearchKeyDescription, kRuleOperatorStartsWith, 'acme')),
        isTrue,
      );
      expect(
        ruleCriterionMatches(_tx(),
            _c(kRuleSearchKeyDescription, kRuleOperatorIsEmpty, '')),
        isTrue,
      );
    });

    test('participant / participant_name keys', () {
      final p = _tx(participant: 'PG&E', participantName: 'Pacific Gas');
      expect(
        ruleCriterionMatches(
            p, _c(kRuleSearchKeyParticipant, kRuleOperatorIs, 'pg&e')),
        isTrue,
      );
      expect(
        ruleCriterionMatches(
            p,
            _c(kRuleSearchKeyParticipantName, kRuleOperatorContains, 'gas')),
        isTrue,
      );
    });
  });

  group('ruleCriterionMatches — numeric amount', () {
    final tx = _tx(amount: '125.50');
    test('comparators', () {
      expect(
          ruleCriterionMatches(
              tx, _c(kRuleSearchKeyAmount, kRuleOperatorGreaterThan, '100')),
          isTrue);
      expect(
          ruleCriterionMatches(
              tx, _c(kRuleSearchKeyAmount, kRuleOperatorEquals, '125.50')),
          isTrue);
      expect(
          ruleCriterionMatches(
              tx, _c(kRuleSearchKeyAmount, kRuleOperatorLessThan, '125.50')),
          isFalse);
      expect(
          ruleCriterionMatches(
              tx, _c(kRuleSearchKeyAmount, kRuleOperatorLessThanOrEqual,
                  '125.50')),
          isTrue);
    });
    test('non-numeric value → no match (no throw)', () {
      expect(
          ruleCriterionMatches(
              tx, _c(kRuleSearchKeyAmount, kRuleOperatorEquals, 'abc')),
          isFalse);
    });
  });

  test('CREDIT-side placeholder keys are not locally evaluable', () {
    final tx = _tx(description: 'x');
    expect(
      ruleCriterionMatches(
          tx, _c(r'$invoice.number', kRuleOperatorContains, 'x')),
      isFalse,
    );
  });

  group('transactionRuleMatches — AND/OR + empty', () {
    final tx = _tx(description: 'Acme', amount: '50');

    test('matchesOnAll = AND', () {
      expect(
        transactionRuleMatches(
          tx,
          _rule([
            _c(kRuleSearchKeyDescription, kRuleOperatorContains, 'acme'),
            _c(kRuleSearchKeyAmount, kRuleOperatorGreaterThan, '10'),
          ]),
        ),
        isTrue,
      );
      expect(
        transactionRuleMatches(
          tx,
          _rule([
            _c(kRuleSearchKeyDescription, kRuleOperatorContains, 'acme'),
            _c(kRuleSearchKeyAmount, kRuleOperatorGreaterThan, '999'),
          ]),
        ),
        isFalse,
      );
    });

    test('matchesOnAll = false → OR', () {
      expect(
        transactionRuleMatches(
          tx,
          _rule(
            [
              _c(kRuleSearchKeyDescription, kRuleOperatorContains, 'nope'),
              _c(kRuleSearchKeyAmount, kRuleOperatorEquals, '50'),
            ],
            matchesOnAll: false,
          ),
        ),
        isTrue,
      );
    });

    test('no usable criteria → matches nothing', () {
      expect(transactionRuleMatches(tx, _rule(const [])), isFalse);
      expect(
        transactionRuleMatches(tx, _rule([_c('', kRuleOperatorContains, 'x')])),
        isFalse,
      );
    });
  });

  test('transactionRuleMatchCount counts matches', () {
    final rule = _rule([
      _c(kRuleSearchKeyDescription, kRuleOperatorContains, 'fee'),
    ]);
    final txs = [
      _tx(description: 'Monthly fee'),
      _tx(description: 'Refund'),
      _tx(description: 'Late FEE charge'),
    ];
    expect(transactionRuleMatchCount(txs, rule), 2);
  });
}
