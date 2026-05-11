import 'package:drift/drift.dart';

/// Document attachments. Scaffolded in M1 (empty/unused) so we don't pay a
/// schema migration when M2+ adds upload UI.
///
/// `upload_state` is `pending | in_flight | uploaded | failed`. The outbox
/// `mutation_kind` for uploads is `'upload'` and references this row.
@DataClassName('DocumentRow')
class Documents extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text().named('company_id')();
  TextColumn get entityType => text().named('entity_type')();
  TextColumn get entityId => text().named('entity_id')();
  TextColumn get localPath => text().named('local_path').nullable()();
  TextColumn get serverUrl => text().named('server_url').nullable()();
  TextColumn get mimeType => text().named('mime_type')();
  IntColumn get size => integer()();
  TextColumn get uploadState => text().named('upload_state')();
  IntColumn get createdAt => integer().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}
