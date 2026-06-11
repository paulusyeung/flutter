import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/company_settings_api_model.dart';
import 'package:admin/data/models/domain/company_settings.dart';
import 'package:admin/ui/features/settings/view_models/design_update_all_mixin.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';

/// Minimal host exposing just the three surfaces [DesignUpdateAllMixin] reads
/// ([isCascadeScope], [draftSettings], [initialSettings]) so the mixin's
/// scope-aware entity list and change detection can be exercised without a
/// repository, DB, or the shell.
class _FakeHost extends SettingsDraftHost with DesignUpdateAllMixin {
  _FakeHost({
    required this.cascade,
    required CompanySettings draft,
    required CompanySettings baseline,
  }) : _draft = draft,
       _baseline = baseline;

  final bool cascade;
  final CompanySettings _draft;
  final CompanySettings _baseline;

  @override
  bool get isCascadeScope => cascade;
  @override
  CompanySettings get draftSettings => _draft;
  @override
  CompanySettings get initialSettings => _baseline;

  // Unused abstract surface.
  @override
  Map<String, List<String>> get fieldErrors => const {};
  @override
  bool get isLoaded => true;
  @override
  bool get isDirty => false;
  @override
  bool get isSaving => false;
  @override
  String? get loadError => null;
  @override
  String? get submitError => null;
  @override
  void reset() {}
  @override
  Future<Object?> save() async => null;
  @override
  Future<void> load() async {}
}

void main() {
  group('designUpdateEntities (scope-aware)', () {
    test(
      'company scope offers all four document designs incl. purchase_order',
      () {
        final host = _FakeHost(
          cascade: false,
          draft: const CompanySettingsApi(),
          baseline: const CompanySettingsApi(),
        );
        expect(host.designUpdateEntities, [
          'invoice',
          'quote',
          'credit',
          'purchase_order',
        ]);
      },
    );

    test('client/group (cascade) scope drops purchase_order — PO designs are '
        'company-scoped server-side', () {
      final host = _FakeHost(
        cascade: true,
        draft: const CompanySettingsApi(),
        baseline: const CompanySettingsApi(),
      );
      expect(host.designUpdateEntities, ['invoice', 'quote', 'credit']);
      expect(host.designUpdateEntities, isNot(contains('purchase_order')));
    });
  });

  group('changedDesignUpdates', () {
    test('emits ticked + changed directives, skips unchanged/empty', () {
      final host = _FakeHost(
        cascade: false,
        draft: const CompanySettingsApi(
          invoiceDesignId: 'B',
          quoteDesignId: 'Q', // unchanged → skipped
        ),
        baseline: const CompanySettingsApi(
          invoiceDesignId: 'A',
          quoteDesignId: 'Q',
        ),
      );
      host.setUpdateAll('invoice', true);
      host.setUpdateAll('quote', true); // ticked but unchanged

      expect(host.changedDesignUpdates(), [
        {'design_id': 'B', 'entity': 'invoice'},
      ]);
    });

    test('a tmp_ design id is skipped (server 400s on an unknown id)', () {
      final host = _FakeHost(
        cascade: false,
        draft: const CompanySettingsApi(invoiceDesignId: 'tmp_123'),
        baseline: const CompanySettingsApi(invoiceDesignId: 'A'),
      );
      host.setUpdateAll('invoice', true);
      expect(host.changedDesignUpdates(), isEmpty);
    });

    test('at cascade scope, a fresh override (baseline null → explicit) is a '
        'real change and emits a directive', () {
      final host = _FakeHost(
        cascade: true,
        // Own sparse draft: invoice overridden to X; baseline inherits (null).
        draft: const CompanySettingsApi(invoiceDesignId: 'X'),
        baseline: const CompanySettingsApi(),
      );
      host.setUpdateAll('invoice', true);
      expect(host.changedDesignUpdates(), [
        {'design_id': 'X', 'entity': 'invoice'},
      ]);
    });

    test('purchase_order is never emitted at cascade scope even if ticked + '
        'changed', () {
      final host = _FakeHost(
        cascade: true,
        draft: const CompanySettingsApi(purchaseOrderDesignId: 'P2'),
        baseline: const CompanySettingsApi(purchaseOrderDesignId: 'P1'),
      );
      host.setUpdateAll('purchase_order', true);
      expect(host.changedDesignUpdates(), isEmpty);
    });

    test('clearUpdateAll resets the one-shot flags', () {
      final host = _FakeHost(
        cascade: false,
        draft: const CompanySettingsApi(invoiceDesignId: 'B'),
        baseline: const CompanySettingsApi(invoiceDesignId: 'A'),
      );
      host.setUpdateAll('invoice', true);
      expect(host.changedDesignUpdates(), isNotEmpty);
      host.clearUpdateAll();
      expect(host.changedDesignUpdates(), isEmpty);
    });
  });
}
