import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:admin/data/models/domain/expense_category.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/repositories/expense_category_repository.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/client_filter_key.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_keys_common.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';
import 'package:admin/ui/core/list/search/membership_filter_key.dart';

/// Build the filter keys exposed in the expenses list's search field.
///
/// Live server-side (May 2026 audit + 2026-05-17 source-read):
/// `client_id`, and `categories` (the canonical param —
/// `ExpenseFilters::categories`, CSV of category ids → `whereIn`).
/// `vendor_ids` / `project_ids` have **no** server method yet (genuine
/// backend gap — tracked in `BACKEND.md`); those pickers wait on backend
/// support.
List<FilterKey> buildExpenseFilterKeys({
  required ClientRepository clients,
  required ExpenseCategoryRepository categories,
  required String companyId,
  String? Function(String id)? nameForClientId,
}) => <FilterKey>[
  const IsFilterKey(),
  ClientFilterKey(
    clients: clients,
    companyId: companyId,
    nameForClientId: nameForClientId,
  ),
  ExpenseCategoryFilterKey(categories: categories, companyId: companyId),
];

/// `category:foo` — multi-valued, resolved through the expense-category
/// repository. `serverKey` is `categories` (`ExpenseFilters::categories` —
/// CSV of category ids → `whereIn('category_id', …)`).
///
/// Mirrors the Tasks `ProjectFilterKey` pattern: the suggestion menu
/// streams `(id, name)` from `ExpenseCategoryRepository.watchActive`, and
/// the same stream populates an in-memory `id → name` cache so chips show
/// the category name instead of the raw id.
class ExpenseCategoryFilterKey extends MembershipFilterKey {
  ExpenseCategoryFilterKey({required this.categories, required this.companyId}) {
    _namesSub = categories.watchActive(companyId: companyId).listen((rows) {
      _names
        ..clear()
        ..addEntries(rows.map((c) => MapEntry(c.id, c.name)));
    });
  }

  final ExpenseCategoryRepository categories;
  final String companyId;
  final Map<String, String> _names = <String, String>{};
  StreamSubscription<List<ExpenseCategory>>? _namesSub;

  @override
  String get id => 'category';

  @override
  String get serverKey => 'categories';

  /// Render checkboxes — inherits the single-write `selectExclusive` /
  /// `clear` from [MembershipFilterKey].
  @override
  bool get checkboxMultiSelect => true;

  @override
  String displayLabel(BuildContext context) => context.tr('category');

  @override
  String displayValueFor(String rawValue) {
    final cached = _names[rawValue];
    if (cached != null && cached.isNotEmpty) return cached;
    return rawValue;
  }

  @override
  Stream<List<FilterValueSuggestion>> watchValueSuggestions(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    return categories.watchActive(companyId: companyId).map((all) {
      final filtered = q.isEmpty
          ? all.take(50)
          : all.where((c) => c.name.toLowerCase().contains(q));
      return [
        for (final c in filtered)
          FilterValueSuggestion(
            rawValue: c.id,
            displayLabel: c.name.isEmpty ? c.id : c.name,
          ),
      ];
    });
  }

  /// Release the names-cache subscription when the key is replaced (e.g.
  /// company switch). `FilterKey` has no lifecycle hook today, so this
  /// lives until GC otherwise — same trade-off as Tasks `ProjectFilterKey`.
  void dispose() {
    _namesSub?.cancel();
    _namesSub = null;
  }
}
