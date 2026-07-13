import 'package:hive/hive.dart';

part 'daily_entry.g.dart';

@HiveType(typeId: 1)
class DailyEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String date;

  @HiveField(2)
  String dhikrSetId;

  @HiveField(3)
  int count;

  @HiveField(4)
  DateTime? completedAt;

  DailyEntry({
    required this.id,
    required this.date,
    required this.dhikrSetId,
    required this.count,
    this.completedAt,
  });
}
