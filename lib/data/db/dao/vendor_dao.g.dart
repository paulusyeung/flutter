// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_dao.dart';

// ignore_for_file: type=lint
mixin _$VendorDaoMixin on DatabaseAccessor<AppDatabase> {
  $VendorsTable get vendors => attachedDatabase.vendors;
  VendorDaoManager get managers => VendorDaoManager(this);
}

class VendorDaoManager {
  final _$VendorDaoMixin _db;
  VendorDaoManager(this._db);
  $$VendorsTableTableManager get vendors =>
      $$VendorsTableTableManager(_db.attachedDatabase, _db.vendors);
}
