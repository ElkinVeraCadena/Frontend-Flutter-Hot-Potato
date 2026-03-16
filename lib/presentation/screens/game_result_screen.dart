import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hot_potato/domain/models/game_room.dart';
import 'package:hot_potato/presentation/screens/match_screen.dart';
import '../providers/game_state.dart';
import '../providers/auth_state.dart';
import '../providers/lobby_state.dart';
import '../theme/app_theme.dart';

class GameResultScreen extends ConsumerWidget {
  const GameResultScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.read(gameStateProvider);
    final currentUserId = ref.read(authStateProvider).value?.id ?? '';

    final room = game.room;
    if (room == null) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => _goHome(context, ref),
            child: const Text('Back to Lobby'),
          ),
        ),
      );
    }

    // Sort active players by score descending
    final allPlayers = room.participantIds;
    final sorted = [...allPlayers]
      ..sort((a, b) => (game.scores[b] ?? 0).compareTo(game.scores[a] ?? 0));

    // Winner is the last non-eliminated player
    final survivors = allPlayers.where((id) => !room.isEliminated(id)).toList();
    final winner = survivors.isNotEmpty ? survivors.first : null;
    final isWinner = winner == currentUserId;

    // Award XP based on score
    final myScore = game.scores[currentUserId] ?? 0;
    final xpGained = myScore * 10 + (isWinner ? 50 : 0);

    // Update XP in Supabase
    if (xpGained > 0) {
      ref.read(authStateProvider.notifier).updateXP(xpGained);
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF8C69), Color(0xFFFFB28B), Color(0xFFFFFDF7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),

              // ---- Trophy / result header ----
              Text(
                isWinner ? '🏆 YOU WIN!' : '🎮 Game Over!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isWinner
                    ? 'Amazing! You survived all rounds!'
                    : 'Better luck next time!',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),

              const SizedBox(height: 24),

              // ---- Winner avatar ----
              if (winner != null)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      winner == currentUserId
                          ? '🥔🏆'
                          : (room.participantNames[winner] ?? '?')
                                .substring(0, 1)
                                .toUpperCase(),
                      style: winner == currentUserId
                          ? const TextStyle(fontSize: 50)
                          : const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                    ),
                  ),
                ),
              if (winner != null) ...[
                const SizedBox(height: 8),
                Text(
                  winner == currentUserId
                      ? 'You are the champion!'
                      : '${game.nameOf(winner)} wins!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // XP badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFAED581).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+$xpGained XP earned!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ---- Scoreboard ----
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Scoreboard',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: sorted.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final pid = sorted[i];
                            final name = game.nameOf(pid);
                            final score = game.scores[pid] ?? 0;
                            final eliminated = room.isEliminated(pid);
                            final isMe = pid == currentUserId;
                            final isWin = winner == pid;

                            return ListTile(
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: isWin
                                    ? const Color(0xFFFFCA28).withOpacity(0.2)
                                    : AppTheme.primaryColor.withOpacity(0.1),
                                child: Text(
                                  i == 0
                                      ? '🥇'
                                      : i == 1
                                      ? '🥈'
                                      : '${i + 1}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: isMe
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isMe
                                          ? AppTheme.primaryColor
                                          : AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                  if (isMe)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 6),
                                      child: Text(
                                        '(You)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondaryColor,
                                        ),
                                      ),
                                    ),
                                  if (eliminated)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 6),
                                      child: Text(
                                        '💀',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$score words',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  Text(
                                    '${score * 10} XP',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ---- Action buttons ----
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _goHome(context, ref),
                        icon: const Icon(Icons.home_rounded),
                        label: const Text('Lobby'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _playAgain(context, ref),
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text('Play Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _goHome(BuildContext context, WidgetRef ref) {
    ref.read(gameStateProvider.notifier).reset();
    ref.read(lobbyStateProvider.notifier).leaveRoom();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _playAgain(BuildContext context, WidgetRef ref) {
    final room = ref.read(gameStateProvider).room;
    if (room == null) {
      _goHome(context, ref);
      return;
    }
    // Restart with same room config
    final freshRoom = room.copyWith(
      status: RoomStatus.playing,
      currentRound: 1,
      currentTurnIndex: 0,
      eliminatedIds: [],
    );
    ref.read(gameStateProvider.notifier).startMatch(freshRoom);
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MatchScreen()));
  }
}
