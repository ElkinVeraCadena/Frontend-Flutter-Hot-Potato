import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/supabase_repository.dart';

final supabaseRepoProvider = Provider((ref) => SupabaseRepository());

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AppUser?>>((ref) {
      return AuthNotifier(ref.read(supabaseRepoProvider));
    });

class AuthNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final SupabaseRepository _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.loading()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    try {
      final user = await _repository.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _repository.signInWithEmail(email, password);
      await checkAuth();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUpWithEmail(String email, String password, String username) async {
    state = const AsyncValue.loading();
    try {
      await _repository.signUpWithEmail(email, password, username);
      await checkAuth();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await _repository.signInWithGoogle();
      // Auth state changes should ideally be listened to via Supabase auth stream
      // but for this demo, we'll just check auth again after sign in.
      await checkAuth(); 
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInAsGuest() async {
    state = const AsyncValue.loading();
    try {
      await _repository.signInAsGuest();
      await checkAuth();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _repository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateXP(int xpToAdd) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    try {
      await _repository.updateXP(currentUser.id, xpToAdd);
      // Optimistic update
      state = AsyncValue.data(
        currentUser.copyWith(
          totalXP: currentUser.totalXP + xpToAdd,
          // Simple linear progression level calculation for demo
          level: ((currentUser.totalXP + xpToAdd) ~/ 100) + 1,
        ),
      );
    } catch (e, st) {
      // Revert or show error
      state = AsyncValue.error(e, st);
    }
  }
}
