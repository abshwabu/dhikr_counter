import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

/// GitHub-style contribution heatmap for the last ~12 weeks.
///
/// [intensities] maps `yyyy-MM-dd` → 0.0–1.0 completion ratio for that day.
class ContributionHeatmap extends StatelessWidget {
  const ContributionHeatmap({
    super.key,
    required this.intensities,
    this.weeks = 12,
  });

  final Map<String, double> intensities;
  final int weeks;

  static final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    // Align columns to weeks that start on Sunday (GitHub style).
    final daysFromSunday = todayDate.weekday % 7;
    final thisWeekSunday =
        todayDate.subtract(Duration(days: daysFromSunday));
    final start =
        thisWeekSunday.subtract(Duration(days: (weeks - 1) * 7));

    final columns = <List<_DayCell>>[];
    var cursor = start;
    List<_DayCell> column = [];

    while (!cursor.isAfter(todayDate)) {
      final key = _dateFormat.format(cursor);
      column.add(
        _DayCell(
          date: cursor,
          intensity: intensities[key]?.clamp(0.0, 1.0) ?? 0.0,
          hasActivity: intensities.containsKey(key),
        ),
      );

      if (column.length == 7) {
        columns.add(column);
        column = [];
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    if (column.isNotEmpty) {
      while (column.length < 7) {
        column.add(const _DayCell.empty());
      }
      columns.add(column);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  for (final label in const ['', 'Mon', '', 'Wed', '', 'Fri', ''])
                    SizedBox(
                      height: 14,
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.darkGreen.withValues(alpha: 0.45),
                              fontSize: 9,
                            ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final week in columns)
                      Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: Column(
                          children: [
                            for (final day in week)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: _HeatCell(day: day),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'Less',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.darkGreen.withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(width: 8),
            for (final level in [0.0, 0.25, 0.5, 0.75, 1.0])
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _swatch(level),
              ),
            Text(
              'More',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.darkGreen.withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _swatch(double intensity) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _colorFor(intensity, hasActivity: intensity > 0),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  static Color _colorFor(double intensity, {required bool hasActivity}) {
    if (!hasActivity || intensity <= 0) {
      return AppTheme.primaryGreen.withValues(alpha: 0.08);
    }
    // Partial days are lighter; full days are deepest green.
    final alpha = 0.22 + (intensity * 0.72);
    return AppTheme.primaryGreen.withValues(alpha: alpha.clamp(0.22, 0.94));
  }
}

class _DayCell {
  const _DayCell({
    required this.date,
    required this.intensity,
    required this.hasActivity,
  }) : isEmpty = false;

  const _DayCell.empty()
      : date = null,
        intensity = 0,
        hasActivity = false,
        isEmpty = true;

  final DateTime? date;
  final double intensity;
  final bool hasActivity;
  final bool isEmpty;
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({required this.day});

  final _DayCell day;

  @override
  Widget build(BuildContext context) {
    if (day.isEmpty) {
      return const SizedBox(width: 12, height: 12);
    }

    final label = day.date == null
        ? ''
        : DateFormat('EEE, MMM d').format(day.date!);
    final percent = (day.intensity * 100).round();

    return Tooltip(
      message: day.hasActivity
          ? '$label · $percent% of dhikr completed'
          : '$label · no activity',
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: ContributionHeatmap._colorFor(
            day.intensity,
            hasActivity: day.hasActivity,
          ),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
