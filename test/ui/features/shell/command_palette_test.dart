import 'package:flutter_test/flutter_test.dart';

import 'package:admin/domain/entity_type.dart';
import 'package:admin/ui/features/shell/widgets/command_palette.dart';

void main() {
  group('entityTypeForSearchGroup', () {
    test('maps every entity search group to its EntityType', () {
      expect(entityTypeForSearchGroup('clients'), EntityType.client);
      expect(entityTypeForSearchGroup('client_contacts'), EntityType.client);
      expect(entityTypeForSearchGroup('invoices'), EntityType.invoice);
      expect(entityTypeForSearchGroup('quotes'), EntityType.quote);
      expect(entityTypeForSearchGroup('credits'), EntityType.credit);
      expect(entityTypeForSearchGroup('payments'), EntityType.payment);
      expect(
        entityTypeForSearchGroup('recurrings'),
        EntityType.recurringInvoice,
      );
      expect(
        entityTypeForSearchGroup('recurring_invoices'),
        EntityType.recurringInvoice,
      );
      expect(entityTypeForSearchGroup('projects'), EntityType.project);
      expect(entityTypeForSearchGroup('tasks'), EntityType.task);
      expect(entityTypeForSearchGroup('products'), EntityType.product);
      expect(entityTypeForSearchGroup('expenses'), EntityType.expense);
      expect(entityTypeForSearchGroup('vendors'), EntityType.vendor);
      expect(entityTypeForSearchGroup('vendor_contacts'), EntityType.vendor);
    });

    test('settings + unknown groups → null (caller uses server path)', () {
      expect(entityTypeForSearchGroup('settings'), isNull);
      expect(entityTypeForSearchGroup('whatever'), isNull);
      expect(entityTypeForSearchGroup(''), isNull);
    });
  });
}
