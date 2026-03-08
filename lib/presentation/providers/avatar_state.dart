import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../domain/models/avatar_config.dart';
import '../../domain/repositories/supabase_repository.dart';
import 'auth_state.dart';

final avatarStateProvider =
    StateNotifierProvider<AvatarNotifier, AsyncValue<AvatarConfig>>((ref) {
      final authState = ref.watch(authStateProvider);
      return AvatarNotifier(
        ref.read(supabaseRepoProvider),
        authState.value?.id,
      );
    });

class AvatarNotifier extends StateNotifier<AsyncValue<AvatarConfig>> {
  final SupabaseRepository _repository;
  final String? _userId;

  AvatarNotifier(this._repository, this._userId)
    : super(const AsyncValue.loading()) {
    if (_userId != null) {
      loadConfig();
    } else {
      state = AsyncValue.data(AvatarConfig(userId: ''));
    }
  }

  Future<void> loadConfig() async {
    if (_userId == null) return;
    try {
      final config = await _repository.getAvatarConfig(_userId!);
      state = AsyncValue.data(config);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateConfig({
    String? hair,
    String? beard,
    String? clothes,
  }) async {
    if (_userId == null) return;
    final currentConfig = state.value;
    if (currentConfig == null) return;

    final updatedConfig = currentConfig.copyWith(
      hair: hair ?? currentConfig.hair,
      beard: beard ?? currentConfig.beard,
      clothes: clothes ?? currentConfig.clothes,
    );

    // Optimistic UI update
    state = AsyncValue.data(updatedConfig);

    try {
      await _repository.updateAvatarConfig(updatedConfig);
    } catch (e, st) {
      // Revert in case of failure
      state = AsyncValue.data(currentConfig);
      // Ideally show a snackbar or similar error
    }
  }
}
