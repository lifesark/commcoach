import 'package:flutter/material.dart';

import '../theme/theme.dart';

class ProgressBadge extends StatelessWidget {
  final String name;
  final String description;
  final String icon;
  final bool isEarned;
  final int xpReward;

  const ProgressBadge({
    super.key,
    required this.name,
    required this.description,
    required this.icon,
    required this.isEarned,
    required this.xpReward,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEarned 
            ? AppTheme.warn.withOpacity(0.1)
            : AppTheme.lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEarned 
              ? AppTheme.warn
              : AppTheme.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isEarned 
                  ? AppTheme.warn
                  : AppTheme.mediumGray,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isEarned 
                        ? AppTheme.warn
                        : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isEarned 
                        ? AppTheme.warn
                        : AppTheme.textSecondary,
                  ),
                ),
                if (xpReward > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '+$xpReward XP',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Status indicator
          Icon(
            isEarned ? Icons.check_circle : Icons.lock,
            color: isEarned ? AppTheme.warn : AppTheme.mediumGray,
            size: 20,
          ),
        ],
      ),
    );
  }
}
