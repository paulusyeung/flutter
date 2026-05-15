import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/domain/payment_link.dart';
import 'package:admin/data/repositories/payment_link_repository.dart';
import 'package:admin/data/services/subscriptions_api.dart';
import 'package:admin/ui/features/payment_links/view_models/payment_link_edit_view_model.dart';

void main() {
  group('PaymentLinkEditViewModel — side effects', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });
    tearDown(() async {
      await db.close();
    });

    PaymentLinkEditViewModel makeVm({PaymentLink? existing}) {
      final repo = PaymentLinkRepository(db: db, api: _FakeSubscriptionsApi());
      return PaymentLinkEditViewModel(
        repo: repo,
        companyId: 'co',
        existing: existing,
      );
    }

    test('turning allowCancellation off zeros refundPeriod', () {
      final existing = emptyPaymentLink().copyWith(
        id: 'real_1',
        allowCancellation: true,
        refundPeriod: 604800,
      );
      final vm = makeVm(existing: existing);
      expect(vm.draft.refundPeriod, 604800);
      vm.setAllowCancellation(false);
      expect(vm.draft.allowCancellation, isFalse);
      expect(vm.draft.refundPeriod, 0);
    });

    test('turning trialEnabled off zeros trialDuration', () {
      final existing = emptyPaymentLink().copyWith(
        id: 'real_1',
        trialEnabled: true,
        trialDuration: 86400,
      );
      final vm = makeVm(existing: existing);
      vm.setTrialEnabled(false);
      expect(vm.draft.trialEnabled, isFalse);
      expect(vm.draft.trialDuration, 0);
    });

    test('turning perSeatEnabled off zeros maxSeatsLimit', () {
      final existing = emptyPaymentLink().copyWith(
        id: 'real_1',
        perSeatEnabled: true,
        maxSeatsLimit: 10,
      );
      final vm = makeVm(existing: existing);
      vm.setPerSeatEnabled(false);
      expect(vm.draft.perSeatEnabled, isFalse);
      expect(vm.draft.maxSeatsLimit, 0);
    });
  });

  group('PaymentLinkEditViewModel — step management', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });
    tearDown(() async {
      await db.close();
    });

    PaymentLinkEditViewModel makeVm() {
      final repo = PaymentLinkRepository(db: db, api: _FakeSubscriptionsApi());
      return PaymentLinkEditViewModel(
        repo: repo,
        companyId: 'co',
        existing: emptyPaymentLink().copyWith(
          id: 'real_1',
          steps: 'auth.login,cart',
        ),
      );
    }

    test('orderedStepIds splits the comma-joined string', () {
      expect(makeVm().orderedStepIds, ['auth.login', 'cart']);
    });

    test('addStep appends; setSteps writes back as comma-joined', () {
      final vm = makeVm();
      vm.addStep('custom.confirmation');
      expect(vm.orderedStepIds, ['auth.login', 'cart', 'custom.confirmation']);
      expect(vm.draft.steps, 'auth.login,cart,custom.confirmation');
    });

    test('addStep is a no-op when the id is already in the list', () {
      final vm = makeVm();
      vm.addStep('cart');
      expect(vm.orderedStepIds, ['auth.login', 'cart']);
    });

    test('removeStep drops by index', () {
      final vm = makeVm();
      vm.removeStep(0);
      expect(vm.orderedStepIds, ['cart']);
    });

    test('reorderStep moves an item — Flutter\'s ReorderableListView '
        'oldIndex/newIndex convention is honored', () {
      final vm = makeVm();
      // ReorderableListView semantics: dragging 0 → after 1 reports
      // newIndex = 2; the VM normalizes by subtracting 1.
      vm.reorderStep(0, 2);
      expect(vm.orderedStepIds, ['cart', 'auth.login']);
    });
  });

  group('PaymentLinkEditViewModel — missingDependencyAt', () {
    test('returns the first missing dependency for a step whose deps are '
        'not all present earlier in the order', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final vm = PaymentLinkEditViewModel(
        repo: PaymentLinkRepository(db: db, api: _FakeSubscriptionsApi()),
        companyId: 'co',
        existing: emptyPaymentLink().copyWith(
          id: 'real_1',
          // cart is FIRST; auth.login is later. cart depends on
          // auth.login → dependency is missing.
          steps: 'cart,auth.login',
        ),
      );
      // Seed catalog directly (no I/O in tests) using the same shape
      // the API would return.
      vm.seedStepsForTest(const [
        PaymentLinkStep(
          id: 'cart',
          label: 'Cart',
          dependencies: ['auth.login'],
        ),
        PaymentLinkStep(
          id: 'auth.login',
          label: 'Login',
          dependencies: [],
        ),
      ]);
      expect(vm.missingDependencyAt(0), 'auth.login');
      expect(vm.missingDependencyAt(1), isNull);
    });

    test('returns null when dependencies are satisfied', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final vm = PaymentLinkEditViewModel(
        repo: PaymentLinkRepository(db: db, api: _FakeSubscriptionsApi()),
        companyId: 'co',
        existing: emptyPaymentLink().copyWith(
          id: 'real_1',
          steps: 'auth.login,cart',
        ),
      );
      vm.seedStepsForTest(const [
        PaymentLinkStep(
          id: 'auth.login',
          label: 'Login',
          dependencies: [],
        ),
        PaymentLinkStep(
          id: 'cart',
          label: 'Cart',
          dependencies: ['auth.login'],
        ),
      ]);
      expect(vm.missingDependencyAt(0), isNull);
      expect(vm.missingDependencyAt(1), isNull);
    });
  });
}

class _FakeSubscriptionsApi implements SubscriptionsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
