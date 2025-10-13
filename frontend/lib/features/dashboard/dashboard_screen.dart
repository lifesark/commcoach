import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../widgets/stats_card.dart';
import '../../widgets/session_history_card.dart';
import '../../widgets/streak_widget.dart';
import '../../widgets/xp_progress_bar.dart';
import '../../widgets/badge_grid.dart';
import '../../state/api_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final historyAsync = ref.watch(historyProvider(10));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('CommCoach'),
        actions: [
          IconButton(
            onPressed: () {
              context.go('/setup');
            },
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: () {
              // Show settings or profile
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: dashboardAsync.when(
        data: (dashboard) => _buildDashboard(dashboard, historyAsync),
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
                'Failed to load dashboard',
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
                  ref.invalidate(dashboardProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(
    Map<String, dynamic> dashboard,
    AsyncValue<List<Map<String, dynamic>>> historyAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          _buildWelcomeSection(dashboard),
          const SizedBox(height: 24),
          
          // XP Progress
          XpProgressBar(
            currentXp: dashboard['total_xp'] ?? 0,
            level: dashboard['level'] ?? 1,
            xpToNextLevel: dashboard['xp_to_next_level'] ?? 1000,
          ),
          const SizedBox(height: 24),
          
          // Stats Grid
          _buildStatsGrid(dashboard),
          const SizedBox(height: 24),
          
          // Streak Widget
          StreakWidget(
            currentStreak: dashboard['current_streak'] ?? 0,
            longestStreak: dashboard['longest_streak'] ?? 0,
          ),
          const SizedBox(height: 24),
          
          // Badges Section
          _buildBadgesSection(dashboard),
          const SizedBox(height: 24),
          
          // Recent Sessions
          _buildRecentSessions(historyAsync),
          const SizedBox(height: 24),
          
          // Quick Actions
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(Map<String, dynamic> dashboard) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentBlue.withOpacity(0.1),
            AppTheme.accentBlue.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.accentBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ready to practice your communication skills?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    context.go('/setup');
                  },
                  icon: const Icon(Icons.mic),
                  label: const Text('Start Practice'),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.mic,
            size: 64,
            color: AppTheme.accentBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> dashboard) {
    final stats = [
      {
        'title': 'Sessions',
        'value': '${dashboard['total_sessions'] ?? 0}',
        'icon': Icons.play_circle_outline,
        'color': AppTheme.accentBlue,
      },
      {
        'title': 'Level',
        'value': '${dashboard['level'] ?? 1}',
        'icon': Icons.star,
        'color': AppTheme.warn,
      },
      {
        'title': 'Badges',
        'value': '${(dashboard['badges'] as List?)?.length ?? 0}',
        'icon': Icons.emoji_events,
        'color': AppTheme.success,
      },
      {
        'title': 'Rank',
        'value': '#${dashboard['leaderboard_position'] ?? '?'}',
        'icon': Icons.leaderboard,
        'color': AppTheme.danger,
      },
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return StatsCard(
          title: stat['title'] as String,
          value: stat['value'] as String,
          icon: stat['icon'] as IconData,
          color: stat['color'] as Color,
        );
      },
    );
  }

  Widget _buildBadgesSection(Map<String, dynamic> dashboard) {
    final badges = List<Map<String, dynamic>>.from(dashboard['badges'] ?? []);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Badges',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            TextButton(
              onPressed: () {
                // Navigate to badges page
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (badges.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  size: 48,
                  color: AppTheme.mediumGray,
                ),
                const SizedBox(height: 12),
                Text(
                  'No badges yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete practice sessions to earn your first badge!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          BadgeGrid(badges: badges.take(6).toList()),
      ],
    );
  }

  Widget _buildRecentSessions(AsyncValue<List<Map<String, dynamic>>> historyAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Sessions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            TextButton(
              onPressed: () {
                // Navigate to history page
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        historyAsync.when(
          data: (sessions) => sessions.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.history,
                        size: 48,
                        color: AppTheme.mediumGray,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No sessions yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start your first practice session!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: sessions.take(3).map((session) {
                    return SessionHistoryCard(
                      session: session,
                      onTap: () {
                        // Navigate to session details
                      },
                    );
                  }).toList(),
                ),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Text(
            'Failed to load sessions: $error',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.danger,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  context.go('/setup');
                },
                icon: const Icon(Icons.mic),
                label: const Text('Practice'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Navigate to leaderboard
                },
                icon: const Icon(Icons.leaderboard),
                label: const Text('Leaderboard'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
