import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return SupabaseService.authStateChanges.map((data) => data.session?.user);
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});
