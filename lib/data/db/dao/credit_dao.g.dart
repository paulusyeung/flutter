// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_dao.dart';

// ignore_for_file: type=lint
mixin _$CreditDaoMixin on DatabaseAccessor<AppDatabase> {
  $CreditsTable get credits => attachedDatabase.credits;
  CreditDaoManager get managers => CreditDaoManager(this);
}

class CreditDaoManager {
  final _$CreditDaoMixin _db;
  CreditDaoManager(this._db);
  $$CreditsTableTableManager get credits =>
      $$CreditsTableTableManager(_db.attachedDatabase, _db.credits);
}
