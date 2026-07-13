import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../models/daily_entry.dart';
import '../models/dhikr_set.dart';
import '../providers/dhikr_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/streak_card.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _sharing = false;

  List<String> _completedTodayNames(
    List<DhikrSet> sets,
    Map<String, DailyEntry> entries,
  ) {
    final names = <String>[];
    for (final set in sets) {
      final entry = entries[set.id];
      if (entry == null) continue;
      if (entry.completedAt != null || entry.count >= set.targetCount) {
        names.add(
          set.transliteration.isNotEmpty ? set.transliteration : set.arabic,
        );
      }
    }
    return names;
  }

  Future<void> _onSharePressed({
    required int currentStreak,
    required List<String> completedNames,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cream,
          title: const Text('Share streak card?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your card will be shared as an image.',
                style: TextStyle(
                  color: AppTheme.darkGreen.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: StreakCard(
                      currentStreak: currentStreak,
                      date: DateTime.now(),
                      completedDhikrNames: completedNames,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
              child: const Text('Share'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    await _captureAndShare(currentStreak);
  }

  Future<void> _captureAndShare(int currentStreak) async {
    setState(() => _sharing = true);
    try {
      final Uint8List? bytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 40),
        pixelRatio: 1,
      );
      if (bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not capture streak card')),
        );
        return;
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/dhikr_streak_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        [XFile(path, mimeType: 'image/png')],
        text: 'My dhikr streak: $currentStreak days 🌙',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final streak = ref.watch(streakProvider);
    final sets = ref.watch(dhikrSetsProvider);
    final entries = ref.watch(todayEntriesProvider);
    final completedNames = _completedTodayNames(sets, entries);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share progress'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.darkGreen.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Screenshot(
                          controller: _screenshotController,
                          child: StreakCard(
                            currentStreak: streak.currentStreak,
                            date: DateTime.now(),
                            completedDhikrNames: completedNames,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _sharing ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.darkGreen,
                        side: BorderSide(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.35),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _sharing
                          ? null
                          : () => _onSharePressed(
                                currentStreak: streak.currentStreak,
                                completedNames: completedNames,
                              ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: AppTheme.lightGold,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: _sharing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.lightGold,
                              ),
                            )
                          : const Icon(Icons.share_outlined),
                      label: Text(_sharing ? 'Sharing…' : 'Share'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
