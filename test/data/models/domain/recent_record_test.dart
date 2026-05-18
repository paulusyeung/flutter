import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/recent_record.dart';
import 'package:admin/domain/entity_type.dart';

void main() {
  test('toJson / tryFromJson round-trips', () {
    final r = RecentRecord(
      type: EntityType.invoice,
      id: 'i1',
      label: '#1001',
      viewedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );
    final back = RecentRecord.tryFromJson(r.toJson())!;
    expect(back.type, EntityType.invoice);
    expect(back.id, 'i1');
    expect(back.label, '#1001');
    expect(back.viewedAt, r.viewedAt);
  });

  test('sameEntity matches on type + id only', () {
    final a = RecentRecord(
      type: EntityType.client,
      id: 'c1',
      label: 'Acme',
      viewedAt: _epoch,
    );
    final b = RecentRecord(
      type: EntityType.client,
      id: 'c1',
      label: 'Acme Inc',
      viewedAt: _epoch,
    );
    final c = RecentRecord(
      type: EntityType.invoice,
      id: 'c1',
      label: 'x',
      viewedAt: _epoch,
    );
    expect(a.sameEntity(b), isTrue);
    expect(a.sameEntity(c), isFalse);
  });

  test('tryFromJson rejects bad shapes', () {
    expect(RecentRecord.tryFromJson('nope'), isNull);
    expect(RecentRecord.tryFromJson({'t': 'client'}), isNull); // no id
    expect(
      RecentRecord.tryFromJson({'t': 'no_such', 'i': 'x'}),
      isNull,
    );
    expect(
      RecentRecord.tryFromJson({'t': 'client', 'i': ''}),
      isNull,
    );
  });
}

final _epoch = DateTime.fromMillisecondsSinceEpoch(0);
