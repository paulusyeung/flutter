// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tax_rate_dao.dart';

// ignore_for_file: type=lint
mixin _$TaxRateDaoMixin on DatabaseAccessor<AppDatabase> {
  $TaxRatesTable get taxRates => attachedDatabase.taxRates;
  TaxRateDaoManager get managers => TaxRateDaoManager(this);
}

class TaxRateDaoManager {
  final _$TaxRateDaoMixin _db;
  TaxRateDaoManager(this._db);
  $$TaxRatesTableTableManager get taxRates =>
      $$TaxRatesTableTableManager(_db.attachedDatabase, _db.taxRates);
}
