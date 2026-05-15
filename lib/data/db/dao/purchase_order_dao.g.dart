// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_order_dao.dart';

// ignore_for_file: type=lint
mixin _$PurchaseOrderDaoMixin on DatabaseAccessor<AppDatabase> {
  $PurchaseOrdersTable get purchaseOrders => attachedDatabase.purchaseOrders;
  PurchaseOrderDaoManager get managers => PurchaseOrderDaoManager(this);
}

class PurchaseOrderDaoManager {
  final _$PurchaseOrderDaoMixin _db;
  PurchaseOrderDaoManager(this._db);
  $$PurchaseOrdersTableTableManager get purchaseOrders =>
      $$PurchaseOrdersTableTableManager(
        _db.attachedDatabase,
        _db.purchaseOrders,
      );
}
