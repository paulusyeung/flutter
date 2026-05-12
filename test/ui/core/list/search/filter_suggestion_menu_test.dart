import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_suggestion_menu.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the alphabetical sort order the key dropdown uses. The full menu
/// pump (`FilterSuggestionMenu` + controller + vm) is heavier than the
/// file-level test policy in `token_search_field_test.dart` allows, so
/// the inline sort in `_KeyList.build` is delegated to the testable
/// top-level [compareFilterKeysByLabel] helper and unit-tested here.

class _StaticLabelKey extends FilterKey {
  const _StaticLabelKey(this._label);

  final String _label;

  @override
  String get id => _label.toLowerCase();

  @override
  String displayLabel(BuildContext context) => _label;

  @override
  FilterValueType get valueType => FilterValueType.string;

  @override
  bool isAtDefault(GenericListViewModel<dynamic> vm) => true;

  @override
  Iterable<FilterToken> tokensFrom(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
  ) => const [];

  @override
  Stream<List<FilterValueSuggestion>> watchValueSuggestions(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
    String query,
  ) => Stream.value(const []);

  @override
  Future<void> addValue(GenericListViewModel<dynamic> vm, String rawValue) =>
      Future.value();

  @override
  Future<void> removeValue(GenericListViewModel<dynamic> vm, String rawValue) =>
      Future.value();
}

void main() {
  testWidgets(
    'compareFilterKeysByLabel sorts alphabetically (case-insensitive)',
    (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final keys = <FilterKey>[
        const _StaticLabelKey('Banana'),
        const _StaticLabelKey('apple'),
        const _StaticLabelKey('Cherry'),
      ];

      keys.sort((a, b) => compareFilterKeysByLabel(a, b, capturedContext));

      expect(
        keys.map((k) => k.displayLabel(capturedContext)).toList(),
        ['apple', 'Banana', 'Cherry'],
        reason: 'Case-insensitive A→Z order regardless of registry order',
      );
    },
  );
}
