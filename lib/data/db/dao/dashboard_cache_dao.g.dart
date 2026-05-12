// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_cache_dao.dart';

// ignore_for_file: type=lint
mixin _$DashboardCacheDaoMixin on DatabaseAccessor<AppDatabase> {
  $DashboardCacheTable get dashboardCache => attachedDatabase.dashboardCache;
  DashboardCacheDaoManager get managers => DashboardCacheDaoManager(this);
}

class DashboardCacheDaoManager {
  final _$DashboardCacheDaoMixin _db;
  DashboardCacheDaoManager(this._db);
  $$DashboardCacheTableTableManager get dashboardCache =>
      $$DashboardCacheTableTableManager(
        _db.attachedDatabase,
        _db.dashboardCache,
      );
}
