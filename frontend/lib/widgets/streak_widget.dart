import 'package:flutter/material.dart';

import '../theme/theme.dart';

class StreakWidget extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;

  const StreakWidget({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: AppTheme.warn,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Streak',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStreakItem(
                    context,
                    'Current',
                    currentStreak,
                    AppTheme.warn,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppTheme.borderLight,
                ),
                Expanded(
                  child: _buildStreakItem(
                    context,
                    'Longest',
                    longestStreak,
                    AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            if (currentStreak > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.warn.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _getStreakMessage(currentStreak),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.warn,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStreakItem(
    BuildContext context,
    String label,
    int value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  String _getStreakMessage(int streak) {
    if (streak == 1) {
      return 'Great start! Keep it going!';
    } else if (streak < 7) {
      return 'You\'re on fire! 🔥';
    } else if (streak < 30) {
      return 'Incredible consistency! ⭐';
    } else {
      return 'You\'re a communication master! 🏆';
    }
  }
}
