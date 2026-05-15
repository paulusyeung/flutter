// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bank_transaction_dao.dart';

// ignore_for_file: type=lint
mixin _$BankTransactionDaoMixin on DatabaseAccessor<AppDatabase> {
  $BankTransactionsTable get bankTransactions =>
      attachedDatabase.bankTransactions;
  BankTransactionDaoManager get managers => BankTransactionDaoManager(this);
}

class BankTransactionDaoManager {
  final _$BankTransactionDaoMixin _db;
  BankTransactionDaoManager(this._db);
  $$BankTransactionsTableTableManager get bankTransactions =>
      $$BankTransactionsTableTableManager(
        _db.attachedDatabase,
        _db.bankTransactions,
      );
}
