import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/daily_entry.dart';
import '../models/dhikr_set.dart';
import '../models/streak_data.dart';

class DhikrRepository {
  DhikrRepository({
    Box<DhikrSet>? dhikrSetsBox,
    Box<DailyEntry>? dailyEntriesBox,
    Box<StreakData>? streakBox,
    Uuid? uuid,
  })  : _dhikrSetsBox = dhikrSetsBox ?? Hive.box<DhikrSet>('dhikrSets'),
        _dailyEntriesBox =
            dailyEntriesBox ?? Hive.box<DailyEntry>('dailyEntries'),
        _streakBox = streakBox ?? Hive.box<StreakData>('streak'),
        _uuid = uuid ?? const Uuid();

  static const _streakKey = 'data';
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  final Box<DhikrSet> _dhikrSetsBox;
  final Box<DailyEntry> _dailyEntriesBox;
  final Box<StreakData> _streakBox;
  final Uuid _uuid;

  List<DhikrSet> getAllDhikrSets() => _dhikrSetsBox.values.toList();

  Future<void> addDhikrSet(DhikrSet dhikrSet) async {
    await _dhikrSetsBox.put(dhikrSet.id, dhikrSet);
  }

  Future<void> updateDhikrSet(DhikrSet dhikrSet) async {
    await _dhikrSetsBox.put(dhikrSet.id, dhikrSet);
  }

  Future<void> deleteDhikrSet(String id) async {
    await _dhikrSetsBox.delete(id);
  }

  Future<DailyEntry> getEntryForToday(String dhikrSetId) async {
    final today = _todayString();
    final key = _entryKey(dhikrSetId, today);
    final existing = _dailyEntriesBox.get(key);
    if (existing != null) {
      return existing;
    }

    final entry = DailyEntry(
      id: _uuid.v4(),
      date: today,
      dhikrSetId: dhikrSetId,
      count: 0,
    );
    await _dailyEntriesBox.put(key, entry);
    return entry;
  }

  Future<DailyEntry> incrementCount(String dhikrSetId) async {
    final entry = await getEntryForToday(dhikrSetId);
    entry.count += 1;

    final dhikrSet = _dhikrSetsBox.get(dhikrSetId);
    if (dhikrSet != null && entry.count >= dhikrSet.targetCount) {
      entry.completedAt = DateTime.now();
    }

    await _dailyEntriesBox.put(_entryKey(dhikrSetId, entry.date), entry);
    return entry;
  }

  Future<DailyEntry> resetToday(String dhikrSetId) async {
    final entry = await getEntryForToday(dhikrSetId);
    entry.count = 0;
    entry.completedAt = null;
    await _dailyEntriesBox.put(_entryKey(dhikrSetId, entry.date), entry);
    return entry;
  }

  StreakData? getStreakData() => _streakBox.get(_streakKey);

  Future<void> saveStreakData(StreakData streakData) async {
    await _streakBox.put(_streakKey, streakData);
  }

  List<DailyEntry> getAllDailyEntries() => _dailyEntriesBox.values.toList();

  int getTotalDhikrCount() =>
      _dailyEntriesBox.values.fold<int>(0, (sum, entry) => sum + entry.count);

  String _todayString() => _dateFormat.format(DateTime.now());

  String _entryKey(String dhikrSetId, String date) => '$dhikrSetId|$date';
}
