import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/auth_screen.dart';
import 'features/setup/setup_screen.dart';
import 'features/practice/practice_room_screen.dart';
import 'features/feedback/feedback_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'state/auth_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: '/auth',
    redirect: (context, state) {
      final isAuthenticated = authState.when(
        data: (user) => user != null,
        loading: () => false,
        error: (_, __) => false,
      );
      
      final isAuthRoute = state.uri.toString().startsWith('/auth');
      
      if (!isAuthenticated && !isAuthRoute) {
        return '/auth';
      }
      
      if (isAuthenticated && isAuthRoute) {
        return '/dashboard';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupScreen(),
      ),
      GoRoute(
        path: '/practice',
        builder: (context, state) {
          final sessionId = state.uri.queryParameters['sessionId'];
          if (sessionId == null) {
            return const Scaffold(
              body: Center(child: Text('Session ID required')),
            );
          }
          return PracticeRoomScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/feedback',
        builder: (context, state) {
          final sessionId = state.uri.queryParameters['sessionId'];
          if (sessionId == null) {
            return const Scaffold(
              body: Center(child: Text('Session ID required')),
            );
          }
          return FeedbackScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
});
