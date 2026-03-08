import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hot_potato/presentation/providers/auth_state.dart';
import 'dart:async';
import '../../domain/models/match.dart';
import '../../domain/repositories/supabase_repository.dart';

final gameStateProvider =
    StateNotifierProvider<GameNotifier, AsyncValue<GameMatch?>>((ref) {
      return GameNotifier(ref.read(supabaseRepoProvider));
    });

class GameNotifier extends StateNotifier<AsyncValue<GameMatch?>> {
  final SupabaseRepository _repository;
  StreamSubscription<GameMatch>? _matchSubscription;

  GameNotifier(this._repository) : super(const AsyncValue.data(null));

  void joinMatch(String matchId) {
    state = const AsyncValue.loading();
    _matchSubscription?.cancel();

    _matchSubscription = _repository
        .streamMatch(matchId)
        .listen(
          (matchConfig) {
            state = AsyncValue.data(matchConfig);
          },
          onError: (e, st) {
            state = AsyncValue.error(e, st);
          },
        );
  }

  Future<void> passPotato(String nextUserId) async {
    final match = state.value;
    if (match == null) return;

    try {
      await _repository.passPotato(match.id, nextUserId);
    } catch (e, st) {
      // Error handling
      state = AsyncValue.error(e, st);
    }
  }

  @override
  void dispose() {
    _matchSubscription?.cancel();
    super.dispose();
  }
}
