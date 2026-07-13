import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_entry.dart';
import '../models/dhikr_set.dart';
import '../models/streak_data.dart';
import '../services/dhikr_repository.dart';
import '../services/streak_service.dart';

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

  /// Applies the Step 9 streak update when all dhikr are done for today.
  /// Returns the new streak when updated, or `null` if already counted today.
  Future<StreakData?> recordDayComplete() async {
    final updated = updateStreakForCompletedDay(state);
    if (updated == null) return null;
    await save(updated);
    return updated;
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
