import 'package:flutter/material.dart';

import '../theme/theme.dart';

class BadgeGrid extends StatelessWidget {
  final List<Map<String, dynamic>> badges;

  const BadgeGrid({
    super.key,
    required this.badges,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return _buildBadgeItem(context, badge);
      },
    );
  }

  Widget _buildBadgeItem(BuildContext context, Map<String, dynamic> badge) {
    final name = badge['name'] ?? 'Badge';
    final icon = badge['icon'] ?? '🏆';
    final isEarned = badge['isEarned'] ?? true;
    
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            icon,
            style: const TextStyle(
              fontSize: 24,
              color: AppTheme.warn,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isEarned 
                  ? AppTheme.warn
                  : AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
