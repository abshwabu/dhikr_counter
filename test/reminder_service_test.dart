import 'package:dhikr_counter/services/reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  });

  group('nextReminderDateTime', () {
    test('schedules today when reminder time is still ahead', () {
      final now = tz.TZDateTime.utc(2026, 7, 13, 10, 0);
      final next = ReminderService.nextReminderDateTime(
        hour: 20,
        minute: 0,
        now: now,
      );
      expect(next, tz.TZDateTime.utc(2026, 7, 13, 20, 0));
    });

    test('rolls to tomorrow when reminder time already passed', () {
      final now = tz.TZDateTime.utc(2026, 7, 13, 21, 0);
      final next = ReminderService.nextReminderDateTime(
        hour: 20,
        minute: 0,
        now: now,
      );
      expect(next, tz.TZDateTime.utc(2026, 7, 14, 20, 0));
    });

    test('skips today when streak is already complete', () {
      final now = tz.TZDateTime.utc(2026, 7, 13, 10, 0);
      final next = ReminderService.nextReminderDateTime(
        hour: 20,
        minute: 0,
        skipToday: true,
        now: now,
      );
      expect(next, tz.TZDateTime.utc(2026, 7, 14, 20, 0));
    });
  });
}
