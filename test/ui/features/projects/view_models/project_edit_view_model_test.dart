import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/project_api_model.dart';
import 'package:admin/data/models/domain/project.dart';
import 'package:admin/data/repositories/project_repository.dart';
import 'package:admin/data/services/projects_api.dart';
import 'package:admin/ui/features/projects/view_models/project_edit_view_model.dart';

/// `StoreProjectRequest` requires `name` + `client_id` on create;
/// `UpdateProjectRequest` drops the `name` rule and locks `client_id`. The VM's
/// `validate()` must therefore block an empty create *before* the optimistic
/// Drift write / outbox enqueue, and never block an edit.
class _FakeProjectsApi implements ProjectsApi {
  @override
  Object? noSuchMethod(Invocation i) => throw UnimplementedError();
}

void main() {
  late AppDatabase db;
  late ProjectRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ProjectRepository(db: db, api: _FakeProjectsApi());
  });
  tearDown(() async {
    await db.close();
  });

  ProjectEditViewModel createVm() => ProjectEditViewModel(
    repo: repo,
    companyId: 'co',
    nameRequiredMessage: 'name required',
    clientRequiredMessage: 'client required',
  );

  ProjectEditViewModel editVm(Project existing) => ProjectEditViewModel(
    repo: repo,
    companyId: 'co',
    nameRequiredMessage: 'name required',
    clientRequiredMessage: 'client required',
    existing: existing,
  );

  Future<int> pendingOutboxCount() async {
    final rows = await db.outboxDao.nextReady(companyId: 'co', now: 1 << 60);
    return rows.length;
  }

  group('ProjectEditViewModel.validate (create)', () {
    test('blocks save when name + client are empty — inline errors, no local '
        'write', () async {
      final vm = createVm();
      final saved = await vm.save();

      expect(saved, isNull);
      expect(vm.fieldErrorFor('name'), 'name required');
      expect(vm.fieldErrorFor('client_id'), 'client required');
      expect(vm.localValidationOnly, isTrue);
      expect(
        await pendingOutboxCount(),
        0,
        reason: 'a blocked create must not enqueue an outbox row',
      );
    });

    test('blocks save when only the client is missing', () async {
      final vm = createVm()..setName('Website redesign');
      final saved = await vm.save();

      expect(saved, isNull);
      expect(vm.fieldErrorFor('name'), isNull);
      expect(vm.fieldErrorFor('client_id'), 'client required');
    });

    test('passes when name + client are set — performs the optimistic '
        'create', () async {
      final vm = createVm()
        ..setName('Website redesign')
        ..setClientId('c1');
      final saved = await vm.save();

      expect(saved, isNotNull);
      expect(vm.fieldErrors, isEmpty);
      expect(
        await pendingOutboxCount(),
        1,
        reason: 'a valid create enqueues exactly one outbox row',
      );
    });
  });

  group('ProjectEditViewModel.validate (edit)', () {
    test('never blocks on a blanked name (UpdateProjectRequest drops the name '
        'rule and locks client_id)', () async {
      final existing = Project.fromApi(
        const ProjectApi(
          id: 'p1',
          name: 'Existing',
          clientId: 'c1',
          updatedAt: 1700000000,
        ),
      );
      final vm = editVm(existing)..setName('');
      final saved = await vm.save();

      expect(saved, isNotNull);
      expect(vm.fieldErrorFor('name'), isNull);
      expect(vm.localValidationOnly, isFalse);
    });
  });
}
