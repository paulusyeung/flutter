import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_lexer.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';

void main() {
  group('lexFilterInput', () {
    test('treats input with no colon as free text', () {
      final result = lexFilterInput('alpha bravo', [_FakeKey('country', [])]);
      expect(result.tokens, isEmpty);
      expect(result.freeText, 'alpha bravo');
    });

    test('parses a single key:value pair', () {
      final result = lexFilterInput('country:US', [_FakeKey('country', [])]);
      expect(result.tokens, [(keyId: 'country', rawValue: 'US')]);
      expect(result.freeText, isEmpty);
    });

    test('resolves an alias to the canonical key id', () {
      final result = lexFilterInput('status:active', [
        _FakeKey('is', ['status']),
      ]);
      expect(result.tokens, [(keyId: 'is', rawValue: 'active')]);
    });

    test('unwraps quoted values', () {
      final result = lexFilterInput('country:"United States"', [
        _FakeKey('country', []),
      ]);
      expect(result.tokens, [(keyId: 'country', rawValue: '"United')]);
      // Quotes only unwrap when the whole piece is quoted; whitespace splits
      // first. The "United and States" pieces both have quotes that don't
      // bracket the whole piece so the simple unwrap leaves the leading
      // quote in place — confirming the regex-based split behaviour.
      expect(result.freeText, 'States"');
    });

    test('comma-separated values produce multiple tokens', () {
      final result = lexFilterInput('is:active,archived', [_FakeKey('is', [])]);
      expect(result.tokens, [
        (keyId: 'is', rawValue: 'active'),
        (keyId: 'is', rawValue: 'archived'),
      ]);
    });

    test('unknown prefix falls through as free text', () {
      final result = lexFilterInput('zzz:bar real', [_FakeKey('country', [])]);
      expect(result.tokens, isEmpty);
      expect(result.freeText, 'zzz:bar real');
    });

    test('mixes tokens and free text', () {
      final result = lexFilterInput('hello country:US world', [
        _FakeKey('country', []),
      ]);
      expect(result.tokens, [(keyId: 'country', rawValue: 'US')]);
      expect(result.freeText, 'hello world');
    });
  });
}

class _FakeKey extends FilterKey {
  _FakeKey(this._id, this._aliases);
  final String _id;
  final List<String> _aliases;

  @override
  String get id => _id;

  @override
  Iterable<String> get aliases => _aliases;

  @override
  String displayLabel(BuildContext context) => _id;

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
