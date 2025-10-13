import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Session providers
final personasProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getPersonas();
});

final debateTopicsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, category) {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getDebateTopics(category: category);
});

final presentationTopicsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, industry) {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getPresentationTopics(industry: industry);
});

final interviewQuestionsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, role) {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getInterviewQuestions(role: role);
});

// Progress providers
final dashboardProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getDashboard();
});

final leaderboardProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, limit) {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getLeaderboard(limit: limit);
});

final badgesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getBadges();
});

// History providers
final historyProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, limit) {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getHistory(limit: limit);
});

final sessionProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, sessionId) {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getSession(sessionId);
});

// Feedback provider
final feedbackProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, sessionId) {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getFeedback(sessionId);
});

// TTS providers
final voicesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getVoices();
});
