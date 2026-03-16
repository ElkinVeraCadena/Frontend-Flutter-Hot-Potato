import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/game_room.dart';
import '../providers/auth_state.dart';
import 'realtime_service.dart';

// ---------------------------------------------------------------------------
// State class
// ---------------------------------------------------------------------------

class LobbyState {
  final GameRoom? room;
  final bool isLoading;
  final String? error;

  const LobbyState({this.room, this.isLoading = false, this.error});

  LobbyState copyWith({
    GameRoom? room,
    bool? isLoading,
    String? error,
    bool clearRoom = false,
    bool clearError = false,
  }) =>
      LobbyState(
        room: clearRoom ? null : (room ?? this.room),
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

// ---------------------------------------------------------------------------
// Provider — Riverpod v3 NotifierProvider
// ---------------------------------------------------------------------------

final lobbyStateProvider =
    NotifierProvider<LobbyNotifier, LobbyState>(LobbyNotifier.new);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class LobbyNotifier extends Notifier<LobbyState> {
  final _random = Random();
  StreamSubscription? _presenceSub;
  StreamSubscription? _eventSub;

  @override
  LobbyState build() {
    ref.onDispose(() {
      _presenceSub?.cancel();
      _eventSub?.cancel();
    });
    return const LobbyState();
  }

  String get _userId => ref.read(authStateProvider).value?.id ?? '';
  String get _userName => ref.read(authStateProvider).value?.name ?? 'Player';
  RealtimeService get _realtime => ref.read(realtimeServiceProvider);

  // ---- Create a new room (Host) ----
  Future<void> createRoom({int totalRounds = 5, int timePerTurn = 30}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    final code = _generateCode();
    final userId = _userId;
    
    final room = GameRoom(
      id: 'room_${DateTime.now().millisecondsSinceEpoch}',
      code: code,
      hostId: userId,
      participantIds: [userId],
      participantNames: {userId: _userName},
      status: RoomStatus.waiting,
      currentRound: 1,
      totalRounds: totalRounds,
      timePerTurn: timePerTurn,
      currentTurnIndex: 0,
      eliminatedIds: [],
    );
    
    state = state.copyWith(room: room, isLoading: false);
    
    _listenToRealtime(code, isHost: true);
    await _realtime.joinRoom(code, userId, _userName);
  }

  // ---- Join an existing room (Client) ----
  Future<void> joinRoom(String code) async {
    state = state.copyWith(isLoading: true, clearError: true);
    code = code.toUpperCase();
    
    _listenToRealtime(code, isHost: false);
    await _realtime.joinRoom(code, _userId, _userName);

    // Give it a few seconds to connect and receive a `room_sync` from the host
    Future.delayed(const Duration(seconds: 5), () {
      if (state.isLoading && state.room == null) {
         state = state.copyWith(
           isLoading: false, 
           error: 'Could not connect to room "$code" or no host found.',
         );
         _realtime.leaveRoom();
      }
    });
  }

  void _listenToRealtime(String code, {required bool isHost}) {
    _presenceSub?.cancel();
    _eventSub?.cancel();
    
    _presenceSub = _realtime.presenceStream.listen((participants) {
      final currentRoom = state.room;
      if (currentRoom != null && isHost) {
        // Host is in charge of updating participants from presence
        final List<String> pIds = [];
        final Map<String, String> pNames = {};
        
        // Add everyone from presence
        for (final p in participants) {
          final id = p['user_id'] as String;
          final name = p['user_name'] as String;
          pIds.add(id);
          pNames[id] = name;
        }
        
        // Ensure host is always first/present just in case presence is weird
        if (!pIds.contains(_userId)) {
          pIds.insert(0, _userId);
          pNames[_userId] = _userName;
        }

        final updated = currentRoom.copyWith(
          participantIds: pIds,
          participantNames: pNames,
        );
        state = state.copyWith(room: updated, isLoading: false);
        
        // Broadcast the official room state to clients
        _realtime.broadcastGameEvent({
          'type': 'room_sync',
          'room': updated.toJson(),
        });
      }
    });

    _eventSub = _realtime.gameEventStream.listen((payload) {
      final type = payload['type'];
      
      if (!isHost && type == 'room_sync') {
        final roomJson = payload['room'] as Map<String, dynamic>;
        state = state.copyWith(room: GameRoom.fromJson(roomJson), isLoading: false);
      }
      
      if (type == 'start_match') {
         if (state.room != null) {
           state = state.copyWith(room: state.room!.copyWith(status: RoomStatus.playing));
         }
      }
    });
  }

  // ---- Start the match (Host only) ----
  GameRoom? startMatch() {
    if (state.room == null) return null;
    if (state.room!.hostId != _userId) {
       state = state.copyWith(error: 'Only the host can start the match.');
       return null;
    }

    final updated = state.room!.copyWith(status: RoomStatus.playing);
    state = state.copyWith(room: updated);
    
    _realtime.broadcastGameEvent({
       'type': 'start_match',
       'room': updated.toJson(),
    });

    return updated;
  }

  void leaveRoom() {
    _realtime.leaveRoom();
    _presenceSub?.cancel();
    _eventSub?.cancel();
    state = const LobbyState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
        6, (_) => chars[_random.nextInt(chars.length)]).join();
  }
}
