import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/game_room.dart';
import '../../domain/models/word_challenge.dart';
import '../providers/auth_state.dart';
import 'realtime_service.dart';

// ---------------------------------------------------------------------------
// Game Phase & State
// ---------------------------------------------------------------------------

enum GamePhase { idle, playing, roundEnd, gameOver }

class GameState {
  final GameRoom? room;
  final List<WordChallenge> challenges;
  final int challengeIndex;
  final int timeLeft;
  final GamePhase phase;
  final String? eliminatedThisRound;
  final Map<String, int> scores;

  const GameState({
    this.room,
    this.challenges = const [],
    this.challengeIndex = 0,
    this.timeLeft = 30,
    this.phase = GamePhase.idle,
    this.eliminatedThisRound,
    this.scores = const {},
  });

  WordChallenge? get currentChallenge =>
      challenges.isNotEmpty && challengeIndex < challenges.length
          ? challenges[challengeIndex]
          : null;

  bool isMyTurn(String userId) => room?.currentTurnUserId == userId;

  String nameOf(String userId) =>
      room?.participantNames[userId] ?? 'Player';

  GameState copyWith({
    GameRoom? room,
    List<WordChallenge>? challenges,
    int? challengeIndex,
    int? timeLeft,
    GamePhase? phase,
    String? eliminatedThisRound,
    Map<String, int>? scores,
    bool clearEliminated = false,
  }) =>
      GameState(
        room: room ?? this.room,
        challenges: challenges ?? this.challenges,
        challengeIndex: challengeIndex ?? this.challengeIndex,
        timeLeft: timeLeft ?? this.timeLeft,
        phase: phase ?? this.phase,
        eliminatedThisRound: clearEliminated
            ? null
            : (eliminatedThisRound ?? this.eliminatedThisRound),
        scores: scores ?? this.scores,
      );
}

// ---------------------------------------------------------------------------
// Provider — uses Riverpod v3 Notifier API
// ---------------------------------------------------------------------------

final gameStateProvider =
    NotifierProvider<GameNotifier, GameState>(GameNotifier.new);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class GameNotifier extends Notifier<GameState> {
  Timer? _timer;
  StreamSubscription? _eventSub;

  @override
  GameState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _eventSub?.cancel();
    });
    return const GameState();
  }

  String get _userId => ref.read(authStateProvider).value?.id ?? '';
  RealtimeService get _realtime => ref.read(realtimeServiceProvider);
  bool get _isHost => state.room?.hostId == _userId;

  // ---- Initialize the match locally ----
  void startMatch(GameRoom room) {
    _timer?.cancel();
    final challenges = WordChallenge.getShuffled(
        count: room.totalRounds * room.participantIds.length + 5);
    final scores = {for (final id in room.participantIds) id: 0};

    state = state.copyWith(
      room: room.copyWith(
          status: RoomStatus.playing, currentTurnIndex: 0, eliminatedIds: []),
      challenges: challenges,
      challengeIndex: 0,
      timeLeft: room.timePerTurn,
      phase: GamePhase.playing,
      scores: scores,
      clearEliminated: true,
    );
    
    _listenToRealtime();
    
    if (room.hostId == _userId) {
      // Host broadcasts the initial full state
      _broadcastGameState();
      _startHostTimer();
    }
  }
  
  void _listenToRealtime() {
    _eventSub?.cancel();
    _eventSub = _realtime.gameEventStream.listen((payload) {
      final type = payload['type'];
      
      // Host handles incoming actions from clients
      if (_isHost) {
        if (type == 'client_passed_potato') {
          _handlePassPotatoHost(payload['user_id'] as String);
        }
        return; 
      }
      
      // Client handles incoming syncs from host
      if (type == 'game_sync') {
        final roomJson = payload['room'] as Map<String, dynamic>;
        final challengesJson = payload['challenges'] as List<dynamic>;
        final scoresJson = payload['scores'] as Map<String, dynamic>;
        
        state = state.copyWith(
          room: GameRoom.fromJson(roomJson),
          challenges: challengesJson
              .map((j) => WordChallenge.fromJson(j as Map<String, dynamic>))
              .toList(),
          challengeIndex: payload['challenge_index'] as int,
          timeLeft: payload['time_left'] as int,
          phase: GamePhase.values.byName(payload['phase'] as String),
          eliminatedThisRound: payload['eliminated_this_round'] as String?,
          scores: scoresJson.map((k, v) => MapEntry(k, v as int)),
        );
      }
    });
  }

  void _broadcastGameState() {
    if (!_isHost) return;
    _realtime.broadcastGameEvent({
      'type': 'game_sync',
      'room': state.room!.toJson(),
      'challenges': state.challenges.map((c) => c.toJson()).toList(),
      'challenge_index': state.challengeIndex,
      'time_left': state.timeLeft,
      'phase': state.phase.name,
      'eliminated_this_round': state.eliminatedThisRound,
      'scores': state.scores,
    });
  }

  // ---- Player typed the correct word — pass the potato ----
  void passPotato(String currentUserId) {
    if (state.phase != GamePhase.playing) return;
    if (!state.isMyTurn(currentUserId)) return;

    if (_isHost) {
       _handlePassPotatoHost(currentUserId);
    } else {
       // Client tells host they passed
       _realtime.broadcastGameEvent({
         'type': 'client_passed_potato',
         'user_id': currentUserId,
       });
       // To decouple input latency, we could eagerly update local state here if we wanted
    }
  }
  
  void _handlePassPotatoHost(String currentUserId) {
    if (!_isHost) return;
    
    final room = state.room!;
    final active = room.activePlayers;
    final currentIdx = active.indexOf(currentUserId);
    if (currentIdx == -1) return; // Safety
    
    final nextIdx = (currentIdx + 1) % active.length;

    final newScores = Map<String, int>.from(state.scores);
    newScores[currentUserId] = (newScores[currentUserId] ?? 0) + 1;

    final nextTurnIndex = room.participantIds.indexOf(active[nextIdx]);
    final updatedRoom = room.copyWith(currentTurnIndex: nextTurnIndex);

    state = state.copyWith(
      room: updatedRoom,
      challengeIndex: state.challengeIndex + 1,
      timeLeft: room.timePerTurn,
      scores: newScores,
      clearEliminated: true,
    );
    
    _broadcastGameState();
    _startHostTimer(); // Reset timer
  }

  // ---- Timer tick ----
  void _startHostTimer() {
    if (!_isHost) return;
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.timeLeft <= 1) {
        _onTimerExpiredAsHost();
      } else {
        state = state.copyWith(timeLeft: state.timeLeft - 1);
        _broadcastGameState();
      }
    });
  }

  // ---- Timer reached 0: eliminate current holder ----
  void _onTimerExpiredAsHost() {
    _timer?.cancel();
    final room = state.room;
    if (room == null || state.phase != GamePhase.playing) return;

    final eliminated = room.currentTurnUserId;
    final newEliminated = [...room.eliminatedIds, eliminated];
    final remaining = room.participantIds
        .where((id) => !newEliminated.contains(id))
        .toList();

    final newRound = room.currentRound + 1;
    final isGameOver = remaining.length <= 1 || newRound > room.totalRounds;

    if (isGameOver) {
      state = state.copyWith(
        room: room.copyWith(
            eliminatedIds: newEliminated, status: RoomStatus.finished),
        phase: GamePhase.gameOver,
        eliminatedThisRound: eliminated,
      );
      _broadcastGameState();
      return;
    }

    final nextTurnIndex = room.participantIds.indexOf(remaining[0]);
    final updatedRoom = room.copyWith(
      eliminatedIds: newEliminated,
      currentRound: newRound,
      currentTurnIndex: nextTurnIndex,
    );

    state = state.copyWith(
      room: updatedRoom,
      challengeIndex: state.challengeIndex + 1,
      timeLeft: room.timePerTurn,
      phase: GamePhase.roundEnd,
      eliminatedThisRound: eliminated,
    );
    
    _broadcastGameState();
  }

  // ---- After round-end dialog, resume ----
  void continueAfterRound() {
    if (state.phase != GamePhase.roundEnd) return;
    
    if (_isHost) {
      state = state.copyWith(phase: GamePhase.playing, clearEliminated: true);
      _broadcastGameState();
      _startHostTimer();
    } else {
      // Just visually clear local dialogs while waiting for host
      state = state.copyWith(phase: GamePhase.playing, clearEliminated: true);
    }
  }

  // ---- Reset ----
  void reset() {
    _timer?.cancel();
    _eventSub?.cancel();
    state = const GameState();
  }
}
