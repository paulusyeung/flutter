import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/domain/design.dart';
import 'package:admin/data/repositories/design_repository.dart';
import 'package:admin/data/services/designs_api.dart';
import 'package:admin/ui/features/settings/view_models/design_edit_view_model.dart';

class _FakeDesignsApi implements DesignsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Design _design({
  String id = 'd1',
  String name = 'Source',
  List<String> entities = const ['invoice', 'quote'],
}) => Design(
  id: id,
  name: name,
  isCustom: true,
  isActive: true,
  isTemplate: false,
  isFree: false,
  entities: entities,
  template: const DesignTemplate(body: '<b>x</b>', header: 'h'),
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  archivedAt: null,
  isDeleted: false,
);

void main() {
  late AppDatabase db;
  late DesignRepository repo;
  const companyId = 'co1';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DesignRepository(db: db, api: _FakeDesignsApi());
  });

  tearDown(() async {
    await db.close();
  });

  test('create-mode starts clean, dirties once a field is set', () {
    final vm = DesignEditViewModel(repo: repo, companyId: companyId);
    expect(vm.isCreate, isTrue);
    expect(vm.isDirty, isFalse);
    vm.setName('My Design');
    expect(vm.isDirty, isTrue);
    expect(vm.draft.name, 'My Design');
  });

  test('toggleEntity adds and removes wire tokens', () {
    final vm = DesignEditViewModel(repo: repo, companyId: companyId);
    vm.toggleEntity('invoice', true);
    vm.toggleEntity('credit', true);
    expect(vm.draft.entities, containsAll(<String>['invoice', 'credit']));
    vm.toggleEntity('invoice', false);
    expect(vm.draft.entities, ['credit']);
  });

  test('loadFrom copies entities + template, keeps draft id', () {
    final vm = DesignEditViewModel(repo: repo, companyId: companyId);
    vm.loadFrom(_design());
    expect(vm.draft.id, '');
    expect(vm.draft.entities, ['invoice', 'quote']);
    expect(vm.draft.template.body, '<b>x</b>');
  });

  test('save() on create lands a tmp design + a create outbox row', () async {
    final vm = DesignEditViewModel(repo: repo, companyId: companyId)
      ..setName('Branded')
      ..toggleEntity('invoice', true)
      ..setBody('<html></html>');

    final saved = await vm.save();

    expect(saved, isNotNull);
    expect(saved!.id, startsWith('tmp_'));
    final rows = await repo.watchAll(companyId: companyId).first;
    expect(rows.where((d) => d.name == 'Branded'), isNotEmpty);
    final outbox = await db.outboxDao.watchAll(companyId).first;
    expect(outbox, isNotEmpty);
  });
}
