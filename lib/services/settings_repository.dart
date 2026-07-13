import 'package:hive/hive.dart';

import '../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository({Box? settingsBox})
      : _box = settingsBox ?? Hive.box('settings');

  static const hapticKey = 'hapticEnabled';
  static const soundKey = 'soundEnabled';
  static const dayResetKey = 'dayResetMode';
  static const latitudeKey = 'latitude';
  static const longitudeKey = 'longitude';
  static const locationLabelKey = 'locationLabel';
  static const reminderEnabledKey = 'reminderEnabled';
  static const reminderHourKey = 'reminderHour';
  static const reminderMinuteKey = 'reminderMinute';

  final Box _box;

  AppSettings load() {
    final modeName = _box.get(dayResetKey) as String?;
    final mode = modeName == DayResetMode.fajr.name
        ? DayResetMode.fajr
        : DayResetMode.midnight;

    return AppSettings(
      hapticEnabled: _box.get(hapticKey, defaultValue: true) as bool,
      soundEnabled: _box.get(soundKey, defaultValue: false) as bool,
      dayResetMode: mode,
      latitude: (_box.get(latitudeKey) as num?)?.toDouble(),
      longitude: (_box.get(longitudeKey) as num?)?.toDouble(),
      locationLabel: _box.get(locationLabelKey) as String?,
      reminderEnabled: _box.get(reminderEnabledKey, defaultValue: false) as bool,
      reminderHour: _box.get(reminderHourKey, defaultValue: 20) as int,
      reminderMinute: _box.get(reminderMinuteKey, defaultValue: 0) as int,
    );
  }

  Future<void> save(AppSettings settings) async {
    await _box.put(hapticKey, settings.hapticEnabled);
    await _box.put(soundKey, settings.soundEnabled);
    await _box.put(dayResetKey, settings.dayResetMode.name);
    await _box.put(reminderEnabledKey, settings.reminderEnabled);
    await _box.put(reminderHourKey, settings.reminderHour);
    await _box.put(reminderMinuteKey, settings.reminderMinute);
    if (settings.latitude != null && settings.longitude != null) {
      await _box.put(latitudeKey, settings.latitude);
      await _box.put(longitudeKey, settings.longitude);
      if (settings.locationLabel != null) {
        await _box.put(locationLabelKey, settings.locationLabel);
      } else {
        await _box.delete(locationLabelKey);
      }
    } else {
      await _box.delete(latitudeKey);
      await _box.delete(longitudeKey);
      await _box.delete(locationLabelKey);
    }
  }
}
