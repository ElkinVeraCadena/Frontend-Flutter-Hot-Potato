import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final realtimeServiceProvider = Provider<RealtimeService>((ref) => RealtimeService());

class RealtimeService {
  final SupabaseClient _client = Supabase.instance.client;
  RealtimeChannel? _channel;
  
  final _presenceController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final _gameEventController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<List<Map<String, dynamic>>> get presenceStream => _presenceController.stream;
  Stream<Map<String, dynamic>> get gameEventStream => _gameEventController.stream;

  Future<void> joinRoom(String roomCode, String userId, String userName) async {
    leaveRoom(); // ensure previous is cleared
    
    // We use ack: true, self: true so we can hear our own events if needed
    _channel = _client.channel('room:$roomCode',
        opts: const RealtimeChannelConfig(ack: true, self: true));

    _channel!
      .onPresenceSync((_) {
        // Called whenever presence state changes (join/leave)
        final state = _channel!.presenceState();
        final List<Map<String, dynamic>> participants = [];
        
        for (final presenceState in state) {
          for (final presence in presenceState.presences) {
            participants.add(Map<String, dynamic>.from(presence.payload));
          }
        }
        _presenceController.add(participants);
      })
      .onBroadcast(
        event: 'game_event',
        callback: (payload) {
          _gameEventController.add(payload);
        },
      )
      .subscribe((status, [error]) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          // Tell others we are here
          await _channel?.track({
            'user_id': userId,
            'user_name': userName,
            'joined_at': DateTime.now().toIso8601String(),
          });
        }
      });
  }

  Future<void> broadcastGameEvent(Map<String, dynamic> payload) async {
    if (_channel != null) {
      await _channel!.sendBroadcastMessage(
        event: 'game_event',
        payload: payload,
      );
    }
  }

  void leaveRoom() {
    _channel?.unsubscribe();
    _channel = null;
  }
}
