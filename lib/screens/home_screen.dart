import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navigation/app_transitions.dart';
import '../providers/dhikr_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dhikr_set_card.dart';
import '../widgets/empty_state_panel.dart';
import '../widgets/streak_banner.dart';
import 'add_dhikr_screen.dart';
import 'counter_screen.dart';
import 'settings_screen.dart';
import 'streak_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sets = ref.watch(dhikrSetsProvider);
    final entries = ref.watch(todayEntriesProvider);
    final streak = ref.watch(streakProvider);
    final hasCustom = sets.any((set) => set.isCustom);

    final completedToday = sets.where((set) {
      final entry = entries[set.id];
      if (entry == null) return false;
      return entry.completedAt != null || entry.count >= set.targetCount;
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dhikr Counter'),
        actions: [
          IconButton(
            tooltip: 'Streak',
            icon: const Icon(Icons.local_fire_department_outlined),
            onPressed: () => pushAppRoute(context, const StreakScreen()),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => pushAppRoute(context, const SettingsScreen()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add custom dhikr',
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: AppTheme.accentGold,
        onPressed: () => pushAppRoute(context, const AddDhikrScreen()),
        child: const Icon(Icons.add),
      ),
      body: sets.isEmpty
          ? EmptyStatePanel(
              icon: Icons.menu_book_outlined,
              title: 'Begin with remembrance',
              message:
                  'No dhikr sets yet. Add a custom set, or reset data then reopen to restore the built-in list.',
              actionLabel: 'Add custom dhikr',
              onAction: () => pushAppRoute(context, const AddDhikrScreen()),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => pushAppRoute(context, const StreakScreen()),
                    child: StreakBanner(
                      currentStreak: streak.currentStreak,
                      completedToday: completedToday,
                      totalToday: sets.length,
                    ),
                  ),
                ),
                if (!hasCustom) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Tip: long-press a set to edit · tap + to add your own',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.darkGreen.withValues(alpha: 0.5),
                        ),
                  ),
                ],
                const SizedBox(height: 20),
                ...sets.map((set) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DhikrSetCard(
                      dhikrSet: set,
                      entry: entries[set.id],
                      onTap: () {
                        ref.read(activeDhikrIdProvider.notifier).state = set.id;
                        pushAppRoute(context, const CounterScreen());
                      },
                      onLongPress: () {
                        pushAppRoute(
                          context,
                          AddDhikrScreen(existing: set),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
