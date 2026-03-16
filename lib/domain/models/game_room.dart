enum RoomStatus { waiting, playing, finished }

class GameRoom {
  final String id;
  final String code; // Short human-readable code to share (e.g. "ABC123")
  final String hostId;
  final List<String> participantIds;
  final Map<String, String> participantNames; // userId -> displayName
  final RoomStatus status;
  final int currentRound;
  final int totalRounds;
  final int timePerTurn; // seconds
  final int currentTurnIndex; // index into participantIds
  final List<String> eliminatedIds;

  const GameRoom({
    required this.id,
    required this.code,
    required this.hostId,
    required this.participantIds,
    required this.participantNames,
    required this.status,
    required this.currentRound,
    required this.totalRounds,
    required this.timePerTurn,
    required this.currentTurnIndex,
    required this.eliminatedIds,
  });

  String get currentTurnUserId {
    final active = activePlayers;
    if (active.isEmpty) return '';
    return active[currentTurnIndex % active.length];
  }

  List<String> get activePlayers =>
      participantIds.where((id) => !eliminatedIds.contains(id)).toList();

  bool isEliminated(String userId) => eliminatedIds.contains(userId);

  factory GameRoom.fromJson(Map<String, dynamic> json) {
    final namesRaw = json['participant_names'] as Map<String, dynamic>? ?? {};
    return GameRoom(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      hostId: json['host_id'] as String,
      participantIds:
          List<String>.from(json['participant_ids'] as List? ?? []),
      participantNames: namesRaw.map((k, v) => MapEntry(k, v.toString())),
      status: _statusFromString(json['status'] as String? ?? 'waiting'),
      currentRound: json['current_round'] as int? ?? 1,
      totalRounds: json['total_rounds'] as int? ?? 5,
      timePerTurn: json['time_per_turn'] as int? ?? 30,
      currentTurnIndex: json['current_turn_index'] as int? ?? 0,
      eliminatedIds:
          List<String>.from(json['eliminated_ids'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'host_id': hostId,
        'participant_ids': participantIds,
        'participant_names': participantNames,
        'status': status.name,
        'current_round': currentRound,
        'total_rounds': totalRounds,
        'time_per_turn': timePerTurn,
        'current_turn_index': currentTurnIndex,
        'eliminated_ids': eliminatedIds,
      };

  GameRoom copyWith({
    String? id,
    String? code,
    String? hostId,
    List<String>? participantIds,
    Map<String, String>? participantNames,
    RoomStatus? status,
    int? currentRound,
    int? totalRounds,
    int? timePerTurn,
    int? currentTurnIndex,
    List<String>? eliminatedIds,
  }) =>
      GameRoom(
        id: id ?? this.id,
        code: code ?? this.code,
        hostId: hostId ?? this.hostId,
        participantIds: participantIds ?? this.participantIds,
        participantNames: participantNames ?? this.participantNames,
        status: status ?? this.status,
        currentRound: currentRound ?? this.currentRound,
        totalRounds: totalRounds ?? this.totalRounds,
        timePerTurn: timePerTurn ?? this.timePerTurn,
        currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
        eliminatedIds: eliminatedIds ?? this.eliminatedIds,
      );

  static RoomStatus _statusFromString(String s) {
    switch (s) {
      case 'playing':
        return RoomStatus.playing;
      case 'finished':
        return RoomStatus.finished;
      default:
        return RoomStatus.waiting;
    }
  }
}
