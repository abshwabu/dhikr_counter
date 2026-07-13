import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_entry.dart';
import '../models/dhikr_set.dart';
import '../providers/dhikr_providers.dart';
import '../providers/settings_providers.dart';
import '../services/streak_calculator.dart';
import '../theme/app_theme.dart';

class CounterScreen extends ConsumerStatefulWidget {
  const CounterScreen({super.key});

  @override
  ConsumerState<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends ConsumerState<CounterScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late int _pageIndex;
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final sets = ref.read(dhikrSetsProvider);
    final activeId = ref.read(activeDhikrIdProvider);
    final index = sets.indexWhere((set) => set.id == activeId);
    _pageIndex = index >= 0 ? index : 0;
    _pageController = PageController(initialPage: _pageIndex);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _pulse = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  bool _isCompleted(DhikrSet set, DailyEntry? entry) {
    if (entry == null) return false;
    return entry.completedAt != null || entry.count >= set.targetCount;
  }

  List<DailyEntry> _entriesList(Map<String, DailyEntry> entries) =>
      entries.values.toList();

  Color _accentFor(DhikrSet set) {
    try {
      final hex = set.colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppTheme.primaryGreen;
    }
  }

  Future<void> _onIncrement(DhikrSet set) async {
    if (_busy) return;

    final sets = ref.read(dhikrSetsProvider);
    final entriesBefore = ref.read(todayEntriesProvider);
    final wasCompleted = _isCompleted(set, entriesBefore[set.id]);
    final dayCompleteBefore =
        isDayComplete(sets, _entriesList(entriesBefore));

    setState(() => _busy = true);
    try {
      await ref.read(todayEntriesActionsProvider).increment(set.id);
      await playTapFeedback(ref);

      final entriesAfter = ref.read(todayEntriesProvider);
      final nowCompleted = _isCompleted(set, entriesAfter[set.id]);
      final dayCompleteAfter =
          isDayComplete(sets, _entriesList(entriesAfter));

      if (!wasCompleted && nowCompleted) {
        await playTapFeedback(ref, stronger: true);
        _pulseController.forward(from: 0);
        if (!mounted) return;
        _showDhikrCompleteToast(set);
      }

      if (!dayCompleteBefore && dayCompleteAfter) {
        final updated =
            await ref.read(streakProvider.notifier).recordDayComplete();
        if (!mounted) return;
        if (updated != null) {
          await playTapFeedback(ref, stronger: true);
          _showStreakDayCompleteToast(updated.currentStreak);
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmReset(DhikrSet set) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cream,
          title: const Text('Reset today\'s count?'),
          content: Text(
            'This will set ${set.transliteration} back to 0 for today.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Reset',
                style: TextStyle(color: AppTheme.primaryGreen),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    await ref.read(todayEntriesActionsProvider).reset(set.id);
  }

  void _showDhikrCompleteToast(DhikrSet set) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryGreen,
        content: Text(
          '${set.transliteration} complete — may it be accepted',
          style: const TextStyle(color: AppTheme.lightGold),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showStreakDayCompleteToast(int currentStreak) {
    ScaffoldMessenger.of(context).clearSnackBars();
    final label =
        currentStreak == 1 ? '1 day streak' : '$currentStreak day streak';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.darkGreen,
        content: Row(
          children: [
            const Icon(
              Icons.local_fire_department_outlined,
              color: AppTheme.accentGold,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Day complete — $label',
                style: const TextStyle(color: AppTheme.lightGold),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onPageChanged(int index, List<DhikrSet> sets) {
    setState(() => _pageIndex = index);
    if (index >= 0 && index < sets.length) {
      ref.read(activeDhikrIdProvider.notifier).state = sets[index].id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sets = ref.watch(dhikrSetsProvider);
    final entries = ref.watch(todayEntriesProvider);

    if (sets.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Counter')),
        body: Center(
          child: Text(
            'No dhikr sets available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.darkGreen.withValues(alpha: 0.6),
                ),
          ),
        ),
      );
    }

    final safeIndex = _pageIndex.clamp(0, sets.length - 1);
    final current = sets[safeIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(current.transliteration),
        actions: [
          IconButton(
            tooltip: 'Reset today',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _confirmReset(current),
          ),
        ],
      ),
      body: Column(
        children: [
          if (sets.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(sets.length, (i) {
                  final selected = i == safeIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: selected ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primaryGreen
                          : AppTheme.primaryGreen.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: sets.length,
              onPageChanged: (index) => _onPageChanged(index, sets),
              itemBuilder: (context, index) {
                final set = sets[index];
                return _CounterPage(
                  dhikrSet: set,
                  entry: entries[set.id],
                  accent: _accentFor(set),
                  pulse: _pulse,
                  isCurrentPage: index == safeIndex,
                  onTap: () => _onIncrement(set),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            child: Text(
              'Swipe to switch · tap the circle to count',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.darkGreen.withValues(alpha: 0.45),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterPage extends StatelessWidget {
  const _CounterPage({
    required this.dhikrSet,
    required this.entry,
    required this.accent,
    required this.pulse,
    required this.isCurrentPage,
    required this.onTap,
  });

  final DhikrSet dhikrSet;
  final DailyEntry? entry;
  final Color accent;
  final Animation<double> pulse;
  final bool isCurrentPage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = entry?.count ?? 0;
    final target = dhikrSet.targetCount;
    final progress = target <= 0 ? 0.0 : (count / target).clamp(0.0, 1.0);
    final completed =
        entry?.completedAt != null || (target > 0 && count >= target);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            dhikrSet.arabic,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.darkGreen,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            dhikrSet.transliteration,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.darkGreen.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            dhikrSet.translation,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkGreen.withValues(alpha: 0.55),
                ),
          ),
          const Spacer(),
          ScaleTransition(
            scale: isCurrentPage ? pulse : const AlwaysStoppedAnimation(1),
            child: SizedBox(
              width: 248,
              height: 248,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 248,
                    height: 248,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: accent.withValues(alpha: 0.12),
                      color: accent.withValues(alpha: 0.9),
                    ),
                  ),
                  Material(
                    color: completed
                        ? accent.withValues(alpha: 0.14)
                        : Colors.white.withValues(alpha: 0.78),
                    shape: const CircleBorder(),
                    elevation: 0,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onTap,
                      child: SizedBox(
                        width: 210,
                        height: 210,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$count',
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    color: AppTheme.darkGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'of $target',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppTheme.darkGreen
                                        .withValues(alpha: 0.5),
                                  ),
                            ),
                            if (completed) ...[
                              const SizedBox(height: 10),
                              Icon(
                                Icons.check_circle_outline_rounded,
                                color: accent.withValues(alpha: 0.9),
                                size: 22,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
