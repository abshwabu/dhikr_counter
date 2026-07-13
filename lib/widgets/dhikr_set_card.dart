import 'package:flutter/material.dart';

import '../models/daily_entry.dart';
import '../models/dhikr_set.dart';
import '../theme/app_theme.dart';

class DhikrSetCard extends StatelessWidget {
  const DhikrSetCard({
    super.key,
    required this.dhikrSet,
    required this.entry,
    required this.onTap,
  });

  final DhikrSet dhikrSet;
  final DailyEntry? entry;
  final VoidCallback onTap;

  Color get _accent {
    try {
      final hex = dhikrSet.colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppTheme.primaryGreen;
    }
  }

  bool get _isCompleted {
    final count = entry?.count ?? 0;
    return entry?.completedAt != null || count >= dhikrSet.targetCount;
  }

  double get _progress {
    if (dhikrSet.targetCount <= 0) return 0;
    final count = entry?.count ?? 0;
    return (count / dhikrSet.targetCount).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final count = entry?.count ?? 0;
    final accent = _accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accent.withValues(alpha: 0.18),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dhikrSet.arabic,
                        textDirection: TextDirection.rtl,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.darkGreen,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dhikrSet.transliteration,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.darkGreen.withValues(alpha: 0.7),
                            ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 6,
                          backgroundColor: accent.withValues(alpha: 0.12),
                          color: accent.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$count / ${dhikrSet.targetCount}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppTheme.darkGreen.withValues(alpha: 0.55),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (_isCompleted)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppTheme.primaryGreen,
                      size: 22,
                    ),
                  )
                else
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 3,
                      backgroundColor: accent.withValues(alpha: 0.12),
                      color: accent.withValues(alpha: 0.85),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
