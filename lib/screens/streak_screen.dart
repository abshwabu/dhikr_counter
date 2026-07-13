import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/daily_entry.dart';
import '../models/dhikr_set.dart';
import '../navigation/app_transitions.dart';
import '../providers/dhikr_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/contribution_heatmap.dart';
import '../widgets/empty_state_panel.dart';
import 'export_screen.dart';

class StreakScreen extends ConsumerWidget {
  const StreakScreen({super.key});

  static final _dateFormat = DateFormat('yyyy-MM-dd');

  /// Completion ratio per day for current sets (0–1).
  Map<String, double> _intensitiesFor(
    List<DhikrSet> sets,
    List<DailyEntry> entries,
  ) {
    if (sets.isEmpty) return const {};

    final byDate = <String, List<DailyEntry>>{};
    for (final entry in entries) {
      byDate.putIfAbsent(entry.date, () => []).add(entry);
    }

    final intensities = <String, double>{};
    for (final entry in byDate.entries) {
      final dayEntries = {
        for (final e in entry.value) e.dhikrSetId: e,
      };
      var completed = 0;
      for (final set in sets) {
        final match = dayEntries[set.id];
        if (match != null && match.count >= set.targetCount) {
          completed++;
        }
      }
      final hasActivity = sets.any((set) => dayEntries.containsKey(set.id));
      if (hasActivity) {
        intensities[entry.key] = completed / sets.length;
      }
    }
    return intensities;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    final sets = ref.watch(dhikrSetsProvider);
    final entries = ref.watch(allDailyEntriesProvider);
    final totalCount = ref.watch(totalDhikrCountProvider);
    final intensities = _intensitiesFor(sets, entries);
    final isDayOne = streak.currentStreak <= 1 &&
        streak.totalDaysCompleted <= 1 &&
        intensities.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Streak'),
        actions: [
          IconButton(
            tooltip: 'Share progress',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => pushAppRoute(context, const ExportScreen()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          if (isDayOne) ...[
            EmptyStatePanel(
              icon: Icons.local_fire_department_outlined,
              title: 'Day one begins here',
              message:
                  'Complete every dhikr set today to light your first streak day. Consistency grows quietly.',
            ),
            const SizedBox(height: 24),
          ],
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Current streak',
                  value: '${streak.currentStreak}',
                  hint: streak.currentStreak == 1 ? 'day' : 'days',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Longest streak',
                  value: '${streak.longestStreak}',
                  hint: streak.longestStreak == 1 ? 'day' : 'days',
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Last 12 weeks',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.darkGreen,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            intensities.isEmpty
                ? 'Your heatmap will fill in as you complete dhikr each day.'
                : 'Shade shows how many of your dhikr sets were completed that day.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.darkGreen.withValues(alpha: 0.55),
                ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              ),
            ),
            child: ContributionHeatmap(intensities: intensities),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Days completed',
                  value: '${streak.totalDaysCompleted}',
                  hint: 'full days',
                  compact: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Total dhikr',
                  value: _formatCount(totalCount),
                  hint: 'all time',
                  compact: true,
                ),
              ),
            ],
          ),
          if (streak.lastCompletedDate != null) ...[
            const SizedBox(height: 20),
            Text(
              'Last full day: ${_friendlyDate(streak.lastCompletedDate!)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.darkGreen.withValues(alpha: 0.5),
                  ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return '$count';
  }

  String _friendlyDate(String yyyyMmDd) {
    try {
      return DateFormat('MMM d, yyyy').format(_dateFormat.parse(yyyyMmDd));
    } catch (_) {
      return yyyyMmDd;
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.hint,
    this.compact = false,
  });

  final String label;
  final String value;
  final String hint;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: compact ? 16 : 20,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.darkGreen.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.darkGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 28 : 36,
                  height: 1.1,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.accentGold.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
