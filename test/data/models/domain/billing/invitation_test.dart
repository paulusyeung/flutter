import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/billing/invitation.dart';

void main() {
  test('freshClone keeps the contact ids and drops all transient state', () {
    const inv = Invitation(
      id: 'i1',
      key: 'k1',
      link: 'https://portal/x',
      clientContactId: 'cc1',
      vendorContactId: 'vc1',
      sentDate: '2026-01-01',
      viewedDate: '2026-01-02',
      openedDate: '2026-01-03',
      emailStatus: 'bounced',
      emailError: 'mailbox full',
      messageId: 'm1',
    );

    final fresh = inv.freshClone();

    // Recipient survives…
    expect(fresh.clientContactId, 'cc1');
    expect(fresh.vendorContactId, 'vc1');
    // …every per-send lifecycle field is wiped.
    expect(fresh.id, isEmpty);
    expect(fresh.key, isEmpty);
    expect(fresh.link, isEmpty);
    expect(fresh.sentDate, isEmpty);
    expect(fresh.viewedDate, isEmpty);
    expect(fresh.openedDate, isEmpty);
    expect(fresh.emailStatus, isEmpty);
    expect(fresh.emailError, isEmpty);
    expect(fresh.messageId, isEmpty);
    // A cloned draft must not inherit a bounce flag.
    expect(fresh.hasBounced, isFalse);
  });
}
