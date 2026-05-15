// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_dao.dart';

// ignore_for_file: type=lint
mixin _$TokenDaoMixin on DatabaseAccessor<AppDatabase> {
  $TokensTable get tokens => attachedDatabase.tokens;
  TokenDaoManager get managers => TokenDaoManager(this);
}

class TokenDaoManager {
  final _$TokenDaoMixin _db;
  TokenDaoManager(this._db);
  $$TokensTableTableManager get tokens =>
      $$TokensTableTableManager(_db.attachedDatabase, _db.tokens);
}
