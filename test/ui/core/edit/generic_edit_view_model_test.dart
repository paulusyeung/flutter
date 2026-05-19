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

  group('GenericEditViewModel.validate hook', () {
    test('default validate() is a no-op — save proceeds normally', () async {
      final vm = _FakeEditVM(initialDraft: 'draft');
      final saved = await vm.save();

      expect(saved, 'draft');
      expect(vm.localValidationOnly, isFalse);
      expect(vm.performSaveCount, 1);
    });

    test(
      'validate() errors block the save before performSave runs',
      () async {
        final vm = _FakeEditVM(
          initialDraft: 'draft',
          validateErrors: const {
            'client_id': ['Please select a client'],
          },
        );

        final result = await vm.save();

        expect(result, isNull);
        expect(vm.performSaveCount, 0); // repo never called → no outbox row
        expect(vm.fieldErrorFor('client_id'), 'Please select a client');
        expect(vm.localValidationOnly, isTrue);
        expect(vm.submitError, isNull);
        expect(vm.isSaving, isFalse);
        expect(vm.isDirty, isTrue); // stays open, not marked clean
      },
    );

    test(
      'fixing the field clears localValidationOnly and lets save proceed',
      () async {
        final vm = _FakeEditVM(
          initialDraft: 'draft',
          validateErrors: const {
            'client_id': ['Please select a client'],
          },
        );
        await vm.save();
        expect(vm.localValidationOnly, isTrue);

        vm.passValidation();
        final ok = await vm.save();

        expect(ok, 'draft');
        expect(vm.localValidationOnly, isFalse);
        expect(vm.fieldErrors, isEmpty);
        expect(vm.performSaveCount, 1);
      },
    );

    test('clearFailedSync() resets localValidationOnly', () async {
      final vm = _FakeEditVM(
        initialDraft: 'draft',
        validateErrors: const {
          'client_id': ['Please select a client'],
        },
      );
      await vm.save();
      expect(vm.localValidationOnly, isTrue);

      vm.clearFailedSync();

      expect(vm.localValidationOnly, isFalse);
      expect(vm.fieldErrors, isEmpty);
    });

    test(
      'a validate() block does NOT leak a one-shot SAVE-PARAM query into '
      'the next plain save (regression: early-return must run finally)',
      () async {
        final vm = _FakeEditVM(
          initialDraft: 'draft',
          validateErrors: const {
            'client_id': ['Please select a client'],
          },
        );
        // Simulate an action bar stashing a SAVE-PARAM query, then a
        // blocked save.
        vm.setPendingSaveQuery({'mark_sent': 'true'});
        final blocked = await vm.save();
        expect(blocked, isNull);

        // User picks a client and presses plain Save.
        vm.passValidation();
        final ok = await vm.save();

        expect(ok, 'draft');
        // The stale mark_sent query must have been cleared by the finally
        // on the blocked save — not replayed here.
        expect(vm.lastConsumedQuery, isNull);
      },
    );
  });
}

class _FakeEditVM extends GenericEditViewModel<String> {
  _FakeEditVM({
    required super.initialDraft,
    this.throwOnSave,
    Map<String, List<String>> validateErrors = const {},
  }) : _validateErrors = validateErrors;

  Object? throwOnSave;
  Map<String, List<String>> _validateErrors;

  int performSaveCount = 0;
  Map<String, String>? lastConsumedQuery;

  void clearThrow() => throwOnSave = null;

  /// Make subsequent validate() pass (simulates the user fixing the field).
  void passValidation() => _validateErrors = const {};

  @override
  Map<String, List<String>> validate() => _validateErrors;

  @override
  Future<String> performSave() async {
    performSaveCount++;
    lastConsumedQuery = consumeSaveQuery();
    if (throwOnSave != null) throw throwOnSave!;
    return draft;
  }
}
