class GameMatch {
  final String id;
  final String targetWord;
  final String currentTurnUserId;
  final List<String> participants;
  final bool isActive;
  final DateTime startedAt;

  GameMatch({
    required this.id,
    required this.targetWord,
    required this.currentTurnUserId,
    required this.participants,
    required this.isActive,
    required this.startedAt,
  });

  factory GameMatch.fromJson(Map<String, dynamic> json) {
    return GameMatch(
      id: json['id'] as String,
      targetWord: json['target_word'] as String,
      currentTurnUserId: json['current_turn_user_id'] as String,
      participants: List<String>.from(json['participants'] as List? ?? []),
      isActive: json['is_active'] as bool? ?? false,
      startedAt: DateTime.parse(json['started_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'target_word': targetWord,
      'current_turn_user_id': currentTurnUserId,
      'participants': participants,
      'is_active': isActive,
      'started_at': startedAt.toIso8601String(),
    };
  }

  GameMatch copyWith({
    String? id,
    String? targetWord,
    String? currentTurnUserId,
    List<String>? participants,
    bool? isActive,
    DateTime? startedAt,
  }) {
    return GameMatch(
      id: id ?? this.id,
      targetWord: targetWord ?? this.targetWord,
      currentTurnUserId: currentTurnUserId ?? this.currentTurnUserId,
      participants: participants ?? this.participants,
      isActive: isActive ?? this.isActive,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}
