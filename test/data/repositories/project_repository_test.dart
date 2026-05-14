import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/project_api_model.dart';
import 'package:admin/data/models/domain/project.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/repositories/project_repository.dart';
import 'package:admin/data/services/projects_api.dart';
import 'package:admin/domain/sync/mutation.dart';

import '_base_entity_repository_contract.dart';

/// Covers the universal `BaseEntityRepository` contract via the shared
/// harness plus Project-specific assertions for `watchForClient`, the
/// dueDate Date round-trip, and the document mutation kinds.
class _ProjectFixture
    extends EntityRepositoryContractFixture<Project, ProjectApi> {
  @override
  String get entityType => 'project';

  @override
  ProjectRepository buildRepo(AppDatabase db) =>
      ProjectRepository(db: db, api: _FakeProjectsApi());

  @override
  ProjectApi buildApiModel({
    required String id,
    String? displayValue,
    int updatedAt = 1700000000,
  }) => ProjectApi(id: id, name: displayValue ?? id, updatedAt: updatedAt);

  @override
  Project fromApi(ProjectApi api) => Project.fromApi(api);

  @override
  Project editCopy(Project item, {required String displayValue}) =>
      item.copyWith(name: displayValue);

  @override
  String idOf(Project item) => item.id;

  @override
  bool isDirtyOf(Project item) => item.isDirty;

  @override
  Future<Project> create(
    BaseEntityRepository<Project, ProjectApi> repo, {
    required String companyId,
    required Project draft,
  }) => (repo as ProjectRepository).create(companyId: companyId, draft: draft);

  @override
  Future<void> save(
    BaseEntityRepository<Project, ProjectApi> repo, {
    required String companyId,
    required Project entity,
  }) => (repo as ProjectRepository).save(companyId: companyId, project: entity);

  @override
  Future<void> delete(
    BaseEntityRepository<Project, ProjectApi> repo, {
    required String companyId,
    required String id,
  }) => (repo as ProjectRepository).delete(companyId: companyId, id: id);
}

void main() {
  runEntityRepositoryContract(_ProjectFixture());

  group('ProjectRepository — entity-specific', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });
    tearDown(() async {
      await db.close();
    });

    ProjectRepository makeRepo() =>
        ProjectRepository(db: db, api: _FakeProjectsApi());

    test('_fromRow overlays is_dirty so watchPage reflects the unsaved '
        'state after restart', () async {
      final repo = makeRepo();
      final draft = Project.fromApi(
        const ProjectApi(name: 'X', updatedAt: 1700000000),
      );
      await repo.create(companyId: 'co', draft: draft);
      final created = await repo
          .watchPage(companyId: 'co', loadedPages: 1)
          .first;
      expect(created, hasLength(1));
      expect(created.first.isDirty, isTrue);
    });

    test('dueDate Date round-trips through fromApi/toApiJson', () {
      final api = const ProjectApi(
        id: 'proj_1',
        name: 'Q1 work',
        dueDate: '2026-04-30',
        taskRate: '50',
        budgetedHours: 40,
        updatedAt: 1700000000,
      );
      final domain = Project.fromApi(api);
      expect(domain.dueDate, const Date(2026, 4, 30));
      expect(domain.taskRate, Decimal.parse('50'));
      expect(domain.budgetedHours, 40.0);

      final payload = domain.toApiJson();
      expect(payload['due_date'], '2026-04-30');
      expect(payload['task_rate'], '50');
      expect(payload['budgeted_hours'], 40.0);
    });

    test('empty dueDate string parses to null, serializes back to empty', () {
      final domain = Project.fromApi(
        const ProjectApi(id: 'proj_1', name: 'X', updatedAt: 1700000000),
      );
      expect(domain.dueDate, isNull);
      expect(domain.toApiJson()['due_date'], '');
    });

    test(
      'watchForClient returns only projects with a matching clientId',
      () async {
        final repo = makeRepo();
        await repo.applyCreateResponse(
          companyId: 'co',
          tempId: 'p1',
          serverResponse: const ProjectApi(
            id: 'p1',
            name: 'P1',
            clientId: 'client_a',
            updatedAt: 1700000000,
          ),
        );
        await repo.applyCreateResponse(
          companyId: 'co',
          tempId: 'p2',
          serverResponse: const ProjectApi(
            id: 'p2',
            name: 'P2',
            clientId: 'client_b',
            updatedAt: 1700000001,
          ),
        );
        await repo.applyCreateResponse(
          companyId: 'co',
          tempId: 'p3',
          serverResponse: const ProjectApi(
            id: 'p3',
            name: 'P3',
            clientId: 'client_a',
            updatedAt: 1700000002,
          ),
        );
        final forA = await repo
            .watchForClient(companyId: 'co', clientId: 'client_a')
            .first;
        expect(forA.map((p) => p.id), unorderedEquals(['p1', 'p3']));
      },
    );

    test('watchForClient with empty clientId yields an empty list', () async {
      final repo = makeRepo();
      final result = await repo
          .watchForClient(companyId: 'co', clientId: '')
          .first;
      expect(result, isEmpty);
    });

    test('uploadDocument enqueues MutationKind.documentUpload (NOT '
        'password-gated)', () async {
      final repo = makeRepo();
      await repo.uploadDocument(
        companyId: 'co',
        projectId: 'proj_1',
        localPath: '/tmp/foo.pdf',
      );
      final rows = await db.outboxDao.nextReady(
        companyId: 'co',
        now: 9999999999999,
      );
      final row = rows.firstWhere(
        (r) => r.mutationKind == MutationKind.documentUpload.wireName,
      );
      expect(row.entityId, 'proj_1');
      expect(row.payload, contains('/tmp/foo.pdf'));
      expect(row.requiresPassword, isFalse);
    });

    test('deleteDocument enqueues MutationKind.documentDelete with '
        'requiresPassword=true', () async {
      final repo = makeRepo();
      await repo.deleteDocument(
        companyId: 'co',
        projectId: 'proj_1',
        documentId: 'doc_42',
      );
      final rows = await db.outboxDao.nextReady(
        companyId: 'co',
        now: 9999999999999,
      );
      final row = rows.firstWhere(
        (r) => r.mutationKind == MutationKind.documentDelete.wireName,
      );
      expect(row.requiresPassword, isTrue);
      expect(row.payload, contains('doc_42'));
    });

    test('delete and purge are password-gated', () async {
      final repo = makeRepo();
      await repo.delete(companyId: 'co', id: 'proj_1');
      await repo.purge(companyId: 'co', id: 'proj_1');
      final rows = await db.outboxDao.nextReady(
        companyId: 'co',
        now: 9999999999999,
      );
      final delRow = rows.firstWhere(
        (r) => r.mutationKind == MutationKind.delete.wireName,
      );
      final purgeRow = rows.firstWhere(
        (r) => r.mutationKind == MutationKind.purge.wireName,
      );
      expect(delRow.requiresPassword, isTrue);
      expect(purgeRow.requiresPassword, isTrue);
    });
  });
}

class _FakeProjectsApi implements ProjectsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
