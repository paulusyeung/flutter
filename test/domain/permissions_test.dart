import 'package:flutter_test/flutter_test.dart';

import 'package:admin/domain/permissions.dart';

void main() {
  group('permissionsAfterToggleCell', () {
    test('checking the last cell in a column auto-promotes to <verb>_all', () {
      final current = [
        for (final e in kPermissionEntities)
          if (e != 'recurring_expense')
            permissionToken(verb: 'create', entity: e),
      ];
      final result = permissionsAfterToggleCell(
        current: current,
        verb: 'create',
        entity: 'recurring_expense',
        checked: true,
      );
      expect(result.promoted, isTrue);
      expect(result.permissions, ['create_all']);
    });

    test('unchecking one cell while <verb>_all is set expands to the other 13 '
        '(React parity)', () {
      final result = permissionsAfterToggleCell(
        current: const ['create_all'],
        verb: 'create',
        entity: 'invoice',
        checked: false,
      );
      expect(result.promoted, isFalse);
      expect(result.permissions, hasLength(kPermissionEntities.length - 1));
      expect(result.permissions, isNot(contains('create_all')));
      expect(result.permissions, isNot(contains('create_invoice')));
      expect(result.permissions, contains('create_client'));
      expect(result.permissions, contains('create_recurring_expense'));
    });

    test('expanding then re-checking the removed cell re-promotes to all', () {
      final expanded = permissionsAfterToggleCell(
        current: const ['create_all'],
        verb: 'create',
        entity: 'invoice',
        checked: false,
      ).permissions;
      final repromoted = permissionsAfterToggleCell(
        current: expanded,
        verb: 'create',
        entity: 'invoice',
        checked: true,
      );
      expect(repromoted.promoted, isTrue);
      expect(repromoted.permissions, ['create_all']);
    });

    test('unchecking a normal cell just removes its token', () {
      final result = permissionsAfterToggleCell(
        current: const ['create_client', 'view_invoice'],
        verb: 'create',
        entity: 'client',
        checked: false,
      );
      expect(result.permissions, ['view_invoice']);
    });

    test('preserves other-verb and unmodeled tokens', () {
      final result = permissionsAfterToggleCell(
        current: const ['view_all', 'edit_invoice', 'some_future_token'],
        verb: 'create',
        entity: 'client',
        checked: true,
      );
      expect(
        result.permissions,
        containsAll(<String>[
          'view_all',
          'edit_invoice',
          'some_future_token',
          'create_client',
        ]),
      );
    });
  });

  group('permissionsAfterToggleAll', () {
    test(
      'checking All drops per-entity tokens for that verb, keeps others',
      () {
        final result = permissionsAfterToggleAll(
          current: const ['create_client', 'create_invoice', 'view_client'],
          verb: 'create',
          checked: true,
        );
        expect(result, isNot(contains('create_client')));
        expect(result, isNot(contains('create_invoice')));
        expect(result, contains('create_all'));
        expect(result, contains('view_client')); // other verb untouched
      },
    );

    test('unchecking All removes only that token', () {
      final result = permissionsAfterToggleAll(
        current: const ['create_all', 'view_client'],
        verb: 'create',
        checked: false,
      );
      expect(result, const ['view_client']);
    });
  });
}
