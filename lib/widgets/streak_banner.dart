import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class StreakBanner extends StatelessWidget {
  const StreakBanner({
    super.key,
    required this.currentStreak,
    required this.completedToday,
    required this.totalToday,
  });

  final int currentStreak;
  final int completedToday;
  final int totalToday;

  @override
  Widget build(BuildContext context) {
    final streakLabel = currentStreak == 1
        ? '1 day streak'
        : '$currentStreak day streak';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department_outlined,
                size: 20,
                color: AppTheme.accentGold.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              Text(
                streakLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.darkGreen,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$completedToday of $totalToday dhikr completed today',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkGreen.withValues(alpha: 0.75),
                ),
          ),
        ],
      ),
    );
  }
}
