// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_link_dao.dart';

// ignore_for_file: type=lint
mixin _$PaymentLinkDaoMixin on DatabaseAccessor<AppDatabase> {
  $PaymentLinksTable get paymentLinks => attachedDatabase.paymentLinks;
  PaymentLinkDaoManager get managers => PaymentLinkDaoManager(this);
}

class PaymentLinkDaoManager {
  final _$PaymentLinkDaoMixin _db;
  PaymentLinkDaoManager(this._db);
  $$PaymentLinksTableTableManager get paymentLinks =>
      $$PaymentLinksTableTableManager(_db.attachedDatabase, _db.paymentLinks);
}
