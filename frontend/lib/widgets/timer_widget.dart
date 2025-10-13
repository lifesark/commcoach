import 'package:flutter/material.dart';

import '../theme/theme.dart';

class TimerWidget extends StatelessWidget {
  final String label;
  final String time;
  final bool isActive;

  const TimerWidget({
    super.key,
    required this.label,
    required this.time,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isActive 
            ? AppTheme.accentBlue.withOpacity(0.1)
            : AppTheme.lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppTheme.accentBlue : AppTheme.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isActive ? AppTheme.accentBlue : AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: isActive ? AppTheme.accentBlue : AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
