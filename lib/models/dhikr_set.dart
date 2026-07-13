import 'package:hive/hive.dart';

part 'dhikr_set.g.dart';

@HiveType(typeId: 0)
class DhikrSet extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String arabic;

  @HiveField(2)
  String transliteration;

  @HiveField(3)
  String translation;

  @HiveField(4)
  int targetCount;

  @HiveField(5)
  bool isCustom;

  @HiveField(6)
  String colorHex;

  @HiveField(7)
  DateTime createdAt;

  DhikrSet({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.targetCount,
    required this.isCustom,
    required this.colorHex,
    required this.createdAt,
  });
}
