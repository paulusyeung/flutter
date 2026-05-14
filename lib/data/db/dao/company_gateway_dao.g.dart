// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_gateway_dao.dart';

// ignore_for_file: type=lint
mixin _$CompanyGatewayDaoMixin on DatabaseAccessor<AppDatabase> {
  $CompanyGatewaysTable get companyGateways => attachedDatabase.companyGateways;
  CompanyGatewayDaoManager get managers => CompanyGatewayDaoManager(this);
}

class CompanyGatewayDaoManager {
  final _$CompanyGatewayDaoMixin _db;
  CompanyGatewayDaoManager(this._db);
  $$CompanyGatewaysTableTableManager get companyGateways =>
      $$CompanyGatewaysTableTableManager(
        _db.attachedDatabase,
        _db.companyGateways,
      );
}
