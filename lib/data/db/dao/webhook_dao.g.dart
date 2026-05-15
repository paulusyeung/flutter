// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'webhook_dao.dart';

// ignore_for_file: type=lint
mixin _$WebhookDaoMixin on DatabaseAccessor<AppDatabase> {
  $WebhooksTable get webhooks => attachedDatabase.webhooks;
  WebhookDaoManager get managers => WebhookDaoManager(this);
}

class WebhookDaoManager {
  final _$WebhookDaoMixin _db;
  WebhookDaoManager(this._db);
  $$WebhooksTableTableManager get webhooks =>
      $$WebhooksTableTableManager(_db.attachedDatabase, _db.webhooks);
}
