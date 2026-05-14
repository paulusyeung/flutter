// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_term_dao.dart';

// ignore_for_file: type=lint
mixin _$PaymentTermDaoMixin on DatabaseAccessor<AppDatabase> {
  $PaymentTermsTable get paymentTerms => attachedDatabase.paymentTerms;
  PaymentTermDaoManager get managers => PaymentTermDaoManager(this);
}

class PaymentTermDaoManager {
  final _$PaymentTermDaoMixin _db;
  PaymentTermDaoManager(this._db);
  $$PaymentTermsTableTableManager get paymentTerms =>
      $$PaymentTermsTableTableManager(_db.attachedDatabase, _db.paymentTerms);
}
