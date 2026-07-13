import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../services/day_boundary.dart';
import '../services/dhikr_repository.dart';
import '../services/reminder_service.dart';
import '../services/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService.instance;
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._repository) : super(_repository.load());

  final SettingsRepository _repository;

  DhikrRepository _repoForReminders() {
    return DhikrRepository(
      todayProvider: () => computeCurrentDateKey(state),
    );
  }

  Future<void> _persistAndSyncReminders() async {
    await _repository.save(state);
    await ReminderService.instance.sync(
      settings: state,
      repository: _repoForReminders(),
    );
  }

  Future<void> setHapticEnabled(bool enabled) async {
    state = state.copyWith(hapticEnabled: enabled);
    await _repository.save(state);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    state = state.copyWith(soundEnabled: enabled);
    await _repository.save(state);
  }

  Future<void> setDayResetMode(DayResetMode mode) async {
    state = state.copyWith(dayResetMode: mode);
    await _persistAndSyncReminders();
  }

  Future<void> setLocation({
    required double latitude,
    required double longitude,
    String? locationLabel,
  }) async {
    state = state.copyWith(
      latitude: latitude,
      longitude: longitude,
      locationLabel: locationLabel,
    );
    await _persistAndSyncReminders();
  }

  /// Enables reminders after requesting OS permission. Returns false if denied.
  Future<bool> setReminderEnabled(bool enabled) async {
    if (enabled) {
      final granted = await ReminderService.instance.requestPermissions();
      if (!granted) {
        state = state.copyWith(reminderEnabled: false);
        await _repository.save(state);
        return false;
      }
    }
    state = state.copyWith(reminderEnabled: enabled);
    await _persistAndSyncReminders();
    return true;
  }

  Future<void> setReminderTime({required int hour, required int minute}) async {
    state = state.copyWith(reminderHour: hour, reminderMinute: minute);
    await _persistAndSyncReminders();
  }

  Future<void> refresh() async {
    state = _repository.load();
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(settingsRepositoryProvider));
});

/// Today's application date key, respecting midnight vs Fajr reset.
final currentDateKeyProvider = Provider<String>((ref) {
  final settings = ref.watch(settingsProvider);
  return computeCurrentDateKey(settings);
});

/// Next Fajr time when that reset mode is active.
final nextFajrProvider = Provider<DateTime?>((ref) {
  return nextFajrTime(ref.watch(settingsProvider));
});

Future<void> playTapFeedback(WidgetRef ref, {bool stronger = false}) async {
  final settings = ref.read(settingsProvider);
  if (settings.hapticEnabled) {
    if (stronger) {
      await HapticFeedback.mediumImpact();
    } else {
      await HapticFeedback.lightImpact();
    }
  }
  if (settings.soundEnabled) {
    await SystemSound.play(SystemSoundType.click);
  }
}
