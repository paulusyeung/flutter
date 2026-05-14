// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'design_dao.dart';

// ignore_for_file: type=lint
mixin _$DesignDaoMixin on DatabaseAccessor<AppDatabase> {
  $DesignsTable get designs => attachedDatabase.designs;
  DesignDaoManager get managers => DesignDaoManager(this);
}

class DesignDaoManager {
  final _$DesignDaoMixin _db;
  DesignDaoManager(this._db);
  $$DesignsTableTableManager get designs =>
      $$DesignsTableTableManager(_db.attachedDatabase, _db.designs);
}
