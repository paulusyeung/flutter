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
  });
}
