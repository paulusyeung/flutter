// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bank_account_dao.dart';

// ignore_for_file: type=lint
mixin _$BankAccountDaoMixin on DatabaseAccessor<AppDatabase> {
  $BankAccountsTable get bankAccounts => attachedDatabase.bankAccounts;
  BankAccountDaoManager get managers => BankAccountDaoManager(this);
}

class BankAccountDaoManager {
  final _$BankAccountDaoMixin _db;
  BankAccountDaoManager(this._db);
  $$BankAccountsTableTableManager get bankAccounts =>
      $$BankAccountsTableTableManager(_db.attachedDatabase, _db.bankAccounts);
}
