import 'package:admin/data/models/value/dashboard_filter.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardFilter', () {
    test('preset thisMonth resolves to the first/last day of the month', () {
      final today = const Date(2026, 5, 11);
      final range = const DashboardPresetRange(DashboardDatePreset.thisMonth);
      final (start, end) = range.resolve(today: today);
      expect(start, const Date(2026, 5, 1));
      expect(end, const Date(2026, 5, 31));
    });

    test('preset lastMonth wraps the year boundary', () {
      final today = const Date(2026, 1, 15);
      final range = const DashboardPresetRange(DashboardDatePreset.lastMonth);
      final (start, end) = range.resolve(today: today);
      expect(start, const Date(2025, 12, 1));
      expect(end, const Date(2025, 12, 31));
    });

    test('preset last7 is inclusive of today', () {
      final today = const Date(2026, 5, 11);
      final (start, end) = const DashboardPresetRange(
        DashboardDatePreset.last7,
      ).resolve(today: today);
      expect(start, const Date(2026, 5, 5));
      expect(end, today);
    });

    test('preset thisQuarter snaps to the calendar quarter', () {
      final today = const Date(2026, 5, 11);
      final (start, end) = const DashboardPresetRange(
        DashboardDatePreset.thisQuarter,
      ).resolve(today: today);
      expect(start, const Date(2026, 4, 1));
      expect(end, const Date(2026, 6, 30));
    });

    test('preset lastQuarter wraps to the previous year when needed', () {
      final today = const Date(2026, 2, 15);
      final (start, end) = const DashboardPresetRange(
        DashboardDatePreset.lastQuarter,
      ).resolve(today: today);
      expect(start, const Date(2025, 10, 1));
      expect(end, const Date(2025, 12, 31));
    });

    test('filterHash is stable across instances with the same fields', () {
      final today = const Date(2026, 5, 11);
      final a = DashboardFilter.defaults();
      final b = DashboardFilter.defaults();
      expect(a.filterHash(today: today), b.filterHash(today: today));
    });

    test('filterHash differs when any field changes', () {
      final today = const Date(2026, 5, 11);
      final base = DashboardFilter.defaults();
      expect(
        base.filterHash(today: today),
        isNot(equals(base.copyWith(currencyId: 1).filterHash(today: today))),
      );
      expect(
        base.filterHash(today: today),
        isNot(
          equals(base.copyWith(includeDrafts: true).filterHash(today: today)),
        ),
      );
    });

    test('filterHash carries a v1 prefix in its seed', () {
      // Different preset → different hash even when their resolved dates match.
      // We can't observe the seed directly; we verify the contract by hashing
      // two filters whose seeds would otherwise be identical except for kind.
      final today = const Date(2026, 5, 11);
      final p1 = DashboardFilter(
        range: const DashboardPresetRange(DashboardDatePreset.thisMonth),
      );
      final p2 = DashboardFilter(
        range: DashboardCustomRange(
          start: const Date(2026, 5, 1),
          end: const Date(2026, 5, 31),
        ),
      );
      expect(
        p1.filterHash(today: today),
        isNot(equals(p2.filterHash(today: today))),
      );
    });

    test('toJson / tryFromJson round-trips a preset filter', () {
      final original = DashboardFilter(
        range: const DashboardPresetRange(DashboardDatePreset.last30),
        currencyId: 2,
        includeDrafts: true,
      );
      final loaded = DashboardFilter.tryFromJson(original.toJson());
      expect(loaded, isNotNull);
      expect(loaded, equals(original));
    });

    test('toJson / tryFromJson round-trips a custom range', () {
      final original = DashboardFilter(
        range: DashboardCustomRange(
          start: const Date(2025, 1, 1),
          end: const Date(2025, 6, 30),
        ),
        currencyId: 1,
      );
      final loaded = DashboardFilter.tryFromJson(original.toJson());
      expect(loaded, isNotNull);
      expect(loaded, equals(original));
    });

    test('tryFromJson returns null on malformed input', () {
      expect(DashboardFilter.tryFromJson(null), isNull);
      expect(DashboardFilter.tryFromJson('not a map'), isNull);
      expect(
        DashboardFilter.tryFromJson(<String, dynamic>{'currencyId': 1}),
        isNull,
      );
    });
  });
}
