import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../widgets/score_card.dart';
import '../../widgets/tips_list.dart';
import '../../state/api_providers.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  final String sessionId;
  
  const FeedbackScreen({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  @override
  Widget build(BuildContext context) {
    final feedbackAsync = ref.watch(feedbackProvider(widget.sessionId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Feedback'),
        actions: [
          IconButton(
            onPressed: () {
              context.go('/dashboard');
            },
            icon: const Icon(Icons.dashboard),
          ),
        ],
      ),
      body: feedbackAsync.when(
        data: (feedback) => _buildFeedbackContent(feedback),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.danger,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load feedback',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(feedbackProvider(widget.sessionId));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackContent(Map<String, dynamic> feedback) {
    final scores = {
      'Clarity': feedback['clarity'] ?? 0,
      'Structure': feedback['structure'] ?? 0,
      'Persuasiveness': feedback['persuasiveness'] ?? 0,
      'Fluency': feedback['fluency'] ?? 0,
      'Timing': feedback['time'] ?? 0,
    };
    
    final overall = feedback['overall'] ?? 0;
    final tips = List<String>.from(feedback['tips'] ?? []);
    final progressUpdate = feedback['progress_update'];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Overall Score
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getScoreColor(overall).withOpacity(0.1),
                  _getScoreColor(overall).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getScoreColor(overall).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Overall Score',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _getScoreColor(overall),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$overall',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: _getScoreColor(overall),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getScoreDescription(overall),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _getScoreColor(overall),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Progress Update (if available)
          if (progressUpdate != null) ...[
            _buildProgressUpdate(progressUpdate),
            const SizedBox(height: 24),
          ],
          
          // Individual Scores
          Text(
            'Detailed Scores',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: scores.length,
            itemBuilder: (context, index) {
              final entry = scores.entries.elementAt(index);
              return ScoreCard(
                title: entry.key,
                score: entry.value,
                color: _getScoreColor(entry.value),
              );
            },
          ),
          const SizedBox(height: 24),
          
          // Tips
          if (tips.isNotEmpty) ...[
            Text(
              'Improvement Tips',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TipsList(tips: tips),
            const SizedBox(height: 24),
          ],
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    context.go('/setup');
                  },
                  child: const Text('Practice Again'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/dashboard');
                  },
                  child: const Text('View Dashboard'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressUpdate(Map<String, dynamic> progressUpdate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.success.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star,
                color: AppTheme.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Progress Update',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You earned ${progressUpdate['session_xp']} XP!',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (progressUpdate['leveled_up'] == true) ...[
            const SizedBox(height: 4),
            Text(
              '🎉 Level Up! You\'re now level ${progressUpdate['level']}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (progressUpdate['new_badges'] != null && 
              (progressUpdate['new_badges'] as List).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '🏆 New Badge${(progressUpdate['new_badges'] as List).length > 1 ? 's' : ''} Earned!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.warn,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return AppTheme.success;
    if (score >= 80) return AppTheme.accentBlue;
    if (score >= 70) return AppTheme.warn;
    return AppTheme.danger;
  }

  String _getScoreDescription(int score) {
    if (score >= 90) return 'Excellent! Outstanding performance';
    if (score >= 80) return 'Great job! Well done';
    if (score >= 70) return 'Good work! Keep practicing';
    if (score >= 60) return 'Not bad! Room for improvement';
    return 'Keep practicing! You\'ll get better';
  }
}
