import 'package:adhan/adhan.dart';

import '../models/app_settings.dart';

/// Returns Fajr for [date] at the given coordinates (local time).
DateTime fajrForDate({
  required double latitude,
  required double longitude,
  required DateTime date,
}) {
  final coordinates = Coordinates(latitude, longitude);
  final params = CalculationMethod.muslim_world_league.getParameters();
  params.madhab = Madhab.shafi;
  final components = DateComponents(date.year, date.month, date.day);
  return PrayerTimes(coordinates, components, params).fajr;
}

/// Application "today" key (`yyyy-MM-dd`) based on midnight or Fajr.
String computeCurrentDateKey(
  AppSettings settings, {
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final calendarDay = DateTime(current.year, current.month, current.day);

  if (settings.dayResetMode == DayResetMode.midnight || !settings.hasLocation) {
    return _format(calendarDay);
  }

  final fajrToday = fajrForDate(
    latitude: settings.latitude!,
    longitude: settings.longitude!,
    date: calendarDay,
  );

  if (current.isBefore(fajrToday)) {
    final previous = calendarDay.subtract(const Duration(days: 1));
    return _format(previous);
  }
  return _format(calendarDay);
}

/// Next Fajr after [now], if Fajr mode and location are available.
DateTime? nextFajrTime(AppSettings settings, {DateTime? now}) {
  if (settings.dayResetMode != DayResetMode.fajr || !settings.hasLocation) {
    return null;
  }
  final current = now ?? DateTime.now();
  final calendarDay = DateTime(current.year, current.month, current.day);
  final fajrToday = fajrForDate(
    latitude: settings.latitude!,
    longitude: settings.longitude!,
    date: calendarDay,
  );
  if (current.isBefore(fajrToday)) {
    return fajrToday;
  }
  final tomorrow = calendarDay.add(const Duration(days: 1));
  return fajrForDate(
    latitude: settings.latitude!,
    longitude: settings.longitude!,
    date: tomorrow,
  );
}

String _format(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
