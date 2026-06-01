import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';

/// Regression coverage for the payload note-search helper
/// (`payloadJsonLike`, used by `QuoteDao.notesLikePayload`). The old
/// implementation string-interpolated the raw search term into a SQL `LIKE`
/// literal, so an apostrophe broke the query and the term was injectable.
/// The term must now be a bound parameter: a literal `'` matches as data,
/// and SQL metacharacters never alter the query's logic.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  QuotesCompanion quote({
    required String id,
    String companyId = 'co',
    String publicNotes = '',
    String privateNotes = '',
  }) => QuotesCompanion.insert(
    id: id,
    companyId: companyId,
    updatedAt: 1,
    payload: jsonEncode({
      'public_notes': publicNotes,
      'private_notes': privateNotes,
    }),
  );

  Future<List<String>> search(String term) => db.quoteDao
      .watchPage(companyId: 'co', offset: 0, limit: 50, search: term)
      .first
      .then((rows) => rows.map((r) => r.id).toList()..sort());

  test(
    'apostrophe in the search term matches as a literal, never throws',
    () async {
      await db.quoteDao.upsert(
        quote(id: 'a', publicNotes: "O'Brien consulting retainer"),
      );
      await db.quoteDao.upsert(quote(id: 'b', publicNotes: 'unrelated'));

      expect(await search("O'Brien"), ['a']);
      expect(await search("o'br"), ['a']);
    },
  );

  test(
    'injection payload is treated as a literal substring, not SQL',
    () async {
      // None of these rows contain the literal injection string, so a
      // correctly-parameterized query returns nothing. The old interpolated
      // form would have made `x' OR '1'='1` a tautology and returned every row.
      await db.quoteDao.upsert(quote(id: 'a', publicNotes: 'alpha'));
      await db.quoteDao.upsert(quote(id: 'b', privateNotes: 'beta'));

      expect(await search("x' OR '1'='1"), isEmpty);
      expect(await search("'; DROP TABLE quotes; --"), isEmpty);

      // The table is intact and normal search still works afterwards.
      expect(await search('alpha'), ['a']);

      // A row that genuinely contains the quote-bearing text is still found.
      await db.quoteDao.upsert(
        quote(id: 'c', privateNotes: "note with x' OR '1'='1 inside"),
      );
      expect(await search("x' OR '1'='1"), ['c']);
    },
  );

  test('matches public and private notes, scoped to the company', () async {
    await db.quoteDao.upsert(quote(id: 'a', publicNotes: 'shared keyword'));
    await db.quoteDao.upsert(quote(id: 'b', privateNotes: 'shared keyword'));
    await db.quoteDao.upsert(
      quote(id: 'x', companyId: 'other', publicNotes: 'shared keyword'),
    );

    expect(await search('shared keyword'), ['a', 'b']);
  });
}
