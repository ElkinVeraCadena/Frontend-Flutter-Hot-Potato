class AppUser {
  final String id;
  final String name;
  final String username;
  final int totalXP;
  final int level;
  final Map<String, int> languageStats;

  AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.totalXP,
    required this.level,
    required this.languageStats,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      username: json['username'] as String,
      totalXP: json['total_xp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      languageStats: Map<String, int>.from(json['language_stats'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'total_xp': totalXP,
      'level': level,
      'language_stats': languageStats,
    };
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? username,
    int? totalXP,
    int? level,
    Map<String, int>? languageStats,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      totalXP: totalXP ?? this.totalXP,
      level: level ?? this.level,
      languageStats: languageStats ?? this.languageStats,
    );
  }
}
