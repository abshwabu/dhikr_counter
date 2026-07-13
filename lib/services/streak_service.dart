import 'package:intl/intl.dart';

import '../models/streak_data.dart';

/// Pure streak day-completion logic (Step 9).
///
/// Call when every active dhikr set is completed for today.
/// Returns the updated data, or `null` if today was already recorded.
StreakData? updateStreakForCompletedDay(
  StreakData current, {
  DateTime? now,
}) {
  final today = DateFormat('yyyy-MM-dd').format(now ?? DateTime.now());

  if (current.lastCompletedDate == today) {
    return null;
  }

  final yesterday = DateFormat('yyyy-MM-dd').format(
    (now ?? DateTime.now()).subtract(const Duration(days: 1)),
  );

  final continued = current.lastCompletedDate == yesterday;
  final nextStreak = continued ? current.currentStreak + 1 : 1;
  final longest =
      nextStreak > current.longestStreak ? nextStreak : current.longestStreak;

  return StreakData(
    currentStreak: nextStreak,
    longestStreak: longest,
    lastCompletedDate: today,
    totalDaysCompleted: current.totalDaysCompleted + 1,
  );
}
