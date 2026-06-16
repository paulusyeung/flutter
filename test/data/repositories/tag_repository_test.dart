import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/tag_api_model.dart';
import 'package:admin/data/models/api/task_api_model.dart';
import 'package:admin/data/models/domain/tag.dart';
import 'package:admin/data/models/domain/task.dart';
import 'package:admin/data/repositories/tag_repository.dart';
import 'package:admin/data/services/tags_api.dart';

import '_base_entity_repository_contract.dart';

void main() {
  // Universal CRUD/outbox contract via the shared harness.
  runEntityRepositoryContract(
    EntityRepositoryContractFixture<Tag, TagApi>.build(
      entityType: 'tag',
      buildRepo: (db) => TagRepository(db: db, api: _FakeTagsApi()),
      buildApiModel: ({required id, displayValue, updatedAt = 1700000000}) =>
          TagApi(
            id: id,
            entityType: 'task',
            name: displayValue ?? id,
            color: '#abcdef',
            updatedAt: updatedAt,
          ),
      fromApi: Tag.fromApi,
      editCopy: (item, {required displayValue}) =>
          item.copyWith(name: displayValue),
      idOf: (t) => t.id,
      isDirtyOf: (t) => t.isDirty,
      create: (repo, {required companyId, required draft}) =>
          (repo as TagRepository).create(companyId: companyId, draft: draft),
      save: (repo, {required companyId, required entity}) =>
          (repo as TagRepository).save(companyId: companyId, tag: entity),
      delete: (repo, {required companyId, required id}) =>
          (repo as TagRepository).delete(companyId: companyId, id: id),
      // Mirrors requiresPasswordFor: {delete, purge}.
      deleteRequiresPassword: true,
    ),
  );

  group('TagRepository — entity-specific', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() async => db.close());

    test('Tag.fromApi normalizes the FQCN entity_type to the short key', () {
      final fromFqcn = Tag.fromApi(
        const TagApi(id: 't1', entityType: 'App\\Models\\Task', name: 'Urgent'),
      );
      expect(fromFqcn.entityType, 'task');
      final fromShort = Tag.fromApi(
        const TagApi(id: 't2', entityType: 'project', name: 'Phase 1'),
      );
      expect(fromShort.entityType, 'project');
    });

    test('Tag.fromApi maps a null color to empty string', () {
      final t = Tag.fromApi(const TagApi(id: 't1', name: 'X'));
      expect(t.color, '');
    });

    test(
      'refreshAll fetches both entity types and stamps the short key',
      () async {
        final repo = TagRepository(
          db: db,
          api: _FakeTagsApi({
            'task': const [
              TagApi(
                id: 'tt',
                entityType: 'App\\Models\\Task',
                name: 'TaskTag',
              ),
            ],
            'project': const [
              TagApi(
                id: 'pt',
                entityType: 'App\\Models\\Project',
                name: 'ProjTag',
              ),
            ],
          }),
        );
        await repo.refreshAll(companyId: 'co');

        final taskTags = await repo
            .watchAll(companyId: 'co', entityType: 'task')
            .first;
        final projectTags = await repo
            .watchAll(companyId: 'co', entityType: 'project')
            .first;
        expect(taskTags.map((t) => t.id), ['tt']);
        expect(taskTags.single.entityType, 'task');
        expect(projectTags.map((t) => t.id), ['pt']);
        expect(projectTags.single.entityType, 'project');
      },
    );

    test('archive optimistically flips local archived_at + is_dirty so it '
        'leaves the active pool offline (M4)', () async {
      final repo = TagRepository(db: db, api: _FakeTagsApi());
      final created = await repo.create(
        companyId: 'co',
        draft: newTagDraft(name: 'Urgent', entityType: 'task'),
      );
      final id = created.entity.id;

      await repo.archive(companyId: 'co', id: id);

      final all = await repo
          .watchAllAnyState(companyId: 'co', entityType: 'task')
          .first;
      final row = all.single;
      expect(row.archivedAt, isNotNull, reason: 'optimistic archive flip');
      expect(row.isDirty, isTrue, reason: 'dirty so a /refresh won\'t clobber');

      // Not a silent no-op: it drops out of the active pool immediately.
      final active = await repo
          .watchAll(companyId: 'co', entityType: 'task')
          .first;
      expect(active, isEmpty);
    });

    test('watchAllAnyState surfaces archived names for the inline-create '
        'collision check while the active pool hides them (M1)', () async {
      final repo = TagRepository(db: db, api: _FakeTagsApi());
      await repo.create(
        companyId: 'co',
        draft: newTagDraft(name: 'Active', entityType: 'task'),
      );
      final archived = await repo.create(
        companyId: 'co',
        draft: newTagDraft(name: 'Archived', entityType: 'task'),
      );
      await repo.archive(companyId: 'co', id: archived.entity.id);

      final anyState = await repo
          .watchAllAnyState(companyId: 'co', entityType: 'task')
          .first;
      expect(
        anyState.map((t) => t.name).toSet(),
        containsAll(<String>['Active', 'Archived']),
        reason: 'collision check must see the archived name',
      );
      final active = await repo
          .watchAll(companyId: 'co', entityType: 'task')
          .first;
      expect(active.map((t) => t.name), ['Active']);
    });
  });

  group('Task tags wire round-trip', () {
    test('parses server [{id,name,color}] objects into tagIds', () {
      final api = TaskApi.fromJson(const {
        'id': 'k1',
        'tags': [
          {'id': 'a', 'name': 'Urgent', 'color': '#ff0000'},
          {'id': 'b', 'name': 'Billing', 'color': null},
        ],
      });
      expect(Task.fromApi(api).tagIds, ['a', 'b']);
    });

    test('parses bare ["id"] strings (the payload round-trip form)', () {
      final api = TaskApi.fromJson(const {
        'id': 'k1',
        'tags': ['a', 'b'],
      });
      expect(Task.fromApi(api).tagIds, ['a', 'b']);
    });

    test('toApiJson emits tags as the bare id list (full-set sync)', () {
      final task = Task.fromApi(
        const TaskApi(id: 'k1'),
      ).copyWith(tagIds: ['a', 'b']);
      expect(task.toApiJson()['tags'], ['a', 'b']);
    });
  });
}

/// Stub TagsApi. The CRUD-contract path never reaches the network; [list] is
/// implemented so the `refreshAll` test can exercise the two-entity_type fetch.
class _FakeTagsApi implements TagsApi {
  _FakeTagsApi([this.byType = const {}]);

  final Map<String, List<TagApi>> byType;

  @override
  Future<({TagListApi data, int? cursorUpdatedAt, String? cursorId})> list({
    required int page,
    int perPage = 50,
    String? search,
    int? sinceUpdatedAt,
    String? sinceId,
    Map<String, String> filters = const {},
  }) async {
    final type = filters['entity_type'] ?? '';
    final items = page == 1
        ? (byType[type] ?? const <TagApi>[])
        : const <TagApi>[];
    return (
      data: TagListApi(data: items),
      cursorUpdatedAt: null,
      cursorId: null,
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
