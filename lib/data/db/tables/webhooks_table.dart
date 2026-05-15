import 'package:drift/drift.dart';

import 'package:admin/data/db/tables/_entity_table_mixin.dart';

/// Drift table for Webhook rows (wire entity: `webhook`).
///
/// Denormalized columns surface the fields the list page filters / sorts on:
/// `event_id`, `target_url`, `rest_method`. The `headers` map lives in the
/// JSON `payload` blob — never queried independently.
@DataClassName('WebhookRow')
class Webhooks extends Table
    with
        EntityIdColumns,
        EntityTimestampColumns,
        EntityFlagColumns,
        EntityPayloadColumn {
  TextColumn get eventId =>
      text().named('event_id').withDefault(const Constant(''))();
  TextColumn get targetUrl =>
      text().named('target_url').withDefault(const Constant(''))();
  TextColumn get format =>
      text().named('format').withDefault(const Constant('JSON'))();
  TextColumn get restMethod =>
      text().named('rest_method').withDefault(const Constant('POST'))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE (company_id, id)'];
}
