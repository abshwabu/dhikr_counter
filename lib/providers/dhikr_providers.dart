import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_entry.dart';
import '../models/dhikr_set.dart';
import '../models/streak_data.dart';
import '../services/dhikr_repository.dart';
import '../services/streak_calculator.dart';

final dhikrRepositoryProvider = Provider<DhikrRepository>((ref) {
  return DhikrRepository();
});

// --- Dhikr sets ---

class DhikrSetsNotifier extends StateNotifier<List<DhikrSet>> {
  DhikrSetsNotifier(this._repository) : super(_repository.getAllDhikrSets());

  final DhikrRepository _repository;

  Future<void> add(DhikrSet dhikrSet) async {
    await _repository.addDhikrSet(dhikrSet);
    state = _repository.getAllDhikrSets();
  }

  Future<void> update(DhikrSet dhikrSet) async {
    await _repository.updateDhikrSet(dhikrSet);
    state = _repository.getAllDhikrSets();
  }

  Future<void> delete(String id) async {
    await _repository.deleteDhikrSet(id);
    state = _repository.getAllDhikrSets();
  }

  void refresh() {
    state = _repository.getAllDhikrSets();
  }
}

final dhikrSetsProvider =
    StateNotifierProvider<DhikrSetsNotifier, List<DhikrSet>>((ref) {
  return DhikrSetsNotifier(ref.watch(dhikrRepositoryProvider));
});

// --- Today's entries ---

class TodayEntriesNotifier extends StateNotifier<Map<String, DailyEntry>> {
  TodayEntriesNotifier(this._repository) : super(const {});

  final DhikrRepository _repository;

  Future<void> loadForSets(List<DhikrSet> sets) async {
    final entries = <String, DailyEntry>{};
    for (final set in sets) {
      entries[set.id] = await _repository.getEntryForToday(set.id);
    }
    state = entries;
  }

  Future<DailyEntry> increment(String dhikrSetId) async {
    final entry = await _repository.incrementCount(dhikrSetId);
    state = {...state, dhikrSetId: entry};
    return entry;
  }

  Future<DailyEntry> reset(String dhikrSetId) async {
    final entry = await _repository.resetToday(dhikrSetId);
    state = {...state, dhikrSetId: entry};
    return entry;
  }
}

final _todayEntriesNotifierProvider =
    StateNotifierProvider<TodayEntriesNotifier, Map<String, DailyEntry>>((ref) {
  final notifier = TodayEntriesNotifier(ref.watch(dhikrRepositoryProvider));

  ref.listen<List<DhikrSet>>(
    dhikrSetsProvider,
    (_, sets) => notifier.loadForSets(sets),
    fireImmediately: true,
  );

  return notifier;
});

/// Today's [DailyEntry] for each dhikr set, derived from [dhikrSetsProvider].
final todayEntriesProvider = Provider<Map<String, DailyEntry>>((ref) {
  return ref.watch(_todayEntriesNotifierProvider);
});

/// Use this for increment/reset so widgets never touch Hive directly.
final todayEntriesActionsProvider = Provider<TodayEntriesNotifier>((ref) {
  return ref.watch(_todayEntriesNotifierProvider.notifier);
});

// --- Streak ---

class StreakNotifier extends StateNotifier<StreakData> {
  StreakNotifier(this._repository)
      : super(
          _repository.getStreakData() ??
              StreakData(
                currentStreak: 0,
                longestStreak: 0,
                totalDaysCompleted: 0,
              ),
        );

  final DhikrRepository _repository;

  Future<void> save(StreakData data) async {
    await _repository.saveStreakData(data);
    state = data;
  }

  /// Applies streak update when all dhikr are done for [todayDateString].
  /// Returns updated data, or `null` if today was already counted.
  Future<StreakData?> recordDayComplete({String? todayDateString}) async {
    final today = todayDateString ?? _todayString();
    if (state.lastCompletedDate == today) {
      return null;
    }
    final updated = updateStreakOnCompletion(state, today);
    await save(updated);
    return updated;
  }

  static String _todayString() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void refresh() {
    state = _repository.getStreakData() ??
        StreakData(
          currentStreak: 0,
          longestStreak: 0,
          totalDaysCompleted: 0,
        );
  }
}

final streakProvider =
    StateNotifierProvider<StreakNotifier, StreakData>((ref) {
  return StreakNotifier(ref.watch(dhikrRepositoryProvider));
});

// --- Active dhikr (counter screen) ---

final activeDhikrIdProvider = StateProvider<String>((ref) => '');

/// All persisted daily entries; refreshes when today's entries change.
final allDailyEntriesProvider = Provider<List<DailyEntry>>((ref) {
  ref.watch(todayEntriesProvider);
  return ref.watch(dhikrRepositoryProvider).getAllDailyEntries();
});

/// Sum of every entry count ever recorded.
final totalDhikrCountProvider = Provider<int>((ref) {
  ref.watch(todayEntriesProvider);
  return ref.watch(dhikrRepositoryProvider).getTotalDhikrCount();
});
