import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/services/api_exception.dart';
import 'package:admin/ui/core/edit/generic_edit_view_model.dart';

void main() {
  group('GenericEditViewModel', () {
    test('save() returns the entity on success and clears errors', () async {
      final vm = _FakeEditVM(initialDraft: 'draft-v1');
      final saved = await vm.save();

      expect(saved, 'draft-v1');
      expect(vm.isSaving, isFalse);
      expect(vm.submitError, isNull);
      expect(vm.fieldErrors, isEmpty);
    });

    test(
      '422 ValidationException populates fieldErrors, returns null',
      () async {
        final vm = _FakeEditVM(
          initialDraft: 'draft',
          throwOnSave: const ValidationException(
            'The given data was invalid.',
            {
              'name': ['Name is required'],
              'email': ['Email must be valid', 'Email is required'],
            },
          ),
        );

        final result = await vm.save();

        expect(result, isNull);
        expect(vm.fieldErrorFor('name'), 'Name is required');
        expect(vm.fieldErrorFor('email'), 'Email must be valid');
        expect(vm.fieldErrorFor('phone'), isNull);
        // submitError stays null so the screen doesn't show a top-level
        // SnackBar — the inline errors are the feedback.
        expect(vm.submitError, isNull);
        expect(vm.isSaving, isFalse);
      },
    );

    test(
      'non-422 errors land on submitError, fieldErrors stays empty',
      () async {
        final vm = _FakeEditVM(
          initialDraft: 'draft',
          throwOnSave: Exception('boom'),
        );

        await vm.save();

        expect(vm.fieldErrors, isEmpty);
        expect(vm.submitError, isNotNull);
        expect(vm.submitError, contains('boom'));
      },
    );

    test(
      'subsequent save() clears the prior fieldErrors before retrying',
      () async {
        final vm = _FakeEditVM(
          initialDraft: 'draft',
          throwOnSave: const ValidationException('Invalid', {
            'name': ['Name is required'],
          }),
        );
        await vm.save();
        expect(vm.fieldErrorFor('name'), isNotNull);

        // Subsequent attempt succeeds — old errors should be cleared.
        vm.clearThrow();
        final ok = await vm.save();
        expect(ok, 'draft');
        expect(vm.fieldErrors, isEmpty);
      },
    );

    test('reset() clears draft, submitError, and fieldErrors', () async {
      final vm = _FakeEditVM(
        initialDraft: 'draft',
        throwOnSave: const ValidationException('Invalid', {
          'name': ['Name is required'],
        }),
      );
      await vm.save();

      vm.reset(emptyDraft: 'fresh');

      expect(vm.draft, 'fresh');
      expect(vm.fieldErrors, isEmpty);
      expect(vm.submitError, isNull);
    });
  });
}

class _FakeEditVM extends GenericEditViewModel<String> {
  _FakeEditVM({required super.initialDraft, this.throwOnSave});

  Object? throwOnSave;

  void clearThrow() => throwOnSave = null;

  @override
  Future<String> performSave() async {
    if (throwOnSave != null) throw throwOnSave!;
    return draft;
  }
}
