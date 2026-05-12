// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nav_state_dao.dart';

// ignore_for_file: type=lint
mixin _$NavStateDaoMixin on DatabaseAccessor<AppDatabase> {
  $NavStateTable get navState => attachedDatabase.navState;
  NavStateDaoManager get managers => NavStateDaoManager(this);
}

class NavStateDaoManager {
  final _$NavStateDaoMixin _db;
  NavStateDaoManager(this._db);
  $$NavStateTableTableManager get navState =>
      $$NavStateTableTableManager(_db.attachedDatabase, _db.navState);
}
