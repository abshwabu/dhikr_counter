import 'package:dhikr_counter/models/daily_entry.dart';
import 'package:dhikr_counter/models/dhikr_set.dart';
import 'package:dhikr_counter/models/streak_data.dart';
import 'package:dhikr_counter/services/streak_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

DhikrSet _set({
  required String id,
  required int targetCount,
}) {
  return DhikrSet(
    id: id,
    arabic: 'ذكر',
    transliteration: id,
    translation: id,
    targetCount: targetCount,
    isCustom: false,
    colorHex: '#1B5E20',
    createdAt: DateTime(2026, 1, 1),
  );
}

DailyEntry _entry({
  required String setId,
  required int count,
  String date = '2026-07-13',
}) {
  return DailyEntry(
    id: 'entry-$setId',
    date: date,
    dhikrSetId: setId,
    count: count,
  );
}

void main() {
  group('isDayComplete', () {
    test('false when a set is missing an entry', () {
      final sets = [_set(id: 'a', targetCount: 33), _set(id: 'b', targetCount: 33)];
      final entries = [_entry(setId: 'a', count: 33)];
      expect(isDayComplete(sets, entries), isFalse);
    });

    test('false when an entry is under target', () {
      final sets = [_set(id: 'a', targetCount: 33)];
      final entries = [_entry(setId: 'a', count: 32)];
      expect(isDayComplete(sets, entries), isFalse);
    });

    test('true when every set meets its target', () {
      final sets = [
        _set(id: 'a', targetCount: 33),
        _set(id: 'b', targetCount: 100),
      ];
      final entries = [
        _entry(setId: 'a', count: 33),
        _entry(setId: 'b', count: 100),
      ];
      expect(isDayComplete(sets, entries), isTrue);
    });
  });

  group('updateStreakOnCompletion', () {
    test('first ever completion starts streak at 1', () {
      final current = StreakData(
        currentStreak: 0,
        longestStreak: 0,
        totalDaysCompleted: 0,
      );

      final updated = updateStreakOnCompletion(current, '2026-07-13');

      expect(updated.currentStreak, 1);
      expect(updated.longestStreak, 1);
      expect(updated.lastCompletedDate, '2026-07-13');
      expect(updated.totalDaysCompleted, 1);
    });

    test('consecutive day increments the streak', () {
      final current = StreakData(
        currentStreak: 3,
        longestStreak: 5,
        lastCompletedDate: '2026-07-12',
        totalDaysCompleted: 10,
      );

      final updated = updateStreakOnCompletion(current, '2026-07-13');

      expect(updated.currentStreak, 4);
      expect(updated.longestStreak, 5);
      expect(updated.lastCompletedDate, '2026-07-13');
      expect(updated.totalDaysCompleted, 11);
    });

    test('missed a day resets current streak to 1', () {
      final current = StreakData(
        currentStreak: 4,
        longestStreak: 7,
        lastCompletedDate: '2026-07-10',
        totalDaysCompleted: 12,
      );

      final updated = updateStreakOnCompletion(current, '2026-07-13');

      expect(updated.currentStreak, 1);
      expect(updated.longestStreak, 7);
      expect(updated.lastCompletedDate, '2026-07-13');
      expect(updated.totalDaysCompleted, 13);
    });

    test('same-day double completion does not double count', () {
      final current = StreakData(
        currentStreak: 2,
        longestStreak: 4,
        lastCompletedDate: '2026-07-13',
        totalDaysCompleted: 8,
      );

      final updated = updateStreakOnCompletion(current, '2026-07-13');

      expect(updated.currentStreak, 2);
      expect(updated.longestStreak, 4);
      expect(updated.lastCompletedDate, '2026-07-13');
      expect(updated.totalDaysCompleted, 8);
    });

    test('new streak longer than longest updates longestStreak', () {
      final current = StreakData(
        currentStreak: 5,
        longestStreak: 5,
        lastCompletedDate: '2026-07-12',
        totalDaysCompleted: 20,
      );

      final updated = updateStreakOnCompletion(current, '2026-07-13');

      expect(updated.currentStreak, 6);
      expect(updated.longestStreak, 6);
      expect(updated.totalDaysCompleted, 21);
    });
  });
}
