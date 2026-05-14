// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_setting_dao.dart';

// ignore_for_file: type=lint
mixin _$GroupSettingDaoMixin on DatabaseAccessor<AppDatabase> {
  $GroupSettingsTable get groupSettings => attachedDatabase.groupSettings;
  GroupSettingDaoManager get managers => GroupSettingDaoManager(this);
}

class GroupSettingDaoManager {
  final _$GroupSettingDaoMixin _db;
  GroupSettingDaoManager(this._db);
  $$GroupSettingsTableTableManager get groupSettings =>
      $$GroupSettingsTableTableManager(_db.attachedDatabase, _db.groupSettings);
}
