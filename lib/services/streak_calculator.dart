import '../models/daily_entry.dart';
import '../models/dhikr_set.dart';
import '../models/streak_data.dart';

/// Returns true only when every [sets] item has a matching entry with
/// `count >= targetCount`.
bool isDayComplete(List<DhikrSet> sets, List<DailyEntry> entriesForThatDay) {
  if (sets.isEmpty) return false;

  final bySetId = <String, DailyEntry>{
    for (final entry in entriesForThatDay) entry.dhikrSetId: entry,
  };

  for (final set in sets) {
    final entry = bySetId[set.id];
    if (entry == null || entry.count < set.targetCount) {
      return false;
    }
  }
  return true;
}

/// Updates streak state after a newly completed day.
///
/// - [todayDateString] already counted → unchanged (no double count)
/// - yesterday → increment [StreakData.currentStreak]
/// - gap / null → reset [StreakData.currentStreak] to 1
///
/// On a new completion, always bumps [StreakData.totalDaysCompleted] and
/// sets [StreakData.longestStreak] to `max(longest, current)`.
StreakData updateStreakOnCompletion(
  StreakData current,
  String todayDateString,
) {
  if (current.lastCompletedDate == todayDateString) {
    return current;
  }

  final yesterday = _yesterdayOf(todayDateString);
  final continued = current.lastCompletedDate == yesterday;
  final nextStreak = continued ? current.currentStreak + 1 : 1;
  final longest =
      nextStreak > current.longestStreak ? nextStreak : current.longestStreak;

  return StreakData(
    currentStreak: nextStreak,
    longestStreak: longest,
    lastCompletedDate: todayDateString,
    totalDaysCompleted: current.totalDaysCompleted + 1,
  );
}

String _yesterdayOf(String dateString) {
  final date = DateTime.parse(dateString);
  final yesterday = date.subtract(const Duration(days: 1));
  final y = yesterday.year.toString().padLeft(4, '0');
  final m = yesterday.month.toString().padLeft(2, '0');
  final d = yesterday.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
