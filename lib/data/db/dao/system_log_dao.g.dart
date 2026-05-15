// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_log_dao.dart';

// ignore_for_file: type=lint
mixin _$SystemLogDaoMixin on DatabaseAccessor<AppDatabase> {
  $SystemLogsTable get systemLogs => attachedDatabase.systemLogs;
  SystemLogDaoManager get managers => SystemLogDaoManager(this);
}

class SystemLogDaoManager {
  final _$SystemLogDaoMixin _db;
  SystemLogDaoManager(this._db);
  $$SystemLogsTableTableManager get systemLogs =>
      $$SystemLogsTableTableManager(_db.attachedDatabase, _db.systemLogs);
}
