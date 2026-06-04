import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/repositories/company_gateway_repository.dart';
import 'package:admin/domain/gateway_constants.dart';
import 'package:admin/ui/features/gateways/view_models/company_gateway_edit_view_model.dart';

/// The VM stores the repo but never calls it for these pure-default checks.
class _FakeGatewayRepo implements CompanyGatewayRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  group('CompanyGatewayEditViewModel new-gateway defaults', () {
    test('initialDraft and emptyDraft both seed token_billing = always', () {
      final vm = CompanyGatewayEditViewModel(
        repo: _FakeGatewayRepo(),
        companyId: 'co-1',
      );
      // Both new-gateway factories must agree (React + admin-portal default to
      // `always`); a divergence means "discard changes" silently flips the
      // setting versus a fresh create.
      expect(vm.draft.tokenBilling, kAutoBillAlways);
      expect(vm.emptyDraft().tokenBilling, kAutoBillAlways);
    });

    test(
      'initialDraft and emptyDraft seed accepted_credit_cards = all brands',
      () {
        final vm = CompanyGatewayEditViewModel(
          repo: _FakeGatewayRepo(),
          companyId: 'co-1',
        );
        // Seeded to all brands (31) so a new gateway never sends
        // `accepted_credit_cards: 0` — which would disable every card brand if
        // the server honors the field. The brand-picker UI is intentionally gone.
        expect(vm.draft.acceptedCreditCards, kAllCreditCardTypes);
        expect(vm.emptyDraft().acceptedCreditCards, kAllCreditCardTypes);
      },
    );
  });
}
