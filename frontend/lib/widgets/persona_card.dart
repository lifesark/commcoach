import 'package:flutter/material.dart';

import '../theme/theme.dart';

class PersonaCard extends StatelessWidget {
  final String name;
  final String description;
  final String tone;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const PersonaCard({
    super.key,
    required this.name,
    required this.description,
    required this.tone,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? AppTheme.accentBlue.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.accentBlue : AppTheme.borderLight,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.accentBlue 
                      : AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  icon ?? _getIconForName(name),
                  color: isSelected ? AppTheme.white : AppTheme.textSecondary,
                  size: 24,
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
                        color: isSelected ? AppTheme.accentBlue : AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected ? AppTheme.accentBlue : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.accentBlue.withOpacity(0.2)
                            : AppTheme.lightGray,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tone,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected ? AppTheme.accentBlue : AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Selection indicator
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.accentBlue,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForName(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('friendly') || lowerName.contains('mentor')) {
      return Icons.favorite;
    } else if (lowerName.contains('socratic') || lowerName.contains('judge')) {
      return Icons.psychology;
    } else if (lowerName.contains('hiring') || lowerName.contains('manager')) {
      return Icons.business_center;
    } else if (lowerName.contains('debate') || lowerName.contains('champion')) {
      return Icons.gavel;
    } else if (lowerName.contains('presentation') || lowerName.contains('coach')) {
      return Icons.present_to_all;
    } else if (lowerName.contains('casual') || lowerName.contains('conversationalist')) {
      return Icons.chat;
    } else {
      return Icons.person;
    }
  }
}
