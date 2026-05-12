// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_dao.dart';

// ignore_for_file: type=lint
mixin _$ClientDaoMixin on DatabaseAccessor<AppDatabase> {
  $ClientsTable get clients => attachedDatabase.clients;
  ClientDaoManager get managers => ClientDaoManager(this);
}

class ClientDaoManager {
  final _$ClientDaoMixin _db;
  ClientDaoManager(this._db);
  $$ClientsTableTableManager get clients =>
      $$ClientsTableTableManager(_db.attachedDatabase, _db.clients);
}
