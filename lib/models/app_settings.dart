enum DayResetMode {
  midnight,
  fajr,
}

class AppSettings {
  const AppSettings({
    this.hapticEnabled = true,
    this.soundEnabled = false,
    this.dayResetMode = DayResetMode.midnight,
    this.latitude,
    this.longitude,
    this.locationLabel,
    this.reminderEnabled = false,
    this.reminderHour = 20,
    this.reminderMinute = 0,
  });

  final bool hapticEnabled;
  final bool soundEnabled;
  final DayResetMode dayResetMode;
  final double? latitude;
  final double? longitude;
  final String? locationLabel;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;

  bool get hasLocation => latitude != null && longitude != null;

  AppSettings copyWith({
    bool? hapticEnabled,
    bool? soundEnabled,
    DayResetMode? dayResetMode,
    double? latitude,
    double? longitude,
    String? locationLabel,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    bool clearLocation = false,
  }) {
    return AppSettings(
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      dayResetMode: dayResetMode ?? this.dayResetMode,
      latitude: clearLocation ? null : (latitude ?? this.latitude),
      longitude: clearLocation ? null : (longitude ?? this.longitude),
      locationLabel:
          clearLocation ? null : (locationLabel ?? this.locationLabel),
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }
}
