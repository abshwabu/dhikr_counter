import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_settings.dart';
import '../models/daily_entry.dart';
import '../models/dhikr_set.dart';
import 'dhikr_repository.dart';
import 'streak_calculator.dart';

/// Offline daily reminders via [flutter_local_notifications].
///
/// Reminders only fire when today's streak is still incomplete. Completing
/// all dhikr cancels today's pending reminder and rolls the schedule to
/// tomorrow so a finished day stays quiet.
class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();

  static const _channelId = 'dhikr_daily_reminder';
  static const _channelName = 'Daily dhikr reminder';
  static const _notificationId = 1001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || kIsWeb) return;

    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Fall back to UTC if timezone plugin isn't ready (needs full restart).
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: android,
      iOS: ios,
      macOS: ios,
    );

    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    if (!_initialized) await init();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    final mac = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    if (mac != null) {
      final granted = await mac.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  Future<void> sync({
    required AppSettings settings,
    required DhikrRepository repository,
  }) async {
    if (kIsWeb) return;
    try {
      if (!_initialized) await init();

      if (!settings.reminderEnabled) {
        await cancel();
        return;
      }

      final dayComplete = isTodayComplete(repository);
      await scheduleDaily(
        hour: settings.reminderHour,
        minute: settings.reminderMinute,
        body: buildBody(repository, dayComplete: dayComplete),
        skipToday: dayComplete,
      );
    } catch (error) {
      debugPrint('ReminderService.sync failed: $error');
    }
  }

  /// True when every dhikr set has hit its target for the app's current day.
  bool isTodayComplete(DhikrRepository repository) {
    final sets = repository.getAllDhikrSets();
    final today = repository.currentDateKey();
    final entries = repository
        .getAllDailyEntries()
        .where((entry) => entry.date == today)
        .toList();
    return isDayComplete(sets, entries);
  }

  /// Builds reminder copy from current Hive data when available.
  String buildBody(
    DhikrRepository repository, {
    bool? dayComplete,
  }) {
    try {
      final sets = repository.getAllDhikrSets();
      if (sets.isEmpty) {
        return 'Take a quiet moment for your daily dhikr.';
      }

      final today = repository.currentDateKey();
      final todayEntries = repository
          .getAllDailyEntries()
          .where((entry) => entry.date == today)
          .toList();
      final complete = dayComplete ?? isDayComplete(sets, todayEntries);

      // Next fire is tomorrow after a finished day — keep copy generic.
      if (complete) {
        return 'Your daily dhikr is waiting — a few quiet moments go a long way.';
      }

      final bySetId = <String, DailyEntry>{
        for (final entry in todayEntries) entry.dhikrSetId: entry,
      };

      var completed = 0;
      for (final set in sets) {
        final entry = bySetId[set.id];
        if (entry != null && entry.count >= set.targetCount) {
          completed++;
        }
      }

      return 'Your dhikr streak is waiting — $completed of ${sets.length} sets done today';
    } catch (_) {
      return 'Your daily dhikr is waiting — a few quiet moments go a long way.';
    }
  }

  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required String body,
    bool skipToday = false,
  }) async {
    await cancel();

    final scheduled = nextReminderDateTime(
      hour: hour,
      minute: minute,
      skipToday: skipToday,
    );
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Local daily reminder to complete dhikr',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id: _notificationId,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: 'Dhikr Counter',
      body: body,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel() async {
    if (!_initialized) return;
    await _plugin.cancel(id: _notificationId);
  }

  /// Next local fire time. When [skipToday] is true (streak already done),
  /// always rolls to tomorrow even if today's reminder hour is still ahead.
  static tz.TZDateTime nextReminderDateTime({
    required int hour,
    required int minute,
    bool skipToday = false,
    tz.TZDateTime? now,
  }) {
    final current = now ?? tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      current.location,
      current.year,
      current.month,
      current.day,
      hour,
      minute,
    );
    if (skipToday || !scheduled.isAfter(current)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

/// Convenience for callers that only have sets/entries maps.
String reminderBodyFromProgress({
  required List<DhikrSet> sets,
  required Map<String, DailyEntry> todayEntries,
}) {
  if (sets.isEmpty) {
    return 'Take a quiet moment for your daily dhikr.';
  }
  var completed = 0;
  for (final set in sets) {
    final entry = todayEntries[set.id];
    if (entry != null && entry.count >= set.targetCount) {
      completed++;
    }
  }
  return 'Your dhikr streak is waiting — $completed of ${sets.length} sets done today';
}
