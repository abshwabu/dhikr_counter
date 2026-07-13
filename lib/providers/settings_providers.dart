import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../services/day_boundary.dart';
import '../services/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._repository) : super(_repository.load());

  final SettingsRepository _repository;

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
    await _repository.save(state);
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
    await _repository.save(state);
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
