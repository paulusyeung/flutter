import 'package:admin/data/models/domain/company_gateway.dart';
import 'package:admin/ui/features/gateways/gateway_order_writer.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pure-logic guards for the gateway display-ordering helpers that back the
/// company-scope list's saved-order presentation + "Default" badge.
void main() {
  group('firstGatewayId', () {
    test('null / empty / whitespace-only CSV → null', () {
      expect(firstGatewayId(null), isNull);
      expect(firstGatewayId(''), isNull);
      expect(firstGatewayId(' , '), isNull);
    });

    test('returns the first non-empty id, trimmed', () {
      expect(firstGatewayId('a,b,c'), 'a');
      expect(firstGatewayId(',a,b'), 'a');
      expect(firstGatewayId(' a , b '), 'a');
    });
  });

  group('orderGatewaysByCsv', () {
    CompanyGateway gw(String id) => CompanyGateway(id: id);
    List<String> ids(List<CompanyGateway> gws) => gws.map((g) => g.id).toList();

    test('empty CSV → items unchanged', () {
      final items = [gw('a'), gw('b')];
      expect(ids(orderGatewaysByCsv(items, '')), ['a', 'b']);
    });

    test('orders by CSV, trimming entries', () {
      final items = [gw('a'), gw('b'), gw('c')];
      expect(ids(orderGatewaysByCsv(items, 'c, a , b')), ['c', 'a', 'b']);
    });

    test('CSV items first; unreferenced items keep incoming order after', () {
      final items = [gw('a'), gw('b'), gw('c'), gw('d')];
      expect(ids(orderGatewaysByCsv(items, 'd,b')), ['d', 'b', 'a', 'c']);
    });

    test('ignores unknown ids and duplicate CSV entries — no drops/dupes', () {
      final items = [gw('a'), gw('b')];
      final out = orderGatewaysByCsv(items, 'x,b,y,a,b');
      expect(ids(out), ['b', 'a']);
      expect(out, hasLength(2));
    });
  });
}
