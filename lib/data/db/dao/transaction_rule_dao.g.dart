// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_rule_dao.dart';

// ignore_for_file: type=lint
mixin _$TransactionRuleDaoMixin on DatabaseAccessor<AppDatabase> {
  $TransactionRulesTable get transactionRules =>
      attachedDatabase.transactionRules;
  TransactionRuleDaoManager get managers => TransactionRuleDaoManager(this);
}

class TransactionRuleDaoManager {
  final _$TransactionRuleDaoMixin _db;
  TransactionRuleDaoManager(this._db);
  $$TransactionRulesTableTableManager get transactionRules =>
      $$TransactionRulesTableTableManager(
        _db.attachedDatabase,
        _db.transactionRules,
      );
}
