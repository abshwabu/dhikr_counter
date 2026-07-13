import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

/// Fixed-size social share card (1080×1080).
class StreakCard extends StatelessWidget {
  const StreakCard({
    super.key,
    required this.currentStreak,
    required this.date,
    required this.completedDhikrNames,
  });

  static const double size = 1080;

  final int currentStreak;
  final DateTime date;
  final List<String> completedDhikrNames;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEEE, MMMM d, yyyy').format(date);

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF8E7),
              Color(0xFFF5E6B8),
              Color(0xFFE8D5A3),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _SubtlePatternPainter()),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 72, vertical: 64),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.accentGold.withValues(alpha: 0.7),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.mosque_outlined,
                          color: AppTheme.primaryGreen,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Text(
                        'Dhikr Counter',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),
                  Text(
                    '$currentStreak',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 220,
                      fontWeight: FontWeight.w700,
                      height: 0.9,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'day streak',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.darkGreen.withValues(alpha: 0.75),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppTheme.accentGold.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 26,
                        color: AppTheme.darkGreen.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      completedDhikrNames.isEmpty
                          ? 'No dhikr completed today yet'
                          : 'Completed today',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkGreen.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (completedDhikrNames.isEmpty)
                    const SizedBox(height: 48)
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final name in completedDhikrNames.take(6))
                          _DhikrChip(label: name),
                        if (completedDhikrNames.length > 6)
                          _DhikrChip(
                            label: '+${completedDhikrNames.length - 6}',
                          ),
                      ],
                    ),
                  const SizedBox(height: 28),
                  Container(
                    height: 2,
                    width: 120,
                    color: AppTheme.accentGold.withValues(alpha: 0.55),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Consistent remembrance',
                    style: TextStyle(
                      fontSize: 22,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.darkGreen.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DhikrChip extends StatelessWidget {
  const _DhikrChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: AppTheme.darkGreen,
        ),
      ),
    );
  }
}

class _SubtlePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryGreen.withValues(alpha: 0.035)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final border = Paint()
      ..color = AppTheme.accentGold.withValues(alpha: 0.35)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTWH(28, 28, size.width - 56, size.height - 56),
      border,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
