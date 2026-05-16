import 'package:admin/data/models/domain/tax_rate.dart';
import 'package:admin/data/repositories/tax_rate_repository.dart';
import 'package:admin/ui/core/edit/generic_edit_view_model.dart';

/// Drives the `/settings/tax_rates/new` + `/:id` edit screen. Optimistic —
/// `save()` lands the draft in Drift via the repo; the outbox handles the
/// server round-trip. Mirrors [PaymentTermEditViewModel].
class TaxRateEditViewModel extends GenericEditViewModel<TaxRate> {
  TaxRateEditViewModel({
    required this.repo,
    required this.companyId,
    TaxRate? existing,
  }) : super(initialDraft: existing ?? _emptyRate(), original: existing);

  final TaxRateRepository repo;
  final String companyId;

  @override
  bool draftIsNonEmpty() {
    final d = draft;
    return d.name.isNotEmpty || d.rate != 0;
  }

  @override
  Future<TaxRate> performSave() async {
    if (isCreate) {
      return repo.create(companyId: companyId, draft: draft);
    }
    await repo.save(companyId: companyId, rate: draft);
    return draft;
  }

  void resetToEmpty() => reset(emptyDraft: _emptyRate());

  void setName(String v) => updateDraft(draft.copyWith(name: v));
  void setRate(double v) => updateDraft(draft.copyWith(rate: v));
}

TaxRate _emptyRate() => TaxRate(
  id: '',
  name: '',
  rate: 0,
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  archivedAt: null,
  isDeleted: false,
);
