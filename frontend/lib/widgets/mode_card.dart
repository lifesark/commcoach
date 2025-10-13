import 'package:flutter/material.dart';

import '../theme/theme.dart';

class ModeCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const ModeCard({
    super.key,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? AppTheme.accentBlue.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppTheme.accentBlue : AppTheme.borderLight,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon ?? _getIconForTitle(title),
                size: 32,
                color: isSelected ? AppTheme.accentBlue : AppTheme.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isSelected ? AppTheme.accentBlue : AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isSelected ? AppTheme.accentBlue : AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'debate':
        return Icons.gavel;
      case 'interview':
        return Icons.business_center;
      case 'presentation':
        return Icons.present_to_all;
      case 'casual chat':
        return Icons.chat;
      default:
        return Icons.mic;
    }
  }
}
