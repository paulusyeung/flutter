// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_status_dao.dart';

// ignore_for_file: type=lint
mixin _$TaskStatusDaoMixin on DatabaseAccessor<AppDatabase> {
  $TaskStatusesTable get taskStatuses => attachedDatabase.taskStatuses;
  TaskStatusDaoManager get managers => TaskStatusDaoManager(this);
}

class TaskStatusDaoManager {
  final _$TaskStatusDaoMixin _db;
  TaskStatusDaoManager(this._db);
  $$TaskStatusesTableTableManager get taskStatuses =>
      $$TaskStatusesTableTableManager(_db.attachedDatabase, _db.taskStatuses);
}
