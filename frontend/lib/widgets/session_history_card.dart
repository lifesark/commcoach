import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/theme.dart';

class SessionHistoryCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final VoidCallback? onTap;

  const SessionHistoryCard({
    super.key,
    required this.session,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mode = session['mode'] ?? 'unknown';
    final topic = session['topic'] ?? 'No topic';
    final startedAt = session['started_at'] != null
        ? DateTime.parse(session['started_at'])
        : null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Mode Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getModeColor(mode).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getModeIcon(mode),
                  color: _getModeColor(mode),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getModeLabel(mode),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      topic,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (startedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, y • h:mm a').format(startedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Arrow
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getModeLabel(String mode) {
    switch (mode.toLowerCase()) {
      case 'debate':
        return 'Debate';
      case 'interview':
        return 'Interview';
      case 'presentation':
        return 'Presentation';
      case 'casual':
        return 'Casual Chat';
      default:
        return 'Practice';
    }
  }

  IconData _getModeIcon(String mode) {
    switch (mode.toLowerCase()) {
      case 'debate':
        return Icons.gavel;
      case 'interview':
        return Icons.business_center;
      case 'presentation':
        return Icons.present_to_all;
      case 'casual':
        return Icons.chat;
      default:
        return Icons.mic;
    }
  }

  Color _getModeColor(String mode) {
    switch (mode.toLowerCase()) {
      case 'debate':
        return AppTheme.danger;
      case 'interview':
        return AppTheme.accentBlue;
      case 'presentation':
        return AppTheme.warn;
      case 'casual':
        return AppTheme.success;
      default:
        return AppTheme.mediumGray;
    }
  }
}
