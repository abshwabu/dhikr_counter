import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../models/app_settings.dart';
import '../providers/dhikr_providers.dart';
import '../providers/settings_providers.dart';
import '../services/fajr_cities.dart';
import '../theme/app_theme.dart';

/// Keep in sync with `version:` in pubspec.yaml.
const _appVersionLabel = '1.0.0+1';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _locating = false;
  bool _resetting = false;

  Future<void> _applyFajrLocation({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    await ref.read(settingsProvider.notifier).setLocation(
          latitude: latitude,
          longitude: longitude,
          locationLabel: label,
        );
    await ref.read(settingsProvider.notifier).setDayResetMode(DayResetMode.fajr);
    if (!mounted) return;
    _showMessage(
      label == null
          ? 'Day now resets at local Fajr.'
          : 'Day now resets at Fajr ($label).',
    );
  }

  Future<void> _pickCityForFajr() async {
    final city = await showModalBottomSheet<FajrCity>(
      context: context,
      backgroundColor: AppTheme.cream,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  'Choose a city for Fajr',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.darkGreen,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              for (final city in fajrCityPresets)
                ListTile(
                  title: Text(city.name),
                  onTap: () => Navigator.of(context).pop(city),
                ),
            ],
          ),
        );
      },
    );
    if (city == null || !mounted) return;
    await _applyFajrLocation(
      latitude: city.latitude,
      longitude: city.longitude,
      label: city.name,
    );
  }

  Future<void> _enableFajrMode({bool preferGps = true}) async {
    if (!preferGps) {
      await _pickCityForFajr();
      return;
    }

    // If we already have coordinates, just turn Fajr on.
    final existing = ref.read(settingsProvider);
    if (existing.hasLocation) {
      await ref
          .read(settingsProvider.notifier)
          .setDayResetMode(DayResetMode.fajr);
      if (!mounted) return;
      _showMessage(
        existing.locationLabel == null
            ? 'Day now resets at local Fajr.'
            : 'Day now resets at Fajr (${existing.locationLabel}).',
      );
      return;
    }

    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        await _promptLocationFallback(
          'Location services are off. Choose a city to calculate Fajr offline.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        await _promptLocationFallback(
          'Location permission was denied. Choose a city instead.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      await _applyFajrLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        label: 'Device location',
      );
    } on MissingPluginException {
      if (!mounted) return;
      await _promptLocationFallback(
        'Location plugin is not loaded yet. Fully stop and reopen the app, or choose a city now.',
      );
    } catch (error) {
      if (!mounted) return;
      await _promptLocationFallback(
        'Could not get GPS location. Choose a city for offline Fajr.',
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _promptLocationFallback(String message) async {
    final useCity = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cream,
          title: const Text('Set Fajr location'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: AppTheme.lightGold,
              ),
              child: const Text('Choose city'),
            ),
          ],
        );
      },
    );
    if (useCity == true && mounted) {
      await _pickCityForFajr();
    }
  }

  Future<void> _onDayResetChanged(DayResetMode? mode) async {
    if (mode == null) return;
    if (mode == DayResetMode.midnight) {
      await ref
          .read(settingsProvider.notifier)
          .setDayResetMode(DayResetMode.midnight);
      return;
    }
    await _enableFajrMode();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatReminderTime(AppSettings settings) {
    final time = TimeOfDay(
      hour: settings.reminderHour,
      minute: settings.reminderMinute,
    );
    return time.format(context);
  }

  Future<void> _pickReminderTime(AppSettings settings) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.reminderHour,
        minute: settings.reminderMinute,
      ),
    );
    if (picked == null || !mounted) return;
    await ref.read(settingsProvider.notifier).setReminderTime(
          hour: picked.hour,
          minute: picked.minute,
        );
  }

  Future<void> _confirmResetAll() async {
    final first = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cream,
          title: const Text('Reset all data?'),
          content: const Text(
            'This permanently deletes custom dhikr, all daily counts, and streak history. Built-in dhikr sets stay.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Continue',
                style: TextStyle(color: Color(0xFFBF360C)),
              ),
            ),
          ],
        );
      },
    );
    if (first != true || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cream,
          title: const Text('Are you sure?'),
          content: const Text(
            'This cannot be undone. Tap Reset everything to wipe your progress.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFBF360C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Reset everything'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    setState(() => _resetting = true);
    try {
      await ref.read(dhikrRepositoryProvider).resetAllUserData();
      ref.read(dhikrSetsProvider.notifier).refresh();
      ref.read(streakProvider.notifier).refresh();
      await ref.read(todayEntriesNotifierProvider.notifier).loadForSets(
            ref.read(dhikrSetsProvider),
          );
      ref.read(activeDhikrIdProvider.notifier).state = '';
      if (!mounted) return;
      _showMessage('All progress data has been reset.');
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final nextFajr = ref.watch(nextFajrProvider);
    final dateKey = ref.watch(currentDateKeyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _SectionCard(
            title: 'Feedback',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Haptic feedback'),
                subtitle: const Text('Light vibration on each count'),
                activeThumbColor: AppTheme.accentGold,
                activeTrackColor: AppTheme.primaryGreen,
                value: settings.hapticEnabled,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setHapticEnabled(value);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sound on tap'),
                subtitle: const Text('Subtle click (off by default)'),
                activeThumbColor: AppTheme.accentGold,
                activeTrackColor: AppTheme.primaryGreen,
                value: settings.soundEnabled,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setSoundEnabled(value);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Daily reminder',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Local reminder'),
                subtitle: const Text(
                  'Offline notification with today’s progress',
                ),
                activeThumbColor: AppTheme.accentGold,
                activeTrackColor: AppTheme.primaryGreen,
                value: settings.reminderEnabled,
                onChanged: (value) async {
                  final ok = await ref
                      .read(settingsProvider.notifier)
                      .setReminderEnabled(value);
                  if (!ok && mounted) {
                    _showMessage(
                      'Notification permission was denied. Enable it in system settings.',
                    );
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: settings.reminderEnabled,
                title: const Text('Reminder time'),
                subtitle: Text(_formatReminderTime(settings)),
                trailing: const Icon(Icons.schedule_outlined),
                onTap: settings.reminderEnabled
                    ? () => _pickReminderTime(settings)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Daily reset',
            children: [
              _ResetOptionTile(
                title: 'Midnight',
                subtitle: 'Calendar day starts at 12:00 AM',
                selected: settings.dayResetMode == DayResetMode.midnight,
                enabled: !_locating,
                onTap: () => _onDayResetChanged(DayResetMode.midnight),
              ),
              _ResetOptionTile(
                title: 'At Fajr',
                subtitle: settings.hasLocation
                    ? 'Fajr near ${settings.locationLabel ?? 'saved location'}'
                    : 'Offline Fajr via GPS or a chosen city',
                selected: settings.dayResetMode == DayResetMode.fajr,
                enabled: !_locating,
                onTap: () => _onDayResetChanged(DayResetMode.fajr),
              ),
              if (_locating)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(
                    color: AppTheme.primaryGreen,
                    backgroundColor: AppTheme.lightGold,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Current day key: $dateKey',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.darkGreen.withValues(alpha: 0.55),
                    ),
              ),
              if (nextFajr != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Next Fajr: ${DateFormat.jm().format(nextFajr)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.darkGreen.withValues(alpha: 0.55),
                      ),
                ),
              ],
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: _locating
                        ? null
                        : () => _enableFajrMode(preferGps: false),
                    icon: const Icon(Icons.location_city_outlined, size: 18),
                    label: const Text('Choose city'),
                  ),
                  TextButton.icon(
                    onPressed: _locating ? null : () => _enableFajrMode(),
                    icon: const Icon(Icons.my_location_outlined, size: 18),
                    label: const Text('Use GPS'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Data',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.delete_forever_outlined,
                  color: Color(0xFFBF360C),
                ),
                title: const Text('Reset all data'),
                subtitle: const Text(
                  'Wipe custom dhikr, entries, and streaks',
                ),
                trailing: _resetting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: _resetting ? null : _confirmResetAll,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'About',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dhikr Counter'),
                subtitle: const Text('Version $_appVersionLabel'),
              ),
              Text(
                'Built for personal remembrance. Prayer times via Adhan (Muslim World League). Location is used only on-device for Fajr.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.darkGreen.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResetOptionTile extends StatelessWidget {
  const _ResetOptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: enabled,
      onTap: enabled ? onTap : null,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected
            ? AppTheme.primaryGreen
            : AppTheme.darkGreen.withValues(alpha: 0.35),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.darkGreen,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          ...children,
        ],
      ),
    );
  }
}
