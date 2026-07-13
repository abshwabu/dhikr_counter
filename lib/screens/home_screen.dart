import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/dhikr_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dhikr_set_card.dart';
import '../widgets/streak_banner.dart';
import 'add_dhikr_screen.dart';
import 'counter_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sets = ref.watch(dhikrSetsProvider);
    final entries = ref.watch(todayEntriesProvider);
    final streak = ref.watch(streakProvider);

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
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add custom dhikr',
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: AppTheme.accentGold,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AddDhikrScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: sets.isEmpty
          ? Center(
              child: Text(
                'No dhikr sets yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.darkGreen.withValues(alpha: 0.6),
                    ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                StreakBanner(
                  currentStreak: streak.currentStreak,
                  completedToday: completedToday,
                  totalToday: sets.length,
                ),
                const SizedBox(height: 20),
                ...sets.map((set) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DhikrSetCard(
                      dhikrSet: set,
                      entry: entries[set.id],
                      onTap: () {
                        ref.read(activeDhikrIdProvider.notifier).state = set.id;
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const CounterScreen(),
                          ),
                        );
                      },
                      onLongPress: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AddDhikrScreen(existing: set),
                          ),
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
