import 'package:flutter/material.dart';

import '../theme/theme.dart';

class XpProgressBar extends StatelessWidget {
  final int currentXp;
  final int level;
  final int xpToNextLevel;

  const XpProgressBar({
    super.key,
    required this.currentXp,
    required this.level,
    required this.xpToNextLevel,
  });

  @override
  Widget build(BuildContext context) {
    final progress = xpToNextLevel > 0 ? (currentXp % 1000) / 1000 : 1.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: AppTheme.warn,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Level $level',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$currentXp XP',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress to Level ${level + 1}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.accentBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.lightGray,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
                  minHeight: 8,
                ),
                const SizedBox(height: 4),
                Text(
                  '${xpToNextLevel - (currentXp % 1000)} XP to next level',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
