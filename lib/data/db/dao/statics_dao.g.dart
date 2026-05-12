// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statics_dao.dart';

// ignore_for_file: type=lint
mixin _$StaticsDaoMixin on DatabaseAccessor<AppDatabase> {
  $StaticsTable get statics => attachedDatabase.statics;
  StaticsDaoManager get managers => StaticsDaoManager(this);
}

class StaticsDaoManager {
  final _$StaticsDaoMixin _db;
  StaticsDaoManager(this._db);
  $$StaticsTableTableManager get statics =>
      $$StaticsTableTableManager(_db.attachedDatabase, _db.statics);
}
