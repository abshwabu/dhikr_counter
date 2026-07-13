import 'package:hive/hive.dart';

part 'streak_data.g.dart';

@HiveType(typeId: 2)
class StreakData extends HiveObject {
  @HiveField(0)
  int currentStreak;

  @HiveField(1)
  int longestStreak;

  @HiveField(2)
  String? lastCompletedDate;

  @HiveField(3)
  int totalDaysCompleted;

  StreakData({
    required this.currentStreak,
    required this.longestStreak,
    this.lastCompletedDate,
    required this.totalDaysCompleted,
  });
}
